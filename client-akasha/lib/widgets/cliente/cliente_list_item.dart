import 'package:akasha/widgets/custom_tile.dart';
import 'package:flutter/material.dart';
import '../../models/cliente.dart';

class ClienteListItem extends StatelessWidget {
  final Cliente cliente;
  // Callbacks para que la página padre maneje la navegación y la lógica de negocio.
  final VoidCallback onEditar;
  final VoidCallback onDesactivar;
  final VoidCallback onVerDetalle;

  const ClienteListItem({
    super.key,
    required this.cliente,
    required this.onEditar,
    required this.onDesactivar,
    required this.onVerDetalle,
  });

  String _textoTipoDocumento(String tipoDocumento) {
    if (tipoDocumento.toUpperCase().contains('CEDULA')) return 'CI';
    if (tipoDocumento.toUpperCase().contains('PASAPORTE')) return 'PAS';
    return tipoDocumento;
  }

  @override
  Widget build(BuildContext context) {
    return CustomTile(
      listTile: ListTile(
        title: Text(
          '${cliente.nombre} ${cliente.apellido}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_textoTipoDocumento(cliente.tipoDocumento)} ${cliente.nroDocumento}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Botón de visualización rápida (el "ojito")
            IconButton(
              onPressed: onVerDetalle,
              icon: const Icon(Icons.visibility),
              tooltip: 'Ver detalle',
            ),
            // Menú de opciones
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'editar':
                    onEditar();
                    break;
                  case 'eliminar':
                    onDesactivar();
                    break;
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<String>>[
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
                      Icon(Icons.delete, color: Colors.red),
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
  }
}
