import 'package:akasha/controllers/dashboard_controller.dart';
import 'package:akasha/models/usuario.dart';
import 'package:akasha/utils/constant.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final DashboardController _controller = DashboardController();
    // Leemos los argumentos pasados durante la navegación.
    // Hacemos un "cast" (as String) porque sabemos que enviamos un String.
    final usuario = ModalRoute.of(context)!.settings.arguments as Usuario;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bienvenido", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text("Usuario: ${usuario.username}", style: TextStyle(fontSize: 20)),
            Text("Contraseña: ${usuario.password}", style: TextStyle(fontSize: 20)),
            Text("Rol: ${usuario.rol}", style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: UxColor.buttonBgColor,
                foregroundColor: UxColor.thirdTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: UxPadding.paddingDefault * 5,
                  vertical: 20,
                ),
                textStyle: TextStyle(fontSize: 20),
              ),
              onPressed: () {
                _controller.handleLogout(context);
              },
              child: Text("Cerrar Sesión"),
            ),
          ],
        ),
      ),
    );
  }
}
