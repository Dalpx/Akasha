import 'package:akasha/models/services/logout_service.dart';
import 'package:flutter/material.dart';

class DashboardController {
  final _service = LogoutService();

  Future<void> handleLogout(BuildContext context) async {
    try {
      //Llama al modelo para autenticar
      bool success = await _service.logout();

      //Procesa la respuesta del modelo
      if (success) {
        
        //Realiza la navegación a dashboard
        Navigator.of(
          context,
        ).pushReplacementNamed('/');
      } 
    } catch (e) {
      print(e.toString());
    }
  }
}
