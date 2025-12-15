import 'package:flutter/material.dart';

import '../../../../../models/ubicacion.dart';
import '../../../../../services/ubicacion_service.dart';
import '../crud_tab_layout.dart';
import '../lists/ubicaciones_list.dart';
import '../dialogs/ubicacion_form_dialog.dart';

class UbicacionesTab extends StatefulWidget {
  final UbicacionService service;
  final Future<List<Ubicacion>> future;
  final VoidCallback onReload;
  final void Function(Ubicacion) onDelete;

  const UbicacionesTab({
    super.key,
    required this.service,
    required this.future,
    required this.onReload,
    required this.onDelete,
  });

  @override
  State<UbicacionesTab> createState() => _UbicacionesTabState();
}

class _UbicacionesTabState extends State<UbicacionesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Future<List<Ubicacion>> _baseFuture;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _baseFuture = widget.future;
  }

  @override
  void didUpdateWidget(covariant UbicacionesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      _baseFuture = widget.future;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _limpiarBusqueda() {
    _searchCtrl.clear();
    setState(() => _searchText = '');
  }

  List<Ubicacion> _filtrar(List<Ubicacion> items) {
    final q = _searchText.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((u) {
      final id = '${u.idUbicacion ?? ''}'.toLowerCase();
      final nombre = u.nombreAlmacen.toLowerCase();
      final desc = (u.descripcion ?? '').toLowerCase();
      return id.contains(q) || nombre.contains(q) || desc.contains(q);
    }).toList();
  }

  Future<List<Ubicacion>> _futureFiltrado() async {
    final items = await _baseFuture;
    return _filtrar(items);
  }

  Future<void> _abrirFiltros() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Filtros'),
        content: const Text('Aquí puedes agregar filtros adicionales después.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return CrudTabLayout(
      buttonLabel: 'Nueva Ubicacion',
      buttonIcon: Icons.add,
      onAdd: () async {
        final ok = await showUbicacionFormDialog(
          context,
          service: widget.service,
        );

        if (!mounted) return;
        if (ok) widget.onReload();
      },
      title: 'Ubicaciones',
      subtitle: 'Gestion de ubicaciones',
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 40,
                width: 300,
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: 'Buscar ubicaciones...',
                  onChanged: (value) => setState(() => _searchText = value),
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchText.trim().isNotEmpty)
                      IconButton(
                        tooltip: 'Limpiar',
                        onPressed: _limpiarBusqueda,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // IconButton(
              //   tooltip: 'Filtros',
              //   onPressed: _abrirFiltros,
              //   icon: Stack(
              //     clipBehavior: Clip.none,
              //     children: [
              //       const Icon(Icons.filter_list),
              //       Positioned(
              //         right: -6,
              //         top: -6,
              //         child: Container(
              //           width: 16,
              //           height: 16,
              //           decoration: BoxDecoration(
              //             shape: BoxShape.circle,
              //             color: Theme.of(context).colorScheme.primary,
              //           ),
              //           child: Center(
              //             child: Text(
              //               '•',
              //               style: TextStyle(
              //                 color: Theme.of(context).colorScheme.onPrimary,
              //                 fontSize: 18,
              //                 height: 0.9,
              //                 fontWeight: FontWeight.bold,
              //               ),
              //             ),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: UbicacionesList(
              future: _futureFiltrado(),
              onEdit: (u) async {
                final ok = await showUbicacionFormDialog(
                  context,
                  service: widget.service,
                  initial: u,
                );

                if (!mounted) return;
                if (ok) widget.onReload();
              },
              onDelete: widget.onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
