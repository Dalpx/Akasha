import 'dart:math';

import 'package:akasha/core/constants.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:flutter/material.dart';

/// Helpers compartidos (snackbar, parseInt, height historial, nro comprobante)
mixin OperacionTabMixin<T extends StatefulWidget> on State<T> {
  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger ??= ScaffoldMessenger.maybeOf(context);
  }

  void showMessage(String msg) {
    if (!mounted) return;
    final messenger = _messenger ?? ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(msg)));
  }

  int parseIntSafe(String value) {
    if (value.trim().isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  double historialHeight() {
    final screenH = MediaQuery.of(context).size.height;
    return min(420, max(220, screenH * 0.32));
  }

  String generarNroComprobante(String prefix) {
    final ahora = DateTime.now();
    final random = Random();
    final parte1 = (ahora.millisecondsSinceEpoch ~/ 1000) % 10000;
    final parte2 = random.nextInt(100000);
    final s1 = parte1.toString().padLeft(4, '0');
    final s2 = parte2.toString().padLeft(5, '0');
    return '$prefix-$s1-$s2';
  }
}

/// Layout responsive (2 columnas >=1100) SIN tocar la UI original
class OperacionResponsiveLayout extends StatelessWidget {
  final Widget factura;
  final Widget historial;
  final String storageKey;

  const OperacionResponsiveLayout({
    super.key,
    required this.factura,
    required this.historial,
    required this.storageKey,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool twoColumns = w >= 1100;

    if (twoColumns) {
      return SingleChildScrollView(
        key: PageStorageKey(storageKey),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: factura),
            const SizedBox(width: 16),
            Expanded(child: historial),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      key: PageStorageKey(storageKey),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          factura,
          const SizedBox(height: 16),
          historial,
        ],
      ),
    );
  }
}

/// Sección con título + Card (mismos estilos que estabas usando)
class OperacionSeccion extends StatelessWidget {
  final String titulo;
  final Widget child;
  final EdgeInsetsGeometry cardPadding;

  const OperacionSeccion({
    super.key,
    required this.titulo,
    required this.child,
    this.cardPadding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Card(
          color: Constants().background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Constants().border),
          ),
          child: Padding(
            padding: cardPadding,
            child: child,
          ),
        ),
      ],
    );
  }
}

enum StockCardStyle { blueInfo, greenRed }

/// Card de stock (misma UI, solo parametrizada)
class StockInfoCard extends StatelessWidget {
  final String label;
  final int stock;
  final StockCardStyle style;

  const StockInfoCard({
    super.key,
    required this.label,
    required this.stock,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color border;
    late final Color valueColor;

    if (style == StockCardStyle.blueInfo) {
      bg = Colors.blue.shade50;
      border = Colors.blue.shade300;
      valueColor = Colors.blue.shade700;
    } else {
      final ok = stock > 0;
      bg = ok ? Colors.green.shade50 : Colors.red.shade50;
      border = ok ? Colors.green.shade300 : Colors.red.shade300;
      valueColor = ok ? Colors.green.shade700 : Colors.red.shade700;
    }

    return Card(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '$stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card reutilizable para una línea de producto (Compra/Venta)
class LineaProductoCard extends StatelessWidget {
  final List<Producto> productos;
  final Producto? productoSeleccionado;
  final Future<void> Function(Producto? nuevo) onProductoChanged;

  final bool canDelete;
  final VoidCallback? onDelete;

  final TextEditingController cantidadCtrl;
  final String? Function(String? value) cantidadValidator;

  final TextEditingController precioCtrl;
  final String labelPrecio;

  final List<Ubicacion> ubicacionesDisponibles;
  final Ubicacion? ubicacionSeleccionada;
  final ValueChanged<Ubicacion?> onUbicacionChanged;
  final String? Function(Ubicacion? value) ubicacionValidator;

  final int stockDisponible;
  final bool mostrarStock;
  final StockCardStyle stockStyle;

  const LineaProductoCard({
    super.key,
    required this.productos,
    required this.productoSeleccionado,
    required this.onProductoChanged,
    required this.canDelete,
    required this.onDelete,
    required this.cantidadCtrl,
    required this.cantidadValidator,
    required this.precioCtrl,
    required this.labelPrecio,
    required this.ubicacionesDisponibles,
    required this.ubicacionSeleccionada,
    required this.onUbicacionChanged,
    required this.ubicacionValidator,
    required this.stockDisponible,
    required this.mostrarStock,
    required this.stockStyle,
  });

  @override
  Widget build(BuildContext context) {
    final showStock = mostrarStock &&
        productoSeleccionado != null &&
        ubicacionSeleccionada != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Producto + eliminar
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Producto>(
                    value: productoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                    ),
                    items: productos
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (nuevo) async => onProductoChanged(nuevo),
                    validator: (_) => productoSeleccionado == null
                        ? 'Selecciona un producto'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: canDelete ? onDelete : null,
                  icon: const Icon(Icons.delete),
                  tooltip: 'Quitar producto',
                ),
              ],
            ),

            if (showStock)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: StockInfoCard(
                  label: 'Stock en ${ubicacionSeleccionada!.nombreAlmacen}:',
                  stock: stockDisponible,
                  style: stockStyle,
                ),
              ),

            const SizedBox(height: 16),

            // Cantidad + Precio + Ubicación
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    validator: cantidadValidator,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: precioCtrl,
                    readOnly: true,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: labelPrecio,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<Ubicacion>(
                    value: ubicacionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(),
                    ),
                    items: ubicacionesDisponibles
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(u.nombreAlmacen),
                          ),
                        )
                        .toList(),
                    onChanged: onUbicacionChanged,
                    validator: (_) => ubicacionValidator(ubicacionSeleccionada),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
