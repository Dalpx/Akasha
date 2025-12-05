import '../models/usuario.dart';

/// Clase encargada de manejar el estado de la sesión de usuario.
/// En una app real, aquí se podría usar SharedPreferences, JWT, etc.
class SessionManager {
  Usuario? _usuarioActual;

  /// Establece el usuario actual cuando el login es exitoso.
  void iniciarSesion(Usuario usuario) {
    _usuarioActual = usuario;
  }

  /// Devuelve el usuario actual si existe sesión.
  Usuario? obtenerUsuarioActual() {
    return _usuarioActual;
  }

  /// Devuelve true si hay usuario autenticado.
  bool estaAutenticado() {
    return _usuarioActual != null;
  }

  /// Cierra la sesión borrando el usuario actual.
  void cerrarSesion() {
    _usuarioActual = null;
  }
}
