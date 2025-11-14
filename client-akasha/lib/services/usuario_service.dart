// lib/services/usuario_service.dart

import 'dart:convert';
import 'dart:developer';

import 'package:akasha/models/usuario.dart';
import 'package:http/http.dart' as http;

class UsuarioService {
  final String _baseUrl = 'http://localhost/akasha/server-akasha/src/usuario';

  // Obtener todos los usuarios
  Future<List<Usuario>> fetchApiData() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is List) {
          return body
              .map((e) => Usuario.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (body is Map<String, dynamic>) {
          // Por si el backend devuelve un solo registro
          return [Usuario.fromJson(body)];
        } else {
          log('Formato inesperado al obtener usuarios');
          return [];
        }
      } else if (response.statusCode == 404) {
        // El backend lanza 404 cuando no hay registros
        log('No hay usuarios registrados');
        return [];
      } else {
        log('Error al cargar usuarios: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      log('Excepción en fetchApiData (usuarios): $e');
      return [];
    }
  }

  // Obtener usuario por ID
  Future<Usuario?> obtenerUsuarioPorID(int id) async {
    final url = Uri.parse('$_baseUrl/$id');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is Map<String, dynamic>) {
          return Usuario.fromJson(body);
        } else {
          log('Formato inesperado al obtener usuario por ID');
          return null;
        }
      } else if (response.statusCode == 404) {
        log('Usuario no encontrado (404)');
        return null;
      } else {
        log('Error al obtener usuario por ID: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      log('Excepción en obtenerUsuarioPorID: $e');
      return null;
    }
  }

  // Crear usuario
  Future<bool> createUsuario(Usuario usuario) async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson(0)),
      );

      if (response.statusCode == 201) {
        log('Usuario creado con éxito');
        return true;
      } else {
        log(
          'Fallo al crear usuario. Código: ${response.statusCode}. Respuesta: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      log('Excepción en createUsuario: $e');
      return false;
    }
  }

  // Actualizar usuario
  Future<bool> updateUsuario(Usuario usuario) async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson(1)),
      );

      if (response.statusCode == 200) {
        log('Usuario actualizado con éxito');
        return true;
      } else {
        log(
          'Fallo al actualizar usuario. Código: ${response.statusCode}. Respuesta: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      log('Excepción en updateUsuario: $e');
      return false;
    }
  }

  // Eliminar (baja lógica) usuario
  Future<bool> deleteUsuario(Usuario usuario) async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(usuario.toJson(2)),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        log('Usuario eliminado con éxito');
        return true;
      } else {
        log(
          'Fallo al eliminar usuario. Código: ${response.statusCode}. Respuesta: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      log('Excepción en deleteUsuario: $e');
      return false;
    }
  }
}
