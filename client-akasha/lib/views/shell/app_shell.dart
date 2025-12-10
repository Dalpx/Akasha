import 'package:akasha/core/constants.dart';
import 'package:akasha/core/responsive_layout.dart';
import 'package:akasha/core/session_manager.dart';
import 'package:akasha/services/compra_service.dart';
import 'package:akasha/services/venta_service.dart';
import 'package:akasha/views/auth/login_page.dart';
import 'package:akasha/views/clientes/clientes_page.dart';
import 'package:akasha/views/compras/compras_page.dart';
import 'package:akasha/views/inventario/movimientos_inventario_page.dart';
import 'package:akasha/views/inventario/productos_page.dart';
import 'package:akasha/views/reportes/reportes_page.dart';
import 'package:akasha/views/seguridad/usuarios_page.dart';
import 'package:akasha/views/ventas/ventas_page.dart';
import 'package:flutter/material.dart';

/// Clase auxiliar para manejar las opciones de navegación
class _NavOption {
  final int index; // Índice original que corresponde a la página en _buildPage
  final IconData icon;
  final String label;
  // Lista de idTipoUsuario permitidos (null significa permitido para todos)
  final List<String>? requiredRoles;

  _NavOption({
    required this.index,
    required this.icon,
    required this.label,
    this.requiredRoles,
  });

  // Constructor para convertir a BottomNavigationBarItem
  BottomNavigationBarItem toBottomNavigationBarItem() {
    return BottomNavigationBarItem(icon: Icon(icon), label: label);
  }
}

/// Widget que actúa como "layout principal" de la aplicación.
class AppShell extends StatefulWidget {
  final SessionManager sessionManager;

  const AppShell({super.key, required this.sessionManager});

  @override
  State<AppShell> createState() {
    return _AppShellState();
  }
}

class _AppShellState extends State<AppShell> {
  // El índice seleccionado es el índice original de la página (0 a 5)
  int _indiceSeleccionado = 0;

  // Lista base de todas las opciones de navegación con sus permisos
  final List<_NavOption> _opcionesBase = [
    // Inventario: Superusuario (0) y Admin (1)
    _NavOption(
      index: 0,
      icon: Icons.inventory_2,
      label: 'Inventario',
      requiredRoles: ["super", "administrador"],
    ),
    _NavOption(
      index: 1,
      icon: Icons.shopping_cart,
      label: 'Ventas',
      requiredRoles: null,
    ),
    _NavOption(
      index: 2,
      icon: Icons.shopping_bag,
      label: 'Compras',
      requiredRoles: null,
    ),
    // Movimientos y Reportes: Superusuario (0) y Admin (1)
    _NavOption(
      index: 3,
      icon: Icons.adjust,
      label: 'Movimientos',
      requiredRoles: ["super", "administrador", "almacen"],
    ),
    // Usuarios: Superusuario (0)
    _NavOption(
      index: 4,
      icon: Icons.person,
      label: 'Usuarios',
      requiredRoles: ["super"],
    ),
    // Reportes: Superusuario (0) y Admin (1)
    _NavOption(
      index: 5,
      icon: Icons.bar_chart,
      label: 'Reportes',
      requiredRoles: ["super", "administrador"],
    ),
    // Cliente: Superusuario (0) y Admin (1)
    _NavOption(
      index: 6,
      icon: Icons.person_2,
      label: 'Clientes',
      requiredRoles: ["super", "administrador"],
    ),
  ];

  /// Retorna la página correspondiente al índice seleccionado.
  Widget _buildPage() {
    // Si el índice seleccionado corresponde a una página sin permiso,
    // redirige a la página por defecto (Inventario, índice 0).
    final String? tipoUsuario = widget.sessionManager
        .obtenerUsuarioActual()
        ?.tipoUsuario;
    final _NavOption opcionActual = _opcionesBase.firstWhere(
      (option) => option.index == _indiceSeleccionado,
      orElse: () => _opcionesBase.first, // Fallback al primero
    );

    if (opcionActual.requiredRoles != null &&
        !opcionActual.requiredRoles!.contains(tipoUsuario)) {
      // Si no tiene permiso, volvemos a Inventario (index 0)
      _indiceSeleccionado = 0;
    }

    // Retornamos el widget correspondiente al índice (ahora garantizado que tiene permiso o es 0)
    switch (_indiceSeleccionado) {
      case 0:
        return ProductosPage();
      case 1:
        return VentasPage(sessionManager: widget.sessionManager);
      case 2:
        return ComprasPage(sessionManager: widget.sessionManager);
      case 3:
        return MovimientoInventarioPage(sessionManager: widget.sessionManager);
      case 4:
        return UsuariosPage();
      case 5:
        return ReportesPage(
          ventaService: VentaService(),
          compraService: CompraService(),
        );
      case 6:
        return ClientesPage();
      default:
        return UsuariosPage(); // Fallback
    }
  }

