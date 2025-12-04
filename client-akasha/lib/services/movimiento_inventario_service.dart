import '../models/movimiento_inventario.dart';
import 'inventario_service.dart';

/// Servicio que gestiona los movimientos aislados de inventario.
/// Cada movimiento puede ser una ENTRADA o una SALIDA.
/// Al registrar un movimiento se actualiza el stock total
/// y, si se indica, el stock de una ubicación específica.
class MovimientoInventarioService {
  final List<MovimientoInventario> _movimientos = <MovimientoInventario>[];

  final InventarioService _inventarioService;

  /// El constructor requiere una instancia de InventarioService
  /// para poder actualizar el stock de productos.
  MovimientoInventarioService({
    required InventarioService inventarioService,
  }) : _inventarioService = inventarioService;

  /// Registra un movimiento de inventario.
  /// - Asigna un id interno.
  /// - Actualiza stock total y por ubicación (si aplica).
  /// - Devuelve el movimiento con id asignado.
  Future<MovimientoInventario> registrarMovimiento(
    MovimientoInventario movimiento,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    int nuevoId = _movimientos.length + 1;
    movimiento.idMovimiento = nuevoId;
    _movimientos.add(movimiento);

    bool esEntrada = movimiento.tipo.toUpperCase() == 'ENTRADA';
    bool esSalida = movimiento.tipo.toUpperCase() == 'SALIDA';

    if (esEntrada) {
      if (movimiento.idUbicacion != null) {
        await _inventarioService.aumentarStockEnUbicacion(
          movimiento.idProducto,
          movimiento.idUbicacion!.toString(),
          movimiento.cantidad,
        );
      } else {
        await _inventarioService.aumentarStock(
          movimiento.idProducto,
          movimiento.cantidad,
        );
      }
    } else if (esSalida) {
      if (movimiento.idUbicacion != null) {
        await _inventarioService.disminuirStockEnUbicacion(
          movimiento.idProducto,
          movimiento.idUbicacion!.toString(),
          movimiento.cantidad,
        );
      } else {
        await _inventarioService.disminuirStock(
          movimiento.idProducto,
          movimiento.cantidad,
        );
      }
    }

    // Nota: en un sistema real aquí se podrían registrar también
    // movimientos de Kardex, usuario que hizo el ajuste, etc.

    return movimiento;
  }

  /// Devuelve la lista de todos los movimientos registrados.
  Future<List<MovimientoInventario>> obtenerMovimientos() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _movimientos;
  }
}
