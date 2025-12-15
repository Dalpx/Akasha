import 'package:akasha/common/custom_card.dart';
import 'package:akasha/core/app_routes.dart';
import 'package:akasha/core/constants.dart';
import 'package:flutter/material.dart';
import '../../core/session_manager.dart';
import '../../services/auth_service.dart';

// (Clases LoginPage, _LoginPageState y _iniciarSesion se mantienen igual)
class LoginPage extends StatefulWidget {
  final SessionManager sessionManager;

  const LoginPage({super.key, required this.sessionManager});

  @override
  State<LoginPage> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _claveController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _cargando = false;
  String? _error;

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    String usuario = _usuarioController.text.trim();
    String clave = _claveController.text.trim();

    final resultado = await _authService.login(usuario, clave);

    if (resultado != null) {
      widget.sessionManager.iniciarSesion(resultado);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.rutaShell);
    } else {
      setState(() {
        _error = 'Usuario o contraseña incorrectos';
      });
    }

    setState(() {
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants().card,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    "assets/images/akasha_logo.png",
                    width: 100,
                    height: 100,
                  ),
                  SizedBox(height: 18),
                  Text(
                    "Inicia Sesión",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 18),
                  Text(
                    "Ingresa los datos de tu cuenta para\n poder acceder",
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400.0),
                    child: CustomCard(
                      color: Constants().background,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Usuario",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _usuarioController,
                            decoration: const InputDecoration(
                              hintText: "Ingresa tu usuario",
                            ),
                          ),
                          SizedBox(height: 12),
                          Text("Contraseña"),
                          SizedBox(height: 8),
                          TextField(
                            controller: _claveController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: "Ingresa tu contraseña",
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          if (_error != null)
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          const SizedBox(height: 24.0),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _cargando ? null : _iniciarSesion,
                              child: _cargando
                                  ? const SizedBox(
                                      width: 20.0,
                                      height: 20.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : const Text('Ingresar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Text(
                "Desarrolado en el IUJO Extensión Barquisimeto en 2025",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
