import 'package:akasha/common/custom_tile.dart';
import 'package:flutter/material.dart';
import '../../../../../../models/producto.dart';
import '../../../../../../services/inventario_service.dart';

class ProductoListItem extends StatelessWidget {
  final int index;
  final Producto producto;
  final InventarioService inventarioService;

  final VoidCallback onVerUbicaciones;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback? onVerDetalle;

  const ProductoListItem({
    super.key,
    required this.producto,
    required this.inventarioService,
    required this.onVerUbicaciones,
    required this.onEditar,
    required this.onEliminar,
    this.onVerDetalle,
    required this.index,
  });

  Widget? _buildStockBadge(BuildContext context, int stock) {
    if (stock >= 10) return null;

    final bool sinStock = stock == 0;
    final Color bg = sinStock
        ? Theme.of(context).colorScheme.error
        : Colors.orange.shade700;
    // final Color fg = sinStock
    //     ? Theme.of(context).colorScheme.onError
    //     : Colors.white;
    final IconData icon = sinStock
        ? Icons.error_rounded
        : Icons.warning_amber_rounded;
    final String tooltip = sinStock
        ? 'Stock: 0. Por favor agregue stock'
        : 'Stock: 10. Evalue la reposición de stock';

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: bg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: inventarioService.obtenerStockTotalDeProducto(
        producto.idProducto!,
      ),
      builder: (context, snapshot) {
        final bool hasStock = snapshot.hasData && snapshot.data != null;
        final int? stock = hasStock ? snapshot.data : null;

        final String stockText = stock?.toString() ?? '...';
        final Widget? badge = stock == null
            ? null
            : _buildStockBadge(context, stock);

        return CustomTile(
          listTile: ListTile(
            leading: Text(
              index.toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    producto.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'STOCK: $stockText | SKU: ${producto.sku}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badge != null) ...[const SizedBox(width: 8), badge],
                IconButton(
                  onPressed: onVerDetalle ?? () {},
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Ver detalle',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'ubicaciones':
                        onVerUbicaciones();
                        break;
                      case 'editar':
                        onEditar();
                        break;
                      case 'eliminar':
                        onEliminar();
                        break;
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'ubicaciones',
                      child: Row(
                        children: [
                          Icon(Icons.location_on),
                          SizedBox(width: 8),
                          Text('Ubicaciones'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Opciones',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
