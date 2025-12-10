import 'package:flutter/material.dart';

import '../../../models/ubicacion.dart';
import '../../../services/ubicacion_service.dart';
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
      child: UbicacionesList(
        future: widget.future,
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
    );
  }
}
