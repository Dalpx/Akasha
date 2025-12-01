import 'package:flutter/material.dart';
import '../../models/proveedor.dart';
import '../../models/producto.dart';
import '../../models/compra.dart';
import '../../models/detalle_compra.dart';
import '../../models/ubicacion.dart';
import '../../services/proveedor_service.dart';
import '../../services/inventario_service.dart';
import '../../services/compra_service.dart';
import '../../services/ubicacion_service.dart';

/// Pantalla principal de compras.
/// Aquí se selecciona un proveedor, se arman órdenes de compra
/// y se registran las compras, actualizando el stock por producto
/// y opcionalmente por ubicación.
class ComprasPage extends StatefulWidget {
  const ComprasPage({Key? key}) : super(key: key);

  @override
  State<ComprasPage> createState() {
    return _ComprasPageState();
  }
}

class _ComprasPageState extends State<ComprasPage> {
  // Servicios que usará la pantalla.
  final ProveedorService _proveedorService = ProveedorService();
  final InventarioService _inventarioService = InventarioService();
  final UbicacionService _ubicacionService = UbicacionService();
  late final CompraService _compraService;

  // Listas de datos cargados.
  List<Proveedor> _proveedores = <Proveedor>[];
  List<Producto> _productos = <Producto>[];
  List<Compra> _compras = <Compra>[]; // Historial de compras.
  List<Ubicacion> _ubicaciones = <Ubicacion>[];

  // Proveedor, producto y ubicación seleccionados.
  Proveedor? _proveedorSeleccionado;
  Producto? _productoSeleccionado;
  Ubicacion? _ubicacionSeleccionada;

  // Controladores para cantidad y precio unitario de la compra.
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _precioUnitarioController =
      TextEditingController();
  // final TextEditingController _cedulaController = TextEditingController();

  // Lista de líneas de la orden de compra en construcción.
  final List<DetalleCompra> _lineasOrden = <DetalleCompra>[];

  // Indica si se están cargando los datos iniciales.
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();

    // Inicializamos el servicio de compras con el inventario compartido.
    _compraService = CompraService(inventarioService: _inventarioService);

    _cargarDatosIniciales();
  }

  /// Carga proveedores, productos, ubicaciones e historial de compras.
  Future<void> _cargarDatosIniciales() async {
    List<Proveedor> proveedores = await _proveedorService
        .obtenerProveedoresActivos();
    List<Producto> productos = await _inventarioService.obtenerProductos();
    List<Compra> compras = await _compraService.obtenerCompras();
    List<Ubicacion> ubicaciones = await _ubicacionService
        .obtenerUbicacionesActivas();

    setState(() {
      _proveedores = proveedores;
      _productos = productos;
      _compras = compras;
      _ubicaciones = ubicaciones;

      if (_proveedores.isNotEmpty) {
        _proveedorSeleccionado = _proveedores[0];
      }

      if (_productos.isNotEmpty) {
        _productoSeleccionado = _productos[0];
      }

      if (_ubicaciones.isNotEmpty) {
        _ubicacionSeleccionada = _ubicaciones[0];
      }

      _cargandoInicial = false;
    });
  }

  /// Calcula el total actual de la orden de compra.
  double _calcularTotalOrden() {
    double total = 0.0;

    for (int i = 0; i < _lineasOrden.length; i++) {
      total = total + _lineasOrden[i].subtotal;
    }

    return total;
  }

  /// Muestra un mensaje en un SnackBar.
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Agrega un producto a la orden con la cantidad, precio y ubicación indicados.
  void _agregarProductoALaOrden() {
    if (_productoSeleccionado == null) {
      _mostrarMensaje('Debe seleccionar un producto.');
      return;
    }

    int cantidad = int.tryParse(_cantidadController.text) ?? 1;

    if (cantidad <= 0) {
      _mostrarMensaje('La cantidad debe ser mayor que cero.');
      return;
    }

    if (_productoSeleccionado!.idProducto == null) {
      _mostrarMensaje('El producto no tiene id asignado.');
      return;
    }

    double precioUnitario;

    if (_precioUnitarioController.text.trim().isEmpty) {
      // Si no se especifica precio, usamos el precio de costo del producto.
      precioUnitario = _productoSeleccionado!.precioCosto;
    } else {
      precioUnitario =
          double.tryParse(_precioUnitarioController.text) ??
          _productoSeleccionado!.precioCosto;
    }

    double subtotal = precioUnitario * cantidad;

    int? idUbicacion;
    if (_ubicacionSeleccionada != null &&
        _ubicacionSeleccionada!.idUbicacion != null) {
      idUbicacion = _ubicacionSeleccionada!.idUbicacion;
    }

    DetalleCompra detalle = DetalleCompra(
      idProducto: _productoSeleccionado!.idProducto!,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      subtotal: subtotal,
      idUbicacion: idUbicacion,
    );

    setState(() {
      _lineasOrden.add(detalle);
      _cantidadController.text = '';
      _precioUnitarioController.text = '';
    });
  }

  /// Elimina una línea de la orden según su índice.
  void _removerLineaOrden(int index) {
    setState(() {
      _lineasOrden.removeAt(index);
    });
  }

  /// Genera un número de documento simple para la compra.
  String _generarNumeroDocumentoCompra() {
    DateTime ahora = DateTime.now();

    String dosDigitos(int n) {
      if (n >= 10) {
        return n.toString();
      }
      return '0${n.toString()}';
    }

    String y = ahora.year.toString();
    String m = dosDigitos(ahora.month);
    String d = dosDigitos(ahora.day);
    String hh = dosDigitos(ahora.hour);
    String mm = dosDigitos(ahora.minute);
    String ss = dosDigitos(ahora.second);

    return 'C-$y$m$d-$hh$mm$ss';
  }

  /// Registra la compra:
  /// - Valida proveedor y líneas.
  /// - Construye la compra.
  /// - Llama al servicio para registrar (actualiza stock por producto/ubicación).
  /// - Actualiza el historial y limpia la orden en curso.
  /// - Muestra un resumen.
  Future<void> _registrarCompra() async {
    if (_proveedorSeleccionado == null) {
      _mostrarMensaje('Debe seleccionar un proveedor.');
      return;
    }

    if (_lineasOrden.isEmpty) {
      _mostrarMensaje('Debe agregar al menos un producto a la orden.');
      return;
    }

    if (_proveedorSeleccionado!.idProveedor == null) {
      _mostrarMensaje('El proveedor no tiene id asignado.');
      return;
    }

    double total = _calcularTotalOrden();
    String numeroDocumento = _generarNumeroDocumentoCompra();

    Compra compra = Compra(
      idProveedor: _proveedorSeleccionado!.idProveedor!,
      fecha: DateTime.now(),
      total: total,
      numeroDocumento: numeroDocumento,
    );

    Compra compraRegistrada = await _compraService.registrarCompra(
      compra,
      _lineasOrden,
    );

    List<DetalleCompra> lineas = List<DetalleCompra>.from(_lineasOrden);

    setState(() {
      _lineasOrden.clear();
      _compras.add(compraRegistrada);
    });

    _mostrarDialogoCompraRegistrada(compraRegistrada, lineas);
  }

  /// Muestra un diálogo con el resumen de una compra registrada.
  void _mostrarDialogoCompraRegistrada(
    Compra compra,
    List<DetalleCompra> detalles,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Compra registrada: ${compra.numeroDocumento}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('ID Compra: ${compra.idCompra ?? '-'}'),
                Text('Proveedor ID: ${compra.idProveedor}'),
                Text('Fecha: ${_formatearFecha(compra.fecha)}'),
                const SizedBox(height: 8.0),
                const Text(
                  'Detalle:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Column(
                  children: detalles.map((DetalleCompra d) {
                    Producto? producto = _buscarProductoPorId(d.idProducto);
                    String nombreProducto = producto != null
                        ? producto.nombre
                        : 'Producto ${d.idProducto}';

                    String textoUbicacion = '';
                    if (d.idUbicacion != null) {
                      Ubicacion? ubicacion = _buscarUbicacionPorId(
                        d.idUbicacion!,
                      );
                      String nombreUbicacion = ubicacion != null
                          ? ubicacion.nombre
                          : 'Ubicación ${d.idUbicacion}';
                      textoUbicacion = '\nUbicación: $nombreUbicacion';
                    }

                    return ListTile(
                      dense: true,
                      title: Text(nombreProducto),
                      subtitle: Text(
                        'Cantidad: ${d.cantidad} x ${d.precioUnitario} = ${d.subtotal}$textoUbicacion',
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Total: ${compra.total}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  /// Permite ver el detalle de una compra seleccionada desde el historial.
  Future<void> _verDetalleCompraDesdeHistorial(Compra compra) async {
    if (compra.idCompra == null) {
      _mostrarMensaje('La compra no tiene id asignado.');
      return;
    }

    List<DetalleCompra> detalles = await _compraService
        .obtenerDetallesPorCompra(compra.idCompra!);

    _mostrarDialogoCompraRegistrada(compra, detalles);
  }

  /// Formatea una fecha simple: yyyy-MM-dd HH:mm
  String _formatearFecha(DateTime fecha) {
    String dosDigitos(int n) {
      if (n >= 10) {
        return n.toString();
      }
      return '0${n.toString()}';
    }

    String y = fecha.year.toString();
    String m = dosDigitos(fecha.month);
    String d = dosDigitos(fecha.day);
    String hh = dosDigitos(fecha.hour);
    String mm = dosDigitos(fecha.minute);

    return '$y-$m-$d $hh:$mm';
  }

  /// Busca un producto por id dentro de la lista de productos cargados.
  Producto? _buscarProductoPorId(int idProducto) {
    for (int i = 0; i < _productos.length; i++) {
      if (_productos[i].idProducto == idProducto) {
        return _productos[i];
      }
    }
    return null;
  }

  /// Busca una ubicación por id dentro de la lista cargada.
  Ubicacion? _buscarUbicacionPorId(int idUbicacion) {
    for (int i = 0; i < _ubicaciones.length; i++) {
      if (_ubicaciones[i].idUbicacion == idUbicacion) {
        return _ubicaciones[i];
      }
    }
    return null;
  }

  /// Diálogo para crear un nuevo proveedor rápido desde la pantalla de compras.
  Future<void> _abrirDialogoNuevoProveedor() async {
    TextEditingController nombreController = TextEditingController();
    TextEditingController telefonoController = TextEditingController();
    TextEditingController correoController = TextEditingController();
    TextEditingController direccionController = TextEditingController();

    Proveedor? proveedorCreado;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nuevo proveedor'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                TextField(
                  controller: correoController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                TextField(
                  controller: direccionController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.trim().isEmpty) {
                  _mostrarMensaje('El nombre del proveedor es obligatorio.');
                  return;
                }

                Proveedor nuevo = Proveedor(
                  nombre: nombreController.text.trim(),
                  telefono: telefonoController.text.trim(),
                  correo: correoController.text.trim().isEmpty
                      ? null
                      : correoController.text.trim(),
                  direccion: direccionController.text.trim().isEmpty
                      ? null
                      : direccionController.text.trim(),
                  activo: true,
                );

                // proveedorCreado =
                await _proveedorService.crearProveedor(nuevo);

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (proveedorCreado != null) {
      setState(() {
        _proveedores.add(proveedorCreado!);
        _proveedorSeleccionado = proveedorCreado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoInicial) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Módulo de Compras',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16.0),

            // Sección de proveedor
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Proveedor',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<Proveedor>(
                            value: _proveedorSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar proveedor',
                            ),
                            items: _proveedores.map((Proveedor proveedor) {
                              return DropdownMenuItem<Proveedor>(
                                value: proveedor,
                                child: Text(proveedor.nombre),
                              );
                            }).toList(),
                            onChanged: (Proveedor? nuevo) {
                              setState(() {
                                _proveedorSeleccionado = nuevo;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            _abrirDialogoNuevoProveedor();
                          },
                          child: const Text('Nuevo proveedor'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Sección para agregar productos a la orden de compra
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Agregar producto a la orden',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<Producto>(
                            value: _productoSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Producto',
                            ),
                            items: _productos.map((Producto producto) {
                              return DropdownMenuItem<Producto>(
                                value: producto,
                                child: Text(producto.nombre),
                              );
                            }).toList(),
                            onChanged: (Producto? nuevo) {
                              setState(() {
                                _productoSeleccionado = nuevo;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<Ubicacion>(
                            value: _ubicacionSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Ubicación (opcional)',
                            ),
                            items: _ubicaciones.map((Ubicacion u) {
                              return DropdownMenuItem<Ubicacion>(
                                value: u,
                                child: Text(u.nombre),
                              );
                            }).toList(),
                            onChanged: (Ubicacion? nueva) {
                              setState(() {
                                _ubicacionSeleccionada = nueva;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _cantidadController,
                            decoration: const InputDecoration(
                              labelText: 'Cant.',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _precioUnitarioController,
                            decoration: const InputDecoration(
                              labelText: 'Precio unitario (opcional)',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            _agregarProductoALaOrden();
                          },
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Detalle de la orden de compra
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Detalle de la orden',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: _lineasOrden.isEmpty
                            ? const Center(
                                child: Text('No hay productos en la orden.'),
                              )
                            : ListView.builder(
                                itemCount: _lineasOrden.length,
                                itemBuilder: (BuildContext context, int index) {
                                  DetalleCompra detalle = _lineasOrden[index];
                                  Producto? producto = _buscarProductoPorId(
                                    detalle.idProducto,
                                  );
                                  String nombreProducto = producto != null
                                      ? producto.nombre
                                      : 'Producto ${detalle.idProducto}';

                                  String textoUbicacion = '';
                                  if (detalle.idUbicacion != null) {
                                    Ubicacion? ubicacion =
                                        _buscarUbicacionPorId(
                                          detalle.idUbicacion!,
                                        );
                                    String nombreUbicacion = ubicacion != null
                                        ? ubicacion.nombre
                                        : 'Ubicación ${detalle.idUbicacion}';
                                    textoUbicacion =
                                        '\nUbicación: $nombreUbicacion';
                                  }

                                  return ListTile(
                                    title: Text(nombreProducto),
                                    subtitle: Text(
                                      'Cantidad: ${detalle.cantidad} x ${detalle.precioUnitario} = ${detalle.subtotal}$textoUbicacion',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        _removerLineaOrden(index);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: ${_calcularTotalOrden()}',
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8.0),

            // Historial de compras
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Historial de compras',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: _compras.isEmpty
                            ? const Center(
                                child: Text(
                                  'Todavía no se han registrado compras.',
                                ),
                              )
                            : ListView.builder(
                                itemCount: _compras.length,
                                itemBuilder: (BuildContext context, int index) {
                                  Compra compra = _compras[index];

                                  return ListTile(
                                    title: Text(compra.numeroDocumento),
                                    subtitle: Text(
                                      'Fecha: ${_formatearFecha(compra.fecha)}\nTotal: ${compra.total}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.visibility),
                                      tooltip: 'Ver detalle',
                                      onPressed: () {
                                        _verDetalleCompraDesdeHistorial(compra);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8.0),

            // Botón para registrar compra
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _registrarCompra();
                },
                child: const Text('Registrar compra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
