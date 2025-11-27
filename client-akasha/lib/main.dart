import 'package:akasha/core/app_routes.dart';
import 'package:flutter/material.dart';

import 'core/session_manager.dart';
import 'views/auth/login_page.dart';
import 'views/shell/app_shell.dart';

void main() {
  // Punto de entrada de la aplicación
  WidgetsFlutterBinding.ensureInitialized();

  // Aquí podrías inicializar SharedPreferences, servicios, etc.
  runApp(const AkashaApp());
}

/// Widget raíz de la aplicación.
/// Se encarga de configurar el MaterialApp, rutas y tema.
class AkashaApp extends StatefulWidget {
  const AkashaApp({Key? key}) : super(key: key);

  @override
  State<AkashaApp> createState() {
    return _AkashaAppState();
  }
}

class _AkashaAppState extends State<AkashaApp> {
  // Gestor de sesión simple en memoria (puedes mejorarlo luego)
  final SessionManager _sessionManager = SessionManager();

  @override
  void initState() {
    super.initState();
    // Aquí podrías cargar sesión persistida (SharedPreferences, etc.)
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akasha - Inventario y Ventas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      // Ruta inicial depende de si hay usuario logueado o no
      home: _buildHome(),
      routes: AppRoutes.buildRoutes(_sessionManager),
    );
  }

  /// Retorna la vista inicial dependiendo del estado de la sesión.
  Widget _buildHome() {
    if (_sessionManager.estaAutenticado()) {
      // Si hay sesión, mostrar el shell principal con navegación lateral/bottom
      return AppShell(
        sessionManager: _sessionManager,
      );
    } else {
      // Si no hay sesión, mostrar pantalla de login
      return LoginPage(
        sessionManager: _sessionManager,
      );
    }
  }
}
