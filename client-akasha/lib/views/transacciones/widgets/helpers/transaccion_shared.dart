import 'dart:math';

import 'package:akasha/common/custom_card.dart';
import 'package:akasha/core/constants.dart';
import 'package:flutter/material.dart';

int parseIntSafe(String value) {
  if (value.trim().isEmpty) return 0;
  return int.tryParse(value) ?? 0;
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

String limpiarNombreArchivoWindows(String input) {
  // Windows no permite / : * ? " < > |
  return input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
}

double historialHeight(BuildContext context) {
  final screenH = MediaQuery.of(context).size.height;
  return min(420, max(220, screenH * 0.45));
}

class TransaccionLayout extends StatelessWidget {
  final Key scrollKey;
  final Widget factura;
  final Widget historial;

  const TransaccionLayout({
    super.key,
    required this.scrollKey,
    required this.factura,
    required this.historial,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool twoColumns = w >= 1100;

    if (twoColumns) {
      return SingleChildScrollView(
        key: scrollKey,
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
      key: scrollKey,
      padding: const EdgeInsets.all(12),
      child: Column(children: [factura, const SizedBox(height: 16), historial]),
    );
  }
}

class FacturaSectionCard extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> selectors;
  final VoidCallback? onAddLinea;
  final List<Widget> lineas;
  final Widget totales;
  final String addButtonText;
  final double lineasHeight;

  const FacturaSectionCard({
    super.key,
    required this.title,
    required this.formKey,
    required this.selectors,
    required this.onAddLinea,
    required this.lineas,
    required this.totales,
    this.addButtonText = 'Agregar producto',
    this.lineasHeight = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        CustomCard(
          content: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Datos del cliente: ",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Wrap(spacing: 12, runSpacing: 12, children: selectors),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Productos: ${lineas.length}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onAddLinea,
                      icon: const Icon(Icons.add),
                      label: Text(addButtonText),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: lineasHeight,
                  child: SingleChildScrollView(child: Column(children: lineas)),
                ),
                const SizedBox(height: 8),
                totales,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HistorialSectionCard<T> extends StatelessWidget {
  final List<T> items;
  final String emptyText;
  final Key listKey;
  final Widget Function(BuildContext context, T item) itemBuilder;

  const HistorialSectionCard({
    super.key,
    required this.items,
    required this.emptyText,
    required this.listKey,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final h = historialHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   title,
        //   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        // ),
        CustomCard(
          content: SizedBox(
            height: h,
            width: double.infinity,
            child: items.isEmpty
                ? Center(child: Text(emptyText))
                : ListView.separated(
                    key: listKey,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0, color: Colors.transparent),
                    itemBuilder: (ctx, i) => itemBuilder(ctx, items[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class StockBannerCard extends StatelessWidget {
  final String label;
  final int stock;
  final Color background;
  final Color borderColor;
  final Color valueColor;

  const StockBannerCard({
    super.key,
    required this.label,
    required this.stock,
    required this.background,
    required this.borderColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: borderColor, width: 1),
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

class LineaProductoCardBase extends StatelessWidget {
  final Widget productoSelector;
  final Widget? stockBanner;
  final Widget cantidadField;
  final Widget precioField;
  final Widget ubicacionField;
  final VoidCallback? onDelete;
  final bool canDelete;

  const LineaProductoCardBase({
    super.key,
    required this.productoSelector,
    required this.stockBanner,
    required this.cantidadField,
    required this.precioField,
    required this.ubicacionField,
    required this.onDelete,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Constants().background, // Usando tus constantes originales
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Constants().borderInput, width: 1.0),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: productoSelector),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: canDelete ? onDelete : null,
                  icon: const Icon(Icons.delete),
                  tooltip: 'Quitar producto',
                ),
              ],
            ),
            if (stockBanner != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: stockBanner!,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 1, child: cantidadField),
                const SizedBox(width: 8),
                Expanded(flex: 1, child: precioField),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: ubicacionField),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
