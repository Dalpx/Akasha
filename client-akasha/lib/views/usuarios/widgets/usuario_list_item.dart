import 'package:akasha/models/usuario.dart';
import 'package:akasha/common/custom_tile.dart';
import 'package:flutter/material.dart';

class UsuarioListItem extends StatelessWidget {
  final Usuario usuario;
  final int index;
  // Callbacks para que la página padre maneje la navegación y la lógica de negocio.
  final VoidCallback onEditar;
  final VoidCallback onDesactivar;
  final VoidCallback onVerDetalle;

  const UsuarioListItem({
    super.key,
    required this.usuario,
    required this.onEditar,
    required this.onDesactivar,
    required this.onVerDetalle,
    required this.index,
  });

  String _textoTipoUsuario(String tipoUsuario) {
    switch (tipoUsuario.toUpperCase()) {
      case 'SUPER':
        return 'Super';
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'ALMACEN':
        return 'Almacen';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: CustomTile(
        listTile: ListTile(
          leading: Text(
            index.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          title: Text(
            usuario.nombreCompleto!,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Tipo: ${_textoTipoUsuario(usuario.tipoUsuario!)}'),
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
      ),
    );
  }
}
