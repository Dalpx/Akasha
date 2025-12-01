import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../models/ubicacion.dart';
import '../../models/movimiento_inventario.dart';
import '../../services/inventario_service.dart';
import '../../services/ubicacion_service.dart';
import '../../services/movimiento_inventario_service.dart';

/// Pantalla de ajuste / movimientos de inventario.
/// Permite registrar ENTRADAS o SALIDAS aisladas que afectan
/// el stock total y, opcionalmente, el stock por ubicación.
class MovimientosInventarioPage extends StatefulWidget {
  const MovimientosInventarioPage({Key? key}) : super(key: key);

  @override
  State<MovimientosInventarioPage> createState() {
    return _MovimientosInventarioPageState();
  }
}

class _MovimientosInventarioPageState extends State<MovimientosInventarioPage> {
  // Servicios
  final InventarioService _inventarioService = InventarioService();
  final UbicacionService _ubicacionService = UbicacionService();
  late final MovimientoInventarioService _movimientoService;

  // Listas de datos
  List<Producto> _productos = <Producto>[];
  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  List<MovimientoInventario> _movimientos = <MovimientoInventario>[];

  // Selecciones actuales
  Producto? _productoSeleccionado;
  Ubicacion? _ubicacionSeleccionada;
  String _tipoSeleccionado = 'ENTRADA'; // ENTRADA o SALIDA

  // Controles de formulario
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();

    _movimientoService = MovimientoInventarioService(
      inventarioService: _inventarioService,
    );

    _cargarDatosIniciales();
  }

  /// Carga productos, ubicaciones e historial de movimientos.
  Future<void> _cargarDatosIniciales() async {
    List<Producto> productos = await _inventarioService.obtenerProductos();
    List<Ubicacion> ubicaciones = await _ubicacionService
        .obtenerUbicacionesActivas();
    List<MovimientoInventario> movimientos = await _movimientoService
        .obtenerMovimientos();

    setState(() {
      _productos = productos;
      _ubicaciones = ubicaciones;
      _movimientos = movimientos;

      if (_productos.isNotEmpty) {
        _productoSeleccionado = _productos[0];
      }

      if (_ubicaciones.isNotEmpty) {
        _ubicacionSeleccionada = _ubicaciones[0];
      }

      _cargandoInicial = false;
    });
  }

  /// Muestra un mensaje breve en la parte inferior de la pantalla.
  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Convierte 'ENTRADA' o 'SALIDA' en etiquetas legibles.
  String _descripcionTipo(String tipo) {
    if (tipo.toUpperCase() == 'ENTRADA') {
      return 'Entrada';
    }
    if (tipo.toUpperCase() == 'SALIDA') {
      return 'Salida';
    }
    return tipo;
  }

  /// Registra un nuevo movimiento de inventario con los datos del formulario.
  Future<void> _registrarMovimiento() async {
    if (_productoSeleccionado == null) {
      _mostrarMensaje('Debe seleccionar un producto.');
      return;
    }

    int cantidad = int.tryParse(_cantidadController.text) ?? 0;
    if (cantidad <= 0) {
      _mostrarMensaje('La cantidad debe ser mayor que cero.');
      return;
    }

    if (_productoSeleccionado!.idProducto == null) {
      _mostrarMensaje('El producto no tiene id asignado.');
      return;
    }

    String descripcion = _descripcionController.text.trim();
    if (descripcion.isEmpty) {
      _mostrarMensaje('Debe indicar una descripción del movimiento.');
      return;
    }

    int? idUbicacion;
    if (_ubicacionSeleccionada != null &&
        _ubicacionSeleccionada!.idUbicacion != null) {
      idUbicacion = _ubicacionSeleccionada!.idUbicacion;
    }

    MovimientoInventario movimiento = MovimientoInventario(
      idProducto: _productoSeleccionado!.idProducto!,
      idUbicacion: idUbicacion,
      fecha: DateTime.now(),
      cantidad: cantidad,
      tipo: _tipoSeleccionado,
      descripcion: descripcion,
    );

    MovimientoInventario registrado = await _movimientoService
        .registrarMovimiento(movimiento);

    setState(() {
      _movimientos.add(registrado);
      _cantidadController.text = '';
      _descripcionController.text = '';
    });

    _mostrarMensaje('Movimiento registrado correctamente.');
  }

  /// Formatea una fecha en formato sencillo yyyy-MM-dd HH:mm.
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

  @override
  Widget build(BuildContext context) {
    if (_cargandoInicial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos de inventario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Formulario de movimiento
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Nuevo movimiento (ajuste)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),

                    // Producto
                    DropdownButtonFormField<Producto>(
                      value: _productoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Producto'),
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
                    const SizedBox(height: 12.0),

                    // Ubicación (opcional)
                    DropdownButtonFormField<Ubicacion>(
                      value: _ubicacionSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Ubicación',
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
                    const SizedBox(height: 12.0),

                    // Tipo de movimiento
                    DropdownButtonFormField<String>(
                      value: _tipoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de movimiento',
                      ),
                      items: <String>['ENTRADA', 'SALIDA'].map((String tipo) {
                        return DropdownMenuItem<String>(
                          value: tipo,
                          child: Text(_descripcionTipo(tipo)),
                        );
                      }).toList(),
                      onChanged: (String? nuevo) {
                        setState(() {
                          _tipoSeleccionado = nuevo ?? 'ENTRADA';
                        });
                      },
                    ),
                    const SizedBox(height: 12.0),

                    // Cantidad
                    TextField(
                      controller: _cantidadController,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12.0),

                    // Descripción
                    TextField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción del movimiento',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12.0),

                    // Botón registrar
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          _registrarMovimiento();
                        },
                        child: const Text('Registrar movimiento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16.0),

            // Historial de movimientos
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Historial de movimientos',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: _movimientos.isEmpty
                            ? const Center(
                                child: Text(
                                  'Todavía no se han registrado movimientos.',
                                ),
                              )
                            : ListView.builder(
                                itemCount: _movimientos.length,
                                itemBuilder: (BuildContext context, int index) {
                                  MovimientoInventario mov =
                                      _movimientos[index];

                                  Producto? producto = _buscarProductoPorId(
                                    mov.idProducto,
                                  );
                                  String nombreProducto = producto != null
                                      ? producto.nombre
                                      : 'Producto ${mov.idProducto}';

                                  String nombreTipo = _descripcionTipo(
                                    mov.tipo,
                                  );

                                  String nombreUbicacion = '-';
                                  if (mov.idUbicacion != null) {
                                    Ubicacion? ubicacion =
                                        _buscarUbicacionPorId(mov.idUbicacion!);
                                    if (ubicacion != null) {
                                      nombreUbicacion = ubicacion.nombre;
                                    } else {
                                      nombreUbicacion =
                                          'Ubicación ${mov.idUbicacion}';
                                    }
                                  }

                                  return ListTile(
                                    title: Text(
                                      '$nombreTipo - $nombreProducto',
                                    ),
                                    subtitle: Text(
                                      'Fecha: ${_formatearFecha(mov.fecha)}\n'
                                      'Cantidad: ${mov.cantidad}\n'
                                      'Ubicación: $nombreUbicacion\n'
                                      'Descripción: ${mov.descripcion}',
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
          ],
        ),
      ),
    );
  }
}
