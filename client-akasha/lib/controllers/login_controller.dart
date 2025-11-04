import 'package:akasha/models/services/login_service.dart';
import 'package:akasha/models/usuario.dart';
import 'package:flutter/material.dart';

class LoginController {
  final LoginService _service = LoginService(); //Instancia del modelo

  // Esta funcion se ejecuta cuando presionan el boton en
  // la vista
  Future<void> handleLogin(
    BuildContext context,
    String username,
    String password,
    Function(bool, String) onLoginResult,
  ) async {
    // Válida que los campos no esten vacíos
    if (username.isEmpty || password.isEmpty) {
      onLoginResult(false, "Los campos deben estar llenos");
      return;
    }

    try {
      //Llama al modelo para autenticar
      bool success = await _service.login(username, password);

      //Procesa la respuesta del modelo
      if (success) {
        //Notifica a la vista el exito
        onLoginResult(true, "¡Login exitoso!");

        //Creamos la instancia de usuario
        final usuarioIngreso = Usuario(username: username, password: password, rol: "Admin");

        //Realiza la navegación a dashboard
        Navigator.of(
          context,
        ).pushReplacementNamed('/dashboard', arguments: usuarioIngreso);
      } else {
        onLoginResult(false, "Alguno de los campos esta incorrecto");
      }
    } catch (e) {
      onLoginResult(false, "Error al conectar: ${e.toString()}");
    }
  }
}
