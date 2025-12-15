import 'package:akasha/models/movimiento_inventario.dart';

class MovimientoHistorialFilters {
  int? tipoMovimiento;

  bool get hasActiveFilters => tipoMovimiento != null;

  List<MovimientoInventario> apply(
    List<MovimientoInventario> movimientos, {
    required String searchText,
  }) {
    Iterable<MovimientoInventario> res = movimientos;

    if (tipoMovimiento != null) {
      final tipo = tipoMovimiento == 1 ? 'entrada' : 'salida';
      res = res.where((m) => m.tipoMovimiento.toLowerCase().trim() == tipo);
    }

    final q = searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((m) => (m.descripcion).toLowerCase().contains(q));
    }

    return res.toList();
  }
}
