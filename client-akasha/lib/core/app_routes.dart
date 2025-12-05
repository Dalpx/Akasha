import 'package:akasha/services/compra_service.dart';
import 'package:akasha/services/venta_service.dart';
import 'package:akasha/views/auth/login_page.dart';
import 'package:akasha/views/clientes/clientes_page.dart';
import 'package:akasha/views/compras/compras_page.dart';
import 'package:akasha/views/configuracion/gestion_proveedores_categorias_ubicaciones_page.dart';
import 'package:akasha/views/configuracion/gestion_ubicaciones_page.dart';
import 'package:akasha/views/inventario/movimientos_inventario_page.dart';
import 'package:akasha/views/inventario/productos_page.dart';
import 'package:akasha/views/reportes/reportes_page.dart';
import 'package:akasha/views/seguridad/usuarios_page.dart';
import 'package:akasha/views/shell/app_shell.dart';
import 'package:akasha/views/ventas/ventas_page.dart';
import 'package:flutter/material.dart';

import 'session_manager.dart';

/// Clase encargada de construir el mapa de rutas de la aplicación.
class AppRoutes {
  static const String rutaLogin = '/login';
  static const String rutaShell = '/appshell';
  static const String rutaInventario = '/inventario';
  static const String rutaVentas = '/ventas';
  static const String rutaCompras = '/compras';
  static const String rutaReportes = '/reportes';
  static const String rutaGestionMaestros = '/gestion-maestros';
  static const String rutaGestionUbicaciones = '/gestion-ubicaciones';
  static const String rutaMovimientosInventario = '/movimientos-inventario';
  static const String rutaGestionUsuarios = '/usuarios';
  static const String rutaGestionCliente = '/clientes';

  /// Construye el mapa de rutas que usará MaterialApp.
  static Map<String, WidgetBuilder> buildRoutes(SessionManager sessionManager) {
    return <String, WidgetBuilder>{
      rutaLogin: (BuildContext context) {
        return LoginPage(sessionManager: sessionManager);
      },
      rutaShell: (BuildContext context) {
        return AppShell(sessionManager: sessionManager);
      },
      rutaInventario: (BuildContext context) {
        return ProductosPage();
      },
      rutaVentas: (BuildContext context) {
        return VentasPage(sessionManager: sessionManager,);
      },
      rutaCompras: (BuildContext context) {
        return ComprasPage(sessionManager: sessionManager,);
      },
      rutaReportes: (BuildContext context) {
        return ReportesPage(ventaService: VentaService(), compraService: CompraService(),);
      },
      rutaGestionMaestros: (BuildContext context) {
        return GestionProveedoresCategoriasPage();
      },
      rutaGestionUbicaciones: (BuildContext context) {
        return GestionUbicacionesPage();
      },
      rutaMovimientosInventario: (BuildContext context) {
        return MovimientoInventarioPage(sessionManager: sessionManager,);
      },
      rutaGestionUsuarios: (BuildContext context) {
        return UsuariosPage();
      },
      rutaGestionCliente: (BuildContext context) {
        return ClientesPage();
      },
    };
  }
}
