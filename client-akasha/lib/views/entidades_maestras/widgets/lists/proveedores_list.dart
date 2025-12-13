import 'package:akasha/widgets/custom_tile.dart';
import 'package:flutter/material.dart';
import '../../../../../models/proveedor.dart';

class ProveedoresList extends StatelessWidget {
  final Future<List<Proveedor>> future;
  final List<Proveedor>? cached;
  final Future<void> Function(Proveedor) onEdit;
  final void Function(Proveedor) onDelete;

  const ProveedoresList({
    super.key,
    required this.future,
    this.cached,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Proveedor>>(
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
            child: Text('Error al cargar proveedores: ${snapshot.error}'),
          );
        }

        if (data.isEmpty) {
          return const Center(child: Text('No hay proveedores'));
        }

        return ListView.builder(
          key: const PageStorageKey('proveedores_list'),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final p = data[index];

            return CustomTile(
              listTile:  ListTile(
                title: Text(p.nombre),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => onEdit(p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onDelete(p),
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
