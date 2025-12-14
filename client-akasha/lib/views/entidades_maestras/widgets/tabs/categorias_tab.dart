import 'package:flutter/material.dart';

import '../../../../../models/categoria.dart';
import '../../../../../services/categoria_service.dart';
import '../crud_tab_layout.dart';
import '../lists/categorias_list.dart';
import '../dialogs/categoria_form_dialog.dart';

class CategoriasTab extends StatefulWidget {
  final CategoriaService service;
  final Future<List<Categoria>> future;
  final VoidCallback onReload;
  final void Function(Categoria) onDelete;

  const CategoriasTab({
    super.key,
    required this.service,
    required this.future,
    required this.onReload,
    required this.onDelete,
  });

  @override
  State<CategoriasTab> createState() => _CategoriasTabState();
}

class _CategoriasTabState extends State<CategoriasTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Future<List<Categoria>> _baseFuture;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _baseFuture = widget.future;
  }

  @override
  void didUpdateWidget(covariant CategoriasTab oldWidget) {
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

  List<Categoria> _filtrar(List<Categoria> items) {
    final q = _searchText.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((c) {
      final id = '${c.idCategoria ?? ''}'.toLowerCase();
      final nombre = c.nombreCategoria.toLowerCase();
      return id.contains(q) || nombre.contains(q);
    }).toList();
  }

  Future<List<Categoria>> _futureFiltrado() async {
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
      buttonLabel: 'Nueva categoría',
      buttonIcon: Icons.add,
      onAdd: () async {
        final ok = await showCategoriaFormDialog(
          context,
          service: widget.service,
        );

        if (!mounted) return;
        if (ok) widget.onReload();
      },
      title: 'Categorías',
      subtitle: 'Gestion de categorías',
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 40,
                width: 300,
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: 'Buscar categorías...',
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
            //   IconButton(
            //     tooltip: 'Filtros',
            //     onPressed: _abrirFiltros,
            //     icon: Stack(
            //       clipBehavior: Clip.none,
            //       children: [
            //         const Icon(Icons.filter_list),
            //         Positioned(
            //           right: -6,
            //           top: -6,
            //           child: Container(
            //             width: 16,
            //             height: 16,
            //             decoration: BoxDecoration(
            //               shape: BoxShape.circle,
            //               color: Theme.of(context).colorScheme.primary,
            //             ),
            //             child: Center(
            //               child: Text(
            //                 '•',
            //                 style: TextStyle(
            //                   color: Theme.of(context).colorScheme.onPrimary,
            //                   fontSize: 18,
            //                   height: 0.9,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CategoriasList(
              future: _futureFiltrado(),
              onEdit: (c) async {
                final ok = await showCategoriaFormDialog(
                  context,
                  service: widget.service,
                  initial: c,
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
