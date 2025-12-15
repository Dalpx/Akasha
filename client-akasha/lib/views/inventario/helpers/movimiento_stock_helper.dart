import 'package:akasha/models/stock_ubicacion.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/services/inventario_service.dart';

class MovimientoStockHelper {
  final InventarioService _service;
  final Map<int, List<StockUbicacion>> _cache = <int, List<StockUbicacion>>{};

  MovimientoStockHelper(this._service);

  Future<void> ensureLoadedForProduct(int idProducto) async {
    if (_cache.containsKey(idProducto)) return;
    _cache[idProducto] =
        await _service.obtenerStockPorUbicacionDeProducto(idProducto);
  }

  Future<void> reloadForProduct(int idProducto) async {
    _cache[idProducto] =
        await _service.obtenerStockPorUbicacionDeProducto(idProducto);
  }

  int stockEnUbicacion(int? idProducto, Ubicacion? ubicacion) {
    if (idProducto == null || ubicacion == null) return 0;
    final stocks = _cache[idProducto] ?? <StockUbicacion>[];
    final item = stocks.firstWhere(
      (s) => s.idUbicacion == ubicacion.nombreAlmacen,
      orElse: () =>
          StockUbicacion(idUbicacion: ubicacion.nombreAlmacen, cantidad: 0),
    );
    return item.cantidad;
  }

  List<Ubicacion> ubicacionesConStock(int? idProducto, List<Ubicacion> todas) {
    if (idProducto == null) return const <Ubicacion>[];
    final stocks = _cache[idProducto] ?? <StockUbicacion>[];
    final names = stocks
        .where((s) => s.cantidad > 0)
        .map((s) => s.idUbicacion)
        .toSet();
    return todas.where((u) => names.contains(u.nombreAlmacen)).toList();
  }
}
