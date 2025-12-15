import 'package:flutter/material.dart';

import 'package:akasha/common/custom_tile.dart';
import 'package:akasha/models/movimiento_inventario.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_shared.dart';

class MovimientoHistorialSection extends StatelessWidget {
  final String title;

  final TextEditingController searchCtrl;
  final bool hasActiveFilters;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;
  final void Function(String) onSearchChanged;

  final List<MovimientoInventario> items;
  final int conteo;

  const MovimientoHistorialSection({
    super.key,
    required this.title,
    required this.searchCtrl,
    required this.hasActiveFilters,
    required this.onClearSearch,
    required this.onOpenFilters,
    required this.items,
    required this.conteo,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasSearch = searchCtrl.text.trim().isNotEmpty;

    final historialCard = HistorialSectionCard<MovimientoInventario>(
      items: items,
      emptyText: 'No hay movimientos para los filtros actuales.',
      listKey: const PageStorageKey('movimientos_historial_list'),
      itemBuilder: (_, m) {
        final isEntrada = m.tipoMovimiento.toLowerCase().trim() == 'entrada';
        return CustomTile(
          listTile: ListTile(
            leading: Icon(
              isEntrada ? Icons.arrow_upward : Icons.arrow_downward,
              color: isEntrada ? Colors.green : Colors.red,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text('${m.nombreProducto ?? "Producto"} · ${m.tipoMovimiento}'),
            subtitle: Text(
              '${m.fecha} · ${m.descripcion}\nUsuario: ${m.nombreUsuario ?? "-"} · Proveedor: ${m.nombreProveedor ?? "-"}',
            ),
            trailing: Text(
              m.cantidad.toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              height: 40,
              width: 400,
              child: SearchBar(
                controller: searchCtrl,
                hintText: 'Buscar por descripción...',
                onChanged: onSearchChanged,
                leading: const Icon(Icons.search),
                trailing: [
                  if (hasSearch)
                    IconButton(
                      tooltip: 'Limpiar',
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Filtros',
              onPressed: onOpenFilters,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.filter_list),
                  if (hasActiveFilters)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        child: Center(
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 18,
                              height: 0.9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        historialCard,
        const SizedBox(height: 12),
        Text('Movimientos encontrados ( $conteo )'),
      ],
    );
  }
}
