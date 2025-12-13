import 'package:akasha/models/stock_ubicacion.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/services/inventario_service.dart';

class StockHelper {
  final InventarioService _inventarioService;

  // Key: idProducto, Value: List<StockUbicacion>
  final Map<int, List<StockUbicacion>> _cache = {};
  final Map<int, Future<List<StockUbicacion>>> _inFlight = {};

  StockHelper(this._inventarioService);

  bool has(int idProducto) => _cache.containsKey(idProducto);

  Future<void> loadForProduct(int idProducto) async {
    final future = _inFlight[idProducto] ??=
        _inventarioService.obtenerStockPorUbicacionDeProducto(idProducto);

    try {
      final stock = await future;
      _cache[idProducto] = stock;
    } finally {
      _inFlight.remove(idProducto);
    }
  }

  Future<void> ensureLoadedForProduct(int? idProducto) async {
    if (idProducto == null) return;
    if (!has(idProducto)) await loadForProduct(idProducto);
  }

  Future<void> ensureLoadedForProducts(Iterable<int> ids) async {
    final uniq = ids.toSet();
    await Future.wait(uniq.map(loadForProduct));
  }

  int stockEnUbicacion(int? idProducto, Ubicacion? ubicacion) {
    if (idProducto == null || ubicacion == null) return 0;

    final stocks = _cache[idProducto] ?? const <StockUbicacion>[];

    // Comparación usando el nombre del almacén (String)
    final stockItem = stocks.firstWhere(
      (s) => s.idUbicacion == ubicacion.nombreAlmacen,
      orElse: () => StockUbicacion(
        idUbicacion: ubicacion.nombreAlmacen,
        cantidad: 0,
      ),
    );

    return stockItem.cantidad;
  }

  /// COMPRAS: ubicaciones donde el producto está "asignado" (tiene registro),
  /// si no hay registros (nuevo/no asignado) -> devuelve todas.
  List<Ubicacion> ubicacionesAsignadas(int? idProducto, List<Ubicacion> todas) {
    if (idProducto == null) return todas;

    final stocks = _cache[idProducto] ?? const <StockUbicacion>[];
    if (stocks.isEmpty) return todas;

    final names = stocks.map((s) => s.idUbicacion).toSet();

    return todas.where((u) => names.contains(u.nombreAlmacen)).toList();
  }

  /// VENTAS: ubicaciones donde el producto tiene stock > 0.
  List<Ubicacion> ubicacionesConStock(int? idProducto, List<Ubicacion> todas) {
    if (idProducto == null) return const <Ubicacion>[];

    final stocks = _cache[idProducto] ?? const <StockUbicacion>[];

    final names = stocks
        .where((s) => s.cantidad > 0)
        .map((s) => s.idUbicacion)
        .toSet();

    return todas.where((u) => names.contains(u.nombreAlmacen)).toList();
  }

  void clear() {
    _cache.clear();
    _inFlight.clear();
  }
}
