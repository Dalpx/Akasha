import 'package:flutter/material.dart';

import '../../../models/categoria.dart';
import '../../../services/categoria_service.dart';
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
      child: CategoriasList(
        future: widget.future,
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
    );
  }
}
