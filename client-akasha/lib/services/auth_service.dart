

import 'package:akasha/models/usuario.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Necesitado para las excepciones de tipo SocketException

class AuthService {
  final String _baseUrl = 'http://localhost/akasha/server-akasha/src/login';

  Future<Usuario?> login(String username, String password) async {
    // 1. Poner las credenciales en un JSON
    final String jsonBody = jsonEncode({
      'user': username,
      'clave_hash': password,
    });

    try {
      // 2. Hacer la POST request
      final http.Response response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json', // Especifica el tipo de contenido
        },
        body: jsonBody,
      );

      // 3. Procesar la respuesta
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonAuth = jsonDecode(response.body);
        
        String? tipoUsuario = jsonAuth["permisos"]?["nombre_tipo_usuario"];

        bool? activoUsuario = false;

        if (jsonAuth['permisos']?['activo'] == 1) {
          print(jsonAuth['permisos']?['activo']);
          activoUsuario = true;
        }

        
        // Login exitoso
        return Usuario(nombreUsuario: username, claveHash: password, tipoUsuario: tipoUsuario, activo: activoUsuario);
      } else if (response.statusCode == 401) {
        // No autorizado, credenciales invalidas
        print('Credenciales inválidas.');
        return null;
      } else {
        // Errores miscelaneos
        print('Server error: ${response.statusCode}');
        return null;
      }
    } on SocketException {
      // Por si no hay internet
      print('Error de red, asegúrate de tener conexión');
      return null;
    } catch (e) {
      // Manejo de error genérico
      print('An unexpected error occurred: $e');
      return null;
    }
  }
}