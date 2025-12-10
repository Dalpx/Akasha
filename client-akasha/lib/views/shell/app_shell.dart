import 'package:akasha/core/constants.dart';
import 'package:akasha/core/responsive_layout.dart';
import 'package:akasha/core/session_manager.dart';
import 'package:akasha/services/compra_service.dart';
import 'package:akasha/services/venta_service.dart';
import 'package:akasha/views/auth/login_page.dart';
import 'package:akasha/views/clientes/clientes_page.dart';
import 'package:akasha/views/inventario/movimientos_inventario_page.dart';
import 'package:akasha/views/inventario/productos_page.dart';
import 'package:akasha/views/reportes/reportes_page.dart';
import 'package:akasha/views/seguridad/usuarios_page.dart';
import 'package:akasha/views/transacciones/compras_ventas_page.dart';
import 'package:akasha/widgets/app-shell/appShell_loading_view.dart';
import 'package:flutter/material.dart';



class _NavOption {
  final int index;
  final IconData icon;
  final String label;
  final List<String>? requiredRoles;

  _NavOption({
    required this.index,
    required this.icon,
    required this.label,
    this.requiredRoles,
  });

  BottomNavigationBarItem toBottomNavigationBarItem() {
    return BottomNavigationBarItem(icon: Icon(icon), label: label);
  }
}

class AppShell extends StatefulWidget {
  final SessionManager sessionManager;

  const AppShell({super.key, required this.sessionManager});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indiceSeleccionado = 0;

  final List<_NavOption> _opcionesBase = [
    _NavOption(
      index: 0,
      icon: Icons.inventory_2,
      label: 'Inventario',
      requiredRoles: ["super", "administrador"],
    ),
    _NavOption(
      index: 1,
      icon: Icons.payment,
      label: 'Transacciones',
      requiredRoles: null,
    ),
    _NavOption(
      index: 2,
      icon: Icons.import_export,
      label: 'Movimientos',
      requiredRoles: null,
    ),
    _NavOption(
      index: 3,
      icon: Icons.manage_accounts,
      label: 'Usuarios',
      requiredRoles: ["super", "administrador", "almacen"],
    ),
    _NavOption(
      index: 4,
      icon: Icons.bar_chart,
      label: 'Reportes',
      requiredRoles: ["super"],
    ),
    _NavOption(
      index: 5,
      icon: Icons.handshake,
      label: 'Clientes',
      requiredRoles: ["super", "administrador"],
    ),
  ];

  late final VentaService _ventaService;
  late final CompraService _compraService;

  late final List<Widget> _pages;

  late final Future<void> _bootFuture;

  @override
  void initState() {
    super.initState();

    _bootFuture = _boot();
  }

  Future<void> _boot() async {
    _ventaService = VentaService();
    _compraService = CompraService();

    _pages = [
      const ProductosPage(),
      ComprasVentasPage(sessionManager: widget.sessionManager),
      MovimientoInventarioPage(sessionManager: widget.sessionManager),
      const UsuariosPage(),
      ReportesPage(
        ventaService: _ventaService,
        compraService: _compraService,
      ),
      const ClientesPage(),
    ];

    await Future.wait([
      Future.delayed(const Duration(milliseconds: 700)),
      WidgetsBinding.instance.endOfFrame,
    ]);

  }

  void _onItemTapped(int index) {
    if (_indiceSeleccionado == index) return;
    setState(() {
      _indiceSeleccionado = index;
    });
  }

  void _cerrarSesion(BuildContext context) {
    widget.sessionManager.cerrarSesion();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<LoginPage>(
        builder: (BuildContext context) {
          return LoginPage(sessionManager: widget.sessionManager);
        },
      ),
      (Route<dynamic> route) => false,
    );
  }

  List<_NavOption> _getOpcionesPermitidas() {
    final String? tipoUsuario =
        widget.sessionManager.obtenerUsuarioActual()?.tipoUsuario;

    if (tipoUsuario == null) {
      return _opcionesBase
          .where((option) => option.requiredRoles == null)
          .toList();
    }

    return _opcionesBase.where((option) {
      if (option.requiredRoles == null) return true;
      return option.requiredRoles!.contains(tipoUsuario);
    }).toList();
  }

  int _indiceSeguro(List<_NavOption> opcionesPermitidas) {
    if (opcionesPermitidas.any((o) => o.index == _indiceSeleccionado)) {
      return _indiceSeleccionado;
    }
    return opcionesPermitidas.first.index;
  }

  Widget _buildBodyConCache(int safeIndex) {
    return IndexedStack(
      index: safeIndex,
      children: _pages,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootFuture,
      builder: (context, snapshot) {
        final bool listo = snapshot.connectionState == ConnectionState.done;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !listo
              ? const AppShellLoadingView()
              : _buildShell(context),
        );
      },
    );
  }

  Widget _buildShell(BuildContext context) {
    final bool esDesktop = ResponsiveLayout.isDesktop(context);
    final List<_NavOption> opcionesPermitidas = _getOpcionesPermitidas();
    final int safeIndex = _indiceSeguro(opcionesPermitidas);

    if (safeIndex != _indiceSeleccionado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _indiceSeleccionado = safeIndex;
        });
      });
    }

    if (esDesktop) {
      return Scaffold(
        body: Row(
          children: <Widget>[
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
                      const SizedBox(width: 12),
                      const Text(
                        "AKASHA",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...opcionesPermitidas.map((option) {
                            return _buildSideBarItem(
                              index: option.index,
                              icon: option.icon,
                              label: option.label,
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _cerrarSesion(context),
                    icon: const Icon(Icons.logout),
                    label: const Text("Cerrar Sesión"),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
            Expanded(child: _buildBodyConCache(safeIndex)),
          ],
        ),
      );
    } else {
      final int indiceVisible = opcionesPermitidas.indexWhere(
        (option) => option.index == safeIndex,
      );

      return Scaffold(
        appBar: AppBar(
          title: const Text('Akasha'),
          actions: <Widget>[
            IconButton(
              onPressed: () => _cerrarSesion(context),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: _buildBodyConCache(safeIndex),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: indiceVisible < 0 ? 0 : indiceVisible,
          onTap: (index) {
            final int indiceOriginal = opcionesPermitidas[index].index;
            _onItemTapped(indiceOriginal);
          },
          items: opcionesPermitidas
              .map((option) => option.toBottomNavigationBarItem())
              .toList(),
          type: BottomNavigationBarType.fixed,
        ),
      );
    }
  }

  Widget _buildSideBarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool seleccionado = _indiceSeleccionado == index;

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
          onTap: () => _onItemTapped(index),
        ),
      ),
    );
  }
}
