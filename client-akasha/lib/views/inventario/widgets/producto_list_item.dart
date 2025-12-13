import 'package:akasha/widgets/custom_tile.dart';
import 'package:flutter/material.dart';
import '../../../../../models/producto.dart';
import '../../../../../services/inventario_service.dart';

class ProductoListItem extends StatelessWidget {
  final Producto producto;
  final InventarioService inventarioService;

  // Callbacks para las acciones.
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
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      // Solicitamos el stock específico de este producto
      future: inventarioService.obtenerStockTotalDeProducto(
        producto.idProducto!,
      ),
      builder: (context, snapshot) {
        final int stock = snapshot.data ?? 0;

        return CustomTile(
          listTile: ListTile(
            title: Text(
              producto.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              'STOCK: $stock | SKU: ${producto.sku}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de visualización rápida (el "ojito")
                IconButton(
                  onPressed: onVerDetalle ?? () {},
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Ver detalle',
                ),
                // Menú de opciones
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
                          Text('Eliminar (Desactivar)'),
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
