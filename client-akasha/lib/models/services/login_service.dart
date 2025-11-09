// Esta clase representa tu capa de Modelo (lógica de negocio).
// En una app real, aquí harías la llamada HTTP a tu backend.

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Necesitado para las excepciones de tipo SocketException

class LoginService {
  final String _baseUrl = 'http://localhost/akasha/server-akasha/src/controllers/loginController.php';

  Future<bool> login(String username, String password) async {
    // 1. Poner las credenciales en un JSON
    final String jsonBody = jsonEncode({
      'user': username,
      'pass': password,
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
        // Login exitoso
        return true;
      } else if (response.statusCode == 401) {
        // No autorizado, credenciales invalidas
        print('Credenciales inválidas.');
        return false;
      } else {
        // Errores miscelaneos
        print('Server error: ${response.statusCode}');
        return false;
      }
    } on SocketException {
      // Por si no hay internet
      print('Error de red, asegúrate de tener conexión');
      return false;
    } catch (e) {
      // Manejo de error genérico
      print('An unexpected error occurred: $e');
      return false;
    }
  }
}

//old code

/* class LoginService {
  Future<bool> login(String username, String password) async {
    // 1. Simula un retraso de red
    await Future.delayed(Duration(seconds: 2));

    // 2. Lógica de autenticación de ejemplo
    if (username == 'Lagos' && password == 'Crotolamo') {
      return true; // Éxito
    } else {
      return false; // Falla
    }
  }
} */