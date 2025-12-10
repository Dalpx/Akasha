import 'package:akasha/models/proveedor.dart';
import 'package:akasha/services/proveedor_service.dart';
import 'package:akasha/widgets/entidades_maestras/crud_tab_layout.dart';
import 'package:akasha/widgets/entidades_maestras/dialogs/proveedor_form_dialog.dart';
import 'package:akasha/widgets/entidades_maestras/lists/proveedores_list.dart';
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
      child: ProveedoresList(
        future: widget.future,
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
    );
  }
}
