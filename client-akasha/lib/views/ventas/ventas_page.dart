import 'package:flutter/material.dart';
import '../../models/cliente.dart';
import '../../models/producto.dart';
import '../../models/detalle_venta.dart';
import '../../models/venta.dart';
import '../../models/ubicacion.dart';
import '../../services/cliente_service.dart';
import '../../services/inventario_service.dart';
import '../../services/venta_service.dart';
import '../../services/ubicacion_service.dart';

/// Pantalla principal de ventas.
/// Aquí se registran clientes, se arman pedidos y se emiten facturas.
/// Además, se muestra un historial de facturas emitidas.
class VentasPage extends StatefulWidget {
  const VentasPage({Key? key}) : super(key: key);

  @override
  State<VentasPage> createState() {
    return _VentasPageState();
  }
}

class _VentasPageState extends State<VentasPage> {
  // Servicios de negocio que usará la pantalla.
  final ClienteService _clienteService = ClienteService();
  final InventarioService _inventarioService = InventarioService();
  final UbicacionService _ubicacionService = UbicacionService();
  late final VentaService _ventaService;

  // Listas de datos cargados.
  List<Cliente> _clientes = <Cliente>[];
  List<Producto> _productos = <Producto>[];
  List<Venta> _ventas = <Venta>[];
  List<Ubicacion> _ubicaciones = <Ubicacion>[];

  // Cliente, producto y ubicación seleccionados.
  Cliente? _clienteSeleccionado;
  Producto? _productoSeleccionado;
  Ubicacion? _ubicacionSeleccionada;

  // Controlador para la cantidad del producto a agregar.
  final TextEditingController _cantidadController = TextEditingController();

  // Lista de líneas del pedido (detalles de la venta en construcción).
  final List<DetalleVenta> _lineasPedido = <DetalleVenta>[];

  // Indica si se están cargando los datos iniciales.
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();

    _ventaService = VentaService();

