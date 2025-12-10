import 'package:akasha/widgets/transacciones/tabs/compras_tab.dart';
import 'package:akasha/widgets/transacciones/tabs/ventas_tab.dart';
import 'package:flutter/material.dart';
import 'package:akasha/core/session_manager.dart';

class ComprasVentasPage extends StatefulWidget {
  final SessionManager sessionManager;

  const ComprasVentasPage({super.key, required this.sessionManager});

  @override
  State<ComprasVentasPage> createState() => _ComprasVentasPageState();
}

class _ComprasVentasPageState extends State<ComprasVentasPage> {
  final GlobalKey<ComprasTabState> _comprasKey = GlobalKey<ComprasTabState>();
  final GlobalKey<VentasTabState> _ventasKey = GlobalKey<VentasTabState>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);

          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transacciones',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text("Gestión de transacciones"),

                  const TabBar(
                    tabs: [
                      Tab(text: 'Compras'),
                      Tab(text: 'Ventas'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _KeepAlivePage(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              child: ComprasTab(
                                key: _comprasKey,
                                sessionManager: widget.sessionManager,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            
                            child: _KeepAlivePage(
                              child: VentasTab(
                                key: _ventasKey,
                                sessionManager: widget.sessionManager,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
