import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../models/ubicacion.dart';
import '../../models/stock_ubicacion.dart';
import '../../services/ubicacion_service.dart';
import '../../services/inventario_service.dart';
import '../../core/app_routes.dart';

/// Pantalla que permite gestionar las ubicaciones de un producto.
/// Se listan las ubicaciones y el stock de ese producto en cada una.
class UbicacionesProductoPage extends StatefulWidget {
  final Producto producto;

  const UbicacionesProductoPage({
    Key? key,
    required this.producto,
  }) : super(key: key);

  @override
  State<UbicacionesProductoPage> createState() {
    return _UbicacionesProductoPageState();
  }
}

class _UbicacionesProductoPageState extends State<UbicacionesProductoPage> {
  final UbicacionService _ubicacionService = UbicacionService();
  final InventarioService _inventarioService = InventarioService();

  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  List<StockUbicacion> _stockUbicaciones = <StockUbicacion>[];

  Ubicacion? _ubicacionSeleccionada;
  final TextEditingController _cantidadController = TextEditingController();

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Carga ubicaciones y stock del producto.
  Future<void> _cargarDatos() async {
    int idProducto = widget.producto.idProducto ?? 0;

    List<Ubicacion> ubicaciones =
        await _ubicacionService.obtenerUbicacionesActivas();
    List<StockUbicacion> stock =
        await _inventarioService.obtenerStockPorUbicacionDeProducto(
      idProducto,
    );

    setState(() {
      _ubicaciones = ubicaciones;
      _stockUbicaciones = stock;

      if (_ubicaciones.isNotEmpty) {
        _ubicacionSeleccionada = _ubicaciones[0];
        int actual =
            _obtenerCantidadEnUbicacion(_ubicacionSeleccionada!.idUbicacion!);
        _cantidadController.text = actual.toString();
      }

      _cargando = false;
    });
  }

  /// Devuelve la cantidad actual en una ubicación concreta para el producto.
  int _obtenerCantidadEnUbicacion(int idUbicacion) {
    for (int i = 0; i < _stockUbicaciones.length; i++) {
      StockUbicacion s = _stockUbicaciones[i];
      if (s.idUbicacion == idUbicacion) {
        return s.cantidad;
      }
    }
    return 0;
  }

  /// Establece (crea o actualiza) el stock en la ubicación seleccionada.
  Future<void> _guardarStockEnUbicacion() async {
    if (_ubicacionSeleccionada == null) {
      _mostrarMensaje('Debe seleccionar una ubicación.');
      return;
    }

    if (widget.producto.idProducto == null) {
      _mostrarMensaje('El producto no tiene id asignado.');
      return;
    }

    int cantidad = int.tryParse(_cantidadController.text) ?? 0;
    if (cantidad < 0) {
      _mostrarMensaje('La cantidad no puede ser negativa.');
      return;
    }

    await _inventarioService.establecerStockEnUbicacion(
      widget.producto.idProducto!,
      _ubicacionSeleccionada!.idUbicacion!,
      cantidad,
    );

    // Volvemos a cargar el stock por ubicación
    List<StockUbicacion> stockActualizado =
        await _inventarioService.obtenerStockPorUbicacionDeProducto(
      widget.producto.idProducto!,
    );

    setState(() {
      _stockUbicaciones = stockActualizado;
    });

    _mostrarMensaje('Stock actualizado correctamente.');
  }

  /// Abre la pantalla general de gestión de ubicaciones.
  /// Al volver, recarga las ubicaciones para que las nuevas aparezcan.
  Future<void> _abrirGestionUbicaciones() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.rutaGestionUbicaciones,
    );

    // Cuando el usuario regresa, recargamos todo.
    setState(() {
      _cargando = true;
    });
    await _cargarDatos();
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicaciones - ${widget.producto.nombre}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          // Botón para ir a la gestión general de ubicaciones
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Gestionar ubicaciones',
            onPressed: () {
              _abrirGestionUbicaciones();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Resumen de stock total
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Stock total: ${0}',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Lista de ubicaciones con su stock
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Stock por ubicación',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: _ubicaciones.isEmpty
                            ? const Center(
                                child: Text('No hay ubicaciones definidas.'),
                              )
                            : ListView.builder(
                                itemCount: _ubicaciones.length,
                                itemBuilder:
                                    (BuildContext context, int index) {
                                  Ubicacion u = _ubicaciones[index];
                                  int cantidad =
                                      _obtenerCantidadEnUbicacion(
                                    u.idUbicacion!,
                                  );

                                  return ListTile(
                                    title: Text(u.nombreAlmacen),
                                    subtitle: Text(
                                      'Stock en esta ubicación: $cantidad',
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