  /// Cambia el índice de navegación seleccionada (usa el índice original de 0 a 5).
  void _onItemTapped(int index) {
    setState(() {
      _indiceSeleccionado = index;
    });
  }

  /// Cierra la sesión y navega a la pantalla de login.
  void _cerrarSesion(BuildContext context) {
    widget.sessionManager.cerrarSesion();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<LoginPage>(
        builder: (BuildContext context) {
          return LoginPage(sessionManager: widget.sessionManager);
        },
      ),
      (Route<dynamic> route) {
        return false;
      },
    );
  }

  /// Filtra las opciones de navegación según el tipo de usuario.
  List<_NavOption> _getOpcionesPermitidas() {
    final String? tipoUsuario = widget.sessionManager
        .obtenerUsuarioActual()
        ?.tipoUsuario;

    // Si no hay usuario logueado (aunque no debería pasar aquí), no mostramos nada extra.
    if (tipoUsuario == null) {
      return _opcionesBase
          .where((option) => option.requiredRoles == null)
          .toList();
    }

    return _opcionesBase.where((option) {
      // Si no requiere roles específicos, es visible.
      if (option.requiredRoles == null) {
        return true;
      }
      // Si requiere roles, es visible solo si el usuario actual está en la lista.
      return option.requiredRoles!.contains(tipoUsuario);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool esDesktop = ResponsiveLayout.isDesktop(context);
    final List<_NavOption> opcionesPermitidas = _getOpcionesPermitidas();

    // Si el índice seleccionado actual no existe en la lista de permitidas,
    // lo reseteamos al primer elemento permitido.
    if (!opcionesPermitidas.any(
      (option) => option.index == _indiceSeleccionado,
    )) {
      _indiceSeleccionado = opcionesPermitidas.first.index;
    }

    if (esDesktop) {
      // Layout para pantallas grandes (web)
      return Scaffold(
        body: Row(
          children: <Widget>[
            // Side bar
            Container(
              width: 250.0,
              color: Constants().sidebar,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 40.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/akasha_logo.png",
                        width: 64,
                        height: 64,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "AKASHA",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // Generación dinámica de items del SideBar
                  ...opcionesPermitidas.map((option) {
                    return _buildSideBarItem(
                      index: option.index,
                      icon: option.icon,
                      label: option.label,
                    );
                  }),

                  const Spacer(),
                  ElevatedButton.icon(
                    
                    onPressed: () {
                      _cerrarSesion(context);
                    },
                    icon: Icon(Icons.logout),
                    label: Text("Cerrar Sesión"),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
            // Contenido principal
            Expanded(child: _buildPage()),
          ],
        ),
      );
    } else {
      // Encontramos el índice *visible* que corresponde al índice original seleccionado.
      final int indiceVisible = opcionesPermitidas.indexWhere(
        (option) => option.index == _indiceSeleccionado,
      );

      return Scaffold(
        appBar: AppBar(
          title: const Text('Akasha'),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                _cerrarSesion(context);
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: _buildPage(),
        bottomNavigationBar: BottomNavigationBar(
          // Usamos el índice de la lista filtrada (indiceVisible)
          currentIndex: indiceVisible,

          // Al tocar un item, usamos el índice de la lista filtrada (index) para
          // obtener el índice *original* y pasarlo a _onItemTapped
          onTap: (index) {
            final int indiceOriginal = opcionesPermitidas[index].index;
            _onItemTapped(indiceOriginal);
          },
          items: opcionesPermitidas
              .map((option) => option.toBottomNavigationBarItem())
              .toList(),

          // Aseguramos que se vean más de 3 items si es necesario
          type: BottomNavigationBarType.fixed,
        ),
      );
    }
  }

  /// Construye un item del sidebar para el layout web.
  Widget _buildSideBarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    bool seleccionado = _indiceSeleccionado == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        color: seleccionado ? Constants().primary : Colors.transparent,
        child: ListTile(
          leading: Icon(
            icon,
            color: seleccionado
                ? Constants().sidebar
                : Constants().sidebarForeground,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: seleccionado
                  ? Constants().sidebar
                  : Constants().sidebarForeground,
              fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () {
            _onItemTapped(index);
          },
        ),
      ),
    );
  }
}
