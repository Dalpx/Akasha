import 'package:akasha/core/session_manager.dart';
import 'package:akasha/services/inventario_service.dart';
import 'package:akasha/widgets/transacciones/tabs/compras_tab.dart';
import 'package:akasha/widgets/transacciones/tabs/ventas_tab.dart';
import 'package:flutter/material.dart';

class ComprasVentasPage extends StatefulWidget {
  final SessionManager sessionManager;

  const ComprasVentasPage({super.key, required this.sessionManager});

  @override
  State<ComprasVentasPage> createState() => _ComprasVentasPageState();
}

class _ComprasVentasPageState extends State<ComprasVentasPage> {
  final GlobalKey<ComprasTabState> _comprasKey = GlobalKey<ComprasTabState>();
  final GlobalKey<VentasTabState> _ventasKey = GlobalKey<VentasTabState>();

  Future<void> _notificarCambioInventario() async {

    try {
      InventarioService.productosRevision.value++;
    } catch (_) {

    }
  }

  Future<void> _postCompra() async {
    // Tras compra, refrescamos el tab opuesto para que tome nuevos
    // productos/stock/proveedores/tipos/ubicaciones si aplica
    await _ventasKey.currentState?.refreshFromExternalChange();
    await _notificarCambioInventario();
  }

  Future<void> _postVenta() async {
    await _comprasKey.currentState?.refreshFromExternalChange();
    await _notificarCambioInventario();
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
                  onPressed: () async {
                    if (isCompras) {
                      await _comprasKey.currentState?.onFabPressed();
                      if (!mounted) return;
                      await _postCompra();
                    } else {
                      await _ventasKey.currentState?.onFabPressed();
                      if (!mounted) return;
                      await _postVenta();
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
