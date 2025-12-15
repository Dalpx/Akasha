import 'package:akasha/models/proveedor.dart';
import 'package:akasha/services/proveedor_service.dart';
import 'package:akasha/views/entidades_maestras/widgets/crud_tab_layout.dart';
import 'package:akasha/views/entidades_maestras/widgets/dialogs/proveedor_form_dialog.dart';
import 'package:akasha/views/entidades_maestras/widgets/lists/proveedores_list.dart';
import 'package:flutter/material.dart';

class ProveedoresTab extends StatefulWidget {
  final ProveedorService service;
  final Future<List<Proveedor>> future;
  final VoidCallback onReload;
  final void Function(Proveedor) onDelete;

  const ProveedoresTab({
    super.key,
    required this.service,
    required this.future,
    required this.onReload,
    required this.onDelete,
  });

  @override
  State<ProveedoresTab> createState() => _ProveedoresTabState();
}

class _ProveedoresTabState extends State<ProveedoresTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Future<List<Proveedor>> _baseFuture;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _baseFuture = widget.future;
  }

  @override
  void didUpdateWidget(covariant ProveedoresTab oldWidget) {
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

  List<Proveedor> _filtrar(List<Proveedor> items) {
    final q = _searchText.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((p) {
      final id = '${p.idProveedor ?? ''}'.toLowerCase();
      final nombre = p.nombre.toLowerCase();
      final tel = p.telefono.toLowerCase();
      final correo = (p.correo ?? '').toLowerCase();
      final dir = (p.direccion ?? '').toLowerCase();
      return id.contains(q) ||
          nombre.contains(q) ||
          tel.contains(q) ||
          correo.contains(q) ||
          dir.contains(q);
    }).toList();
  }

  Future<List<Proveedor>> _futureFiltrado() async {
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
      buttonLabel: 'Nuevo proveedor',
      buttonIcon: Icons.add,
      onAdd: () async {
        final ok = await showProveedorFormDialog(
          context,
          service: widget.service,
        );

        if (!mounted) return;
        if (ok) widget.onReload();
      },
      title: 'Proveedores',
      subtitle: 'Gestion de proveedores',
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 40,
                width: 300,
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: 'Buscar proveedores...',
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
            //   const SizedBox(width: 8),
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
            child: ProveedoresList(
              future: _futureFiltrado(),
              onEdit: (p) async {
                final ok = await showProveedorFormDialog(
                  context,
                  service: widget.service,
                  initial: p,
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
