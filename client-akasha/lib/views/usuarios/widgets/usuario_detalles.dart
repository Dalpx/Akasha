import 'package:akasha/models/usuario.dart';
import 'package:flutter/material.dart';

class UsuarioDetalles extends StatelessWidget {
  
  final Usuario usuario;

  const UsuarioDetalles({super.key, required this.usuario});

  // Función auxiliar para obtener el texto legible del tipo de usuario
  String _getTextoTipoUsuario(String tipoUsuario) {
    switch (tipoUsuario.toUpperCase()) {
      case 'SUPER':
        return 'Super Administrador';
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'ALMACEN':
        return 'Almacén';
      default:
        return 'Desconocido';
    }
  }

  // Función auxiliar para obtener el estado Activo/Inactivo
  String _getTextoEstado(bool activo) {
    return activo ? 'Activo' : 'Inactivo';
  }
  
  @override
  Widget build(BuildContext dialogContext) {
    // Definimos el color del estado
    final Color estadoColor = usuario.activo ? Colors.green.shade700 : Colors.red.shade700;
    final String tipoUsuarioTexto = _getTextoTipoUsuario(usuario.tipoUsuario!);

    return AlertDialog(
      title: Text(
        usuario.nombreCompleto!, 
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            // NOMBRE DE USUARIO
            ListTile(
              leading: const Icon(Icons.person_pin),
              title: const Text('Nombre de Usuario'),
              subtitle: Text(usuario.nombreUsuario),
              dense: true,
            ),
            // EMAIL
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(usuario.email!),
              dense: true,
            ),
            // TIPO DE USUARIO (ROL)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Rol'),
              subtitle: Text(
                tipoUsuarioTexto,
              ),
              dense: true,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text('Cerrar'),
          onPressed: () {
            Navigator.of(dialogContext).pop();
          },
        ),
      ],
    );
  }
}