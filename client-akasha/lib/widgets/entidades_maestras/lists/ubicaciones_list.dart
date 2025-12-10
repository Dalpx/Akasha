import 'package:akasha/widgets/custom_tile.dart';
import 'package:flutter/material.dart';
import '../../../models/ubicacion.dart';

class UbicacionesList extends StatelessWidget {
  final Future<List<Ubicacion>> future;
  final List<Ubicacion>? cached;
  final Future<void> Function(Ubicacion) onEdit;
  final void Function(Ubicacion) onDelete;

  const UbicacionesList({
    super.key,
    required this.future,
    this.cached,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ubicacion>>(
      future: future,
      initialData: cached,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting &&
            data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && data.isEmpty) {
          return Center(
            child: Text('Error al cargar ubicaciones: ${snapshot.error}'),
          );
        }

        if (data.isEmpty) {
          return const Center(child: Text('No hay ubicaciones'));
        }

        return ListView.builder(
          key: const PageStorageKey('ubicaciones_list'),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final u = data[index];

            return CustomTile(
              listTile: ListTile(
                title: Text(u.nombreAlmacen),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => onEdit(u),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onDelete(u),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
