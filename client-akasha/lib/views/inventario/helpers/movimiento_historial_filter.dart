// Archivo: lib/views/inventario/helpers/movimiento_historial_filter.dart

import 'package:akasha/models/movimiento_inventario.dart';

class MovimientoHistorialFilters {
  // null = Todos, 1 = Entrada, 0 = Salida/Otros.
  int? tipoMovimiento; 

  bool get hasActiveFilters => tipoMovimiento != null;

  List<MovimientoInventario> apply(
    List<MovimientoInventario> items, {
    String? searchText,
  }) {
    Iterable<MovimientoInventario> filtered = items;

    // 1. Filtrar por texto de búsqueda (Descripción)
    final search = searchText?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      filtered = filtered.where((m) {
        // Busca en la descripción del movimiento
        return m.descripcion?.toLowerCase().contains(search) ?? false;
      });
    }

    // 2. Filtrar por tipo de movimiento (Entrada, Salida/Otros, o Todos)
    if (tipoMovimiento != null) {
      if (tipoMovimiento == 1) {
         // Mostrar solo 'entrada'
         filtered = filtered.where((m) => 
            m.tipoMovimiento.toLowerCase().trim() == 'entrada'
         );
      } else if (tipoMovimiento == 0) {
         // Mostrar 'salida' y cualquier otro tipo (ajuste, transferencia, etc.)
         // que no sea 'entrada'.
         filtered = filtered.where((m) => 
            m.tipoMovimiento.toLowerCase().trim() != 'entrada'
         );
      }
    }
    
    return filtered.toList();
  }

  void clear() {
    tipoMovimiento = null;
  }
}