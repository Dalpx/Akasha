import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/usuario.dart';

/// Servicio simple en memoria para gestionar usuarios.
/// Similar al InventarioService, pero trabajando con el modelo `Usuario`.
class UsuarioService {


  final List<Usuario> _usuariosEnMemoria = <Usuario>[];

    final String _baseUrl =
      "http://localhost/akasha/server-akasha/src/usuario";

  Future<List<Usuario>> obtenerUsuarios({bool soloActivos = true}) async {
    final url = Uri.parse(_baseUrl);
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonUsuario = jsonDecode(response.body);

        //Convertimos a lista de usuarios
        final List<Usuario> usuarios = jsonUsuario
            .map(
              (usuario) => Usuario.fromJson(usuario as Map<String, dynamic>),
            )
            .toList();
        
        return usuarios;
      } else {
        log("Fallo el codigo: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("El error fue al ObtenerUsuarios: ${e}");
      return [];
    }
  }

  /// Crea un nuevo usuario y lo agrega a la lista.
  Future<void> crearUsuario(Usuario usuario) async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          usuario.toJson(),
        ), // Usamos toJson() del modelo usuario
      );

      if (response.statusCode == 201) {
        // 201 Created es la respuesta estándar para una creación exitosa
        log("Usuario creado con éxito. ID: ${response.body}");
      } else {
        log(
          "Fallo al crear usuario. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar crear usuario: $e");
    }
  }

  /// Actualiza un usuario existente.
  Future<void> actualizarUsuario(Usuario usuario) async {
    final url = Uri.parse(
      '$_baseUrl/${usuario.idUsuario}',
    ); // Asegúrate de que usuario tenga un 'id'

    try {
      final response = await http.put(
        // Se usa PUT para reemplazar completamente el recurso
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson()),
      );

      if (response.statusCode == 200) {
        log("usuario actualizado con éxito.");
      } else {
        log(
          "Fallo al actualizar usuario. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar actualizar usuario: $e");
    }
  }

  /// Eliminación lógica: marca al usuario como inactivo.
  Future<void> eliminarUsuario(int idUsuario) async {
    final url = Uri.parse("${_baseUrl}/${idUsuario}");
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'id_usuario': idUsuario}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content es común para un DELETE exitoso
        log("Usuario con ID ${idUsuario} eliminado con éxito.");
      } else {
        log(
          "Fallo al eliminar usuario. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar eliminar usuario: $e");
    }
  }

  /// Búsqueda rápida por id.
  Usuario? buscarPorId(int idUsuario) {
    for (final Usuario usuario in _usuariosEnMemoria) {
      if (usuario.idUsuario == idUsuario) {
        return usuario;
      }
    }
    return null;
  }
}
