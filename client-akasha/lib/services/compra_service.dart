import '../models/compra.dart';
import '../models/detalle_compra.dart';
import 'inventario_service.dart';

/// Servicio que encapsula la lógica de negocio de las compras.
/// Aquí se registran las compras a proveedores y se actualiza el stock.
class CompraService {
  final List<Compra> _compras = <Compra>[];
  final List<DetalleCompra> _detalles = <DetalleCompra>[];

  final InventarioService _inventarioService;

  /// El constructor requiere una instancia de InventarioService.
  /// De esta forma, cada compra puede impactar el stock compartido.
  CompraService({
    required InventarioService inventarioService,
  }) : _inventarioService = inventarioService;

  /// Registra una compra con sus detalles.
  /// Además de guardar la compra, aumenta el stock según las cantidades compradas.
  /// Si el detalle tiene ubicación, aumenta en esa ubicación.
  Future<Compra> registrarCompra(
    Compra compra,
    List<DetalleCompra> detalles,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    int nuevoIdCompra = _compras.length + 1;
    compra.idCompra = nuevoIdCompra;
    _compras.add(compra);

    for (int i = 0; i < detalles.length; i++) {
      DetalleCompra detalle = detalles[i];
      detalle.idCompra = nuevoIdCompra;
      detalle.idDetalleCompra = _detalles.length + 1;
      _detalles.add(detalle);
    }

    // Actualizar stock en inventario según los detalles de la compra.
    for (int i = 0; i < detalles.length; i++) {
      DetalleCompra detalle = detalles[i];

      if (detalle.idUbicacion != null) {
        await _inventarioService.aumentarStockEnUbicacion(
          detalle.idProducto,
          detalle.idUbicacion!,
          detalle.cantidad,
        );
      } else {
        await _inventarioService.aumentarStock(
          detalle.idProducto,
          detalle.cantidad,
        );
      }
    }

    return compra;
  }

  /// Devuelve todas las compras registradas.
  Future<List<Compra>> obtenerCompras() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _compras;
  }

  /// Devuelve los detalles de una compra específica.
  Future<List<DetalleCompra>> obtenerDetallesPorCompra(
    int idCompra,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));

    List<DetalleCompra> resultado = <DetalleCompra>[];

    for (int i = 0; i < _detalles.length; i++) {
      DetalleCompra detalle = _detalles[i];
      if (detalle.idCompra == idCompra) {
        resultado.add(detalle);
      }
    }

    return resultado;
  }
}
