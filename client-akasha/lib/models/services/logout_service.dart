// Esta clase representa tu capa de Modelo (lógica de negocio).
// En una app real, aquí harías la llamada HTTP a tu backend.

class LogoutService {
  Future<bool> logout() async {
    // 1. Simula un retraso de red
    await Future.delayed(Duration(seconds: 2));

    // 2. Lógica de autenticación de ejemplo
    return true;
  }
}