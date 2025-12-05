import 'package:flutter/material.dart';

/// Clase helper para lógica responsive.
/// Define si estamos en modo "pantalla grande" o "pantalla pequeña".
class ResponsiveLayout {
  /// Determina si debe usarse layout tipo web (sidebar).
  static bool isDesktop(BuildContext context) {
    // También puedes usar kIsWeb para diferenciar plataforma
    double width = MediaQuery.of(context).size.width;
    return width >= 900.0;
  }

  /// Determina si debe usarse layout tipo mobile (bottom bar).
  static bool isMobile(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return width < 900.0;
  }
}