    _cargarDatosIniciales();
  }

  /// Carga clientes, productos, ubicaciones y ventas desde los servicios.
  Future<void> _cargarDatosIniciales() async {
    List<Cliente> clientes = await _clienteService.obtenerClientesActivos();
    List<Producto> productos = await _inventarioService.obtenerProductos();
    List<Venta> ventas = await _ventaService.obtenerVentas();
    List<Ubicacion> ubicaciones = await _ubicacionService
        .obtenerUbicacionesActivas();

    setState(() {
      _clientes = clientes;
      _productos = productos;
      _ventas = ventas;
      _ubicaciones = ubicaciones;

      if (_clientes.isNotEmpty) {
        _clienteSeleccionado = _clientes[0];
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

  /// Calcula el total actual del pedido sumando los subtotales de las líneas.
  double _calcularTotalPedido() {
    double total = 0.0;

    for (int i = 0; i < _lineasPedido.length; i++) {
      total = total + double.parse(_lineasPedido[i].subtotal) ;
    }

    return total;
  }

  /// Muestra un mensaje simple en la parte inferior de la pantalla.
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Agrega un producto al pedido con la cantidad indicada y la ubicación seleccionada.
  void _agregarProductoAlPedido() {
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

    double precioUnitario = _productoSeleccionado!.precioVenta;
    double subtotal = precioUnitario * cantidad;

    int? idUbicacion;
    if (_ubicacionSeleccionada != null &&
        _ubicacionSeleccionada!.idUbicacion != null) {
      idUbicacion = _ubicacionSeleccionada!.idUbicacion;
    }

    DetalleVenta detalle = DetalleVenta(
      idProducto: _productoSeleccionado!.idProducto!,

      cantidad: cantidad,
      precioUnitario: precioUnitario.toString(),
      subtotal: subtotal.toString(),
      idDetalleVenta: null,
      nombreProducto: 'a',
      // idUbicacion: idUbicacion.toString(),
    );

    setState(() {
      _lineasPedido.add(detalle);
      _cantidadController.text = '';
    });
  }

  /// Elimina una línea del pedido según su índice en la lista.
  void _removerLineaPedido(int index) {
    setState(() {
      _lineasPedido.removeAt(index);
    });
  }

  /// Genera un número de factura simple basado en la fecha y hora actual.
  String _generarNumeroFactura() {
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

    return 'F-$y$m$d-$hh$mm$ss';
  }

  /// Emite la factura.
  Future<void> _emitirFactura() async {
    if (_clienteSeleccionado == null) {
      _mostrarMensaje('Debe seleccionar un cliente.');
      return;
    }

    if (_lineasPedido.isEmpty) {
      _mostrarMensaje('Debe agregar al menos un producto al pedido.');
      return;
    }

    if (_clienteSeleccionado!.idCliente == null) {
      _mostrarMensaje('El cliente no tiene id asignado.');
      return;
    }

    double total = _calcularTotalPedido();
    String numeroFactura = _generarNumeroFactura();

    for (int i = 0; i < _lineasPedido.length; i++) {
      total = total + double.parse(_lineasPedido[i].subtotal);
    }

    Venta venta = Venta(
      total: total,
      nroComprobante: numeroFactura,
      idTipoComprobante: '1',
      subtotal: total,
      impuesto: 21,
      idVenta: null,
      fecha: DateTime.now(),
      nombreCliente: 'hardcode',
      metodoPago: '1',
      registradoPor: 'pruebadeUsuario',
      email: 'usuarioharcodeado@gmail.com',
      nombreTipoUsuario: 'hardcoded',
    );

    Venta ventaRegistrada = await _ventaService.registrarVenta(
      venta,
      _lineasPedido
    );

    List<DetalleVenta> lineasFactura = List<DetalleVenta>.from(_lineasPedido);

    setState(() {
      _lineasPedido.clear();
    });

    _mostrarDialogoFacturaEmitida(ventaRegistrada, lineasFactura);
  }

  /// Muestra un diálogo con el resumen de la factura emitida.
  void _mostrarDialogoFacturaEmitida(Venta venta, List<DetalleVenta> detalles) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Factura emitida: ${venta.nroComprobante}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('ID Venta: ${venta.nroComprobante}'),
                Text('Cliente ID: ${venta.nombreCliente}'),
                const SizedBox(height: 8.0),
                const Text(
                  'Detalle:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Column(
                  children: detalles.map((DetalleVenta d) {
                    Producto? producto = _buscarProductoPorId(d.idProducto);
                    String nombreProducto = producto != null
                        ? producto.nombre
                        : 'Producto ${d.idProducto}';

                    String textoUbicacion = '';
                    // if (d.idUbicacion.isNotEmpty) {
                    //   Ubicacion? ubicacion = _buscarUbicacionPorId(
                    //     int.parse(d.idUbicacion),
                    //   );
                    //   String nombreUbicacion = ubicacion != null
                    //       ? ubicacion.nombreAlmacen
                    //       : 'Ubicación ${d.idUbicacion}';
                    //   textoUbicacion = '\nUbicación: $nombreUbicacion';
                    // }

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
                  'Total: ${venta.total}',
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

  /// Permite ver el detalle de una venta seleccionada desde el historial.
  Future<void> _verDetalleVentaDesdeHistorial(Venta venta) async {
    List<DetalleVenta> detalles = await _ventaService.obtenerDetallesPorVenta(
      venta.idVenta!,
    );

    _mostrarDialogoFacturaEmitida(venta, detalles);
  }

  /// Busca un producto por id.
  Producto? _buscarProductoPorId(int idProducto) {
    for (int i = 0; i < _productos.length; i++) {
      if (_productos[i].idProducto == idProducto) {
        return _productos[i];
      }
    }
    return null;
  }

  /// Busca una ubicación por id.
  Ubicacion? _buscarUbicacionPorId(int idUbicacion) {
    for (int i = 0; i < _ubicaciones.length; i++) {
      if (_ubicaciones[i].idUbicacion == idUbicacion) {
        return _ubicaciones[i];
      }
    }
    return null;
  }

  /// Diálogo para registrar un nuevo cliente (igual que antes).
  Future<void> _abrirDialogoNuevoCliente() async {
    TextEditingController nombreController = TextEditingController();
    TextEditingController apellidoController = TextEditingController();
    TextEditingController telefonoController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController direccionController = TextEditingController();
    TextEditingController? _cedulaController = TextEditingController();

    Cliente? clienteCreado;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nuevo cliente'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: apellidoController,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                TextField(
                  controller: _cedulaController,
                  decoration: const InputDecoration(labelText: 'Cédula'),
                ),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
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
                  _mostrarMensaje('El nombre del cliente es obligatorio.');
                  return;
                }

                Cliente nuevo = Cliente(
                  nombre: nombreController.text.trim(),
                  apellido: apellidoController.text.trim(),
                  telefono: telefonoController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  direccion: direccionController.text.trim().isEmpty
                      ? null
                      : direccionController.text.trim(),
                  activo: true,
                  tipoDocumento: "1",
                  nroDocumento: "V-${_cedulaController.text.trim()}",
                );

                clienteCreado = await _clienteService.crearCliente(nuevo);

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

    if (clienteCreado != null) {
      setState(() {
        _clientes.add(clienteCreado!);
        _clienteSeleccionado = clienteCreado;
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
                'Módulo de Ventas',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16.0),

            // Cliente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Cliente',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<Cliente>(
                            value: _clienteSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar cliente',
                            ),
                            items: _clientes.map((Cliente cliente) {
                              return DropdownMenuItem<Cliente>(
                                value: cliente,
                                child: Text(cliente.nombre),
                              );
                            }).toList(),
                            onChanged: (Cliente? nuevo) {
                              setState(() {
                                _clienteSeleccionado = nuevo;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: () {
                            _abrirDialogoNuevoCliente();
                          },
                          child: const Text('Nuevo cliente'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Agregar producto al pedido (incluye ubicación)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Agregar producto al pedido',
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
                                child: Text(u.nombreAlmacen),
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
                        ElevatedButton(
                          onPressed: () {
                            _agregarProductoAlPedido();
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

            // Detalle del pedido
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
                          'Detalle del pedido',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: _lineasPedido.isEmpty
                            ? const Center(
                                child: Text('No hay productos en el pedido.'),
                              )
                            : ListView.builder(
                                itemCount: _lineasPedido.length,
                                itemBuilder: (BuildContext context, int index) {
                                  DetalleVenta detalle = _lineasPedido[index];
                                  Producto? producto = _buscarProductoPorId(
                                    detalle.idProducto,
                                  );
                                  String nombreProducto = producto != null
                                      ? producto.nombre
                                      : 'Producto ${detalle.idProducto}';

                                  String textoUbicacion = '';
                                  // if (detalle.idUbicacion != null) {
                                  //   Ubicacion? ubicacion =
                                  //       _buscarUbicacionPorId(
                                  //         int.parse(detalle.idUbicacion),
                                  //       );
                                  //   String nombreUbicacion = ubicacion != null
                                  //       ? ubicacion.nombreAlmacen
                                  //       : 'Ubicación ${detalle.idUbicacion}';
                                  //   textoUbicacion =
                                  //       '\nUbicación: $nombreUbicacion';
                                  // }

                                  return ListTile(
                                    title: Text(nombreProducto),
                                    subtitle: Text(
                                      'Cantidad: ${detalle.cantidad} x ${detalle.precioUnitario} = ${detalle.subtotal}$textoUbicacion',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        _removerLineaPedido(index);
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
                          'Total: ${_calcularTotalPedido()}',
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

            // Historial de facturas emitidas
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
                          'Historial de facturas emitidas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: _ventas.isEmpty
                            ? const Center(
                                child: Text(
                                  'Todavía no se han emitido facturas.',
                                ),
                              )
                            : ListView.builder(
                                itemCount: _ventas.length,
                                itemBuilder: (BuildContext context, int index) {
                                  Venta venta = _ventas[index];

                                  return ListTile(
                                    title: Text(venta.nroComprobante),
                                    subtitle: Text('Total: ${venta.total}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.visibility),
                                      tooltip: 'Ver detalle',
                                      onPressed: () {
                                        _verDetalleVentaDesdeHistorial(venta);
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

            // Botón para emitir factura
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _emitirFactura();
                },
                child: const Text('Emitir factura'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
