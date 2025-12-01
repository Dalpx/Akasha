import 'package:akasha/core/app_routes.dart';
import 'package:flutter/material.dart';
import '../../core/session_manager.dart';
import '../../services/auth_service.dart';


/// Pantalla de login.
/// Permite ingresar usuario y contraseña, llama al AuthService y
/// si es exitoso, guarda el usuario en SessionManager.
class LoginPage extends StatefulWidget {
  final SessionManager sessionManager;

  const LoginPage({
    Key? key,
    required this.sessionManager,
  }) : super(key: key);

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

  /// Intenta iniciar sesión usando los datos del formulario.
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400.0,
          ),
          child: Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Akasha',
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _usuarioController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: _claveController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  const SizedBox(height: 20.0),
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
        ),
      ),
    );
  }
}
