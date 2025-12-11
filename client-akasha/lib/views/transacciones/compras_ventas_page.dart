import 'package:akasha/core/session_manager.dart';
import 'package:akasha/widgets/transacciones/tabs/compras_tab.dart';
import 'package:akasha/widgets/transacciones/tabs/ventas_tab.dart';
import 'package:flutter/material.dart';

class ComprasVentasPage extends StatefulWidget {
  final SessionManager sessionManager;

  const ComprasVentasPage({super.key, required this.sessionManager});

  @override
  State<ComprasVentasPage> createState() => ComprasVentasPageState();
}

class ComprasVentasPageState extends State<ComprasVentasPage> {
  final GlobalKey<ComprasTabState> _comprasKey = GlobalKey<ComprasTabState>();
  final GlobalKey<VentasTabState> _ventasKey = GlobalKey<VentasTabState>();

  Future<void> refreshFromExternalChange() async {
    await Future.wait([
      _comprasKey.currentState?.refreshFromExternalChange() ?? Future.value(),
      _ventasKey.currentState?.refreshFromExternalChange() ?? Future.value(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);

          return Scaffold(
            appBar: AppBar(
              title: const Text('Compras y Ventas'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Compras'),
                  Tab(text: 'Ventas'),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Refrescar catálogos',
                  onPressed: () => refreshFromExternalChange(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            body: TabBarView(
              children: [
                ComprasTab(
                  key: _comprasKey,
                  sessionManager: widget.sessionManager,
                ),
                VentasTab(
                  key: _ventasKey,
                  sessionManager: widget.sessionManager,
                ),
              ],
            ),
            floatingActionButton: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final isCompras = controller.index == 0;

                return FloatingActionButton(
                  onPressed: () {
                    if (isCompras) {
                      _comprasKey.currentState?.onFabPressed();
                    } else {
                      _ventasKey.currentState?.onFabPressed();
                    }
                  },
                  tooltip: isCompras ? 'Registrar compra' : 'Registrar venta',
                  child: Icon(
                    isCompras ? Icons.shopping_cart_checkout : Icons.add,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
