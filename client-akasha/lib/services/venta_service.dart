import '../models/venta.dart';
import '../models/detalle_venta.dart';
import 'inventario_service.dart';

/// Servicio que encapsula la lógica de negocio de las ventas.
/// Aquí se registran las facturas y sus detalles, y se actualiza el stock.
class VentaService {
  final List<Venta> _ventas = <Venta>[];
  final List<DetalleVenta> _detalles = <DetalleVenta>[];

  // Referencia al servicio de inventario para poder actualizar stock.
  final InventarioService _inventarioService;

  /// El constructor requiere una instancia de InventarioService.
  /// Esto permite que las ventas impacten el stock de productos.
  VentaService({
    required InventarioService inventarioService,
  }) : _inventarioService = inventarioService;

  /// Registra una venta con sus detalles.
  /// Además de guardar la venta, descuenta del stock las cantidades vendidas.
  /// Si el detalle tiene ubicación, descuenta de esa ubicación.
  Future<Venta> registrarVenta(
    Venta venta,
    List<DetalleVenta> detalles,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    int nuevoIdVenta = _ventas.length + 1;
    venta.idVenta = nuevoIdVenta;
    _ventas.add(venta);

    for (int i = 0; i < detalles.length; i++) {
      DetalleVenta detalle = detalles[i];
      detalle.idVenta = nuevoIdVenta;
      detalle.idDetalleVenta = _detalles.length + 1;
      _detalles.add(detalle);
    }

    // Actualizar stock en inventario según los detalles de la venta.
    for (int i = 0; i < detalles.length; i++) {
      DetalleVenta detalle = detalles[i];

      if (detalle.idUbicacion != null) {
        await _inventarioService.disminuirStockEnUbicacion(
          detalle.idProducto,
          detalle.idUbicacion!,
          detalle.cantidad,
        );
      } else {
        await _inventarioService.disminuirStock(
          detalle.idProducto,
          detalle.cantidad,
        );
      }
    }

    return venta;
  }

  /// Devuelve todas las ventas registradas.
  Future<List<Venta>> obtenerVentas() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _ventas;
  }

  /// Devuelve todos los detalles de una venta específica.
  Future<List<DetalleVenta>> obtenerDetallesPorVenta(int idVenta) async {
    await Future.delayed(const Duration(milliseconds: 200));

    List<DetalleVenta> resultado = <DetalleVenta>[];

    for (int i = 0; i < _detalles.length; i++) {
      DetalleVenta detalle = _detalles[i];
      if (detalle.idVenta == idVenta) {
        resultado.add(detalle);
      }
    }

    return resultado;
  }
}
