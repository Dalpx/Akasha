import 'package:akasha/widgets/custom_tile.dart';
import 'package:flutter/material.dart';
import '../../../../../models/categoria.dart';

class CategoriasList extends StatelessWidget {
  final Future<List<Categoria>> future;
  final List<Categoria>? cached;
  final Future<void> Function(Categoria) onEdit;
  final void Function(Categoria) onDelete;

  const CategoriasList({
    super.key,
    required this.future,
    this.cached,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Categoria>>(
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
            child: Text('Error al cargar categorías: ${snapshot.error}'),
          );
        }

        if (data.isEmpty) {
          return const Center(child: Text('No hay categorías'));
        }

        return ListView.builder(
          key: const PageStorageKey('categorias_list'),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final c = data[index];

            return CustomTile(
              listTile: ListTile(
                title: Text(c.nombreCategoria),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => onEdit(c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onDelete(c),
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
