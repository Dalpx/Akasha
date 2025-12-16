import 'package:akasha/common/custom_card.dart';
import 'package:akasha/views/inventario/helpers/movimiento_stock_helper.dart';
import 'package:flutter/material.dart';

import 'package:akasha/models/producto.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_shared.dart';

import 'stock_banner.dart';

class MovimientoFormSectionCard extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;

  final List<Producto> productos;
  final List<Ubicacion> ubicaciones;

  final int tipoMovimiento;
  final Producto? productoSeleccionado;
  final Ubicacion? ubicacionSeleccionada;

  final TextEditingController cantidadCtrl;
  final TextEditingController descripcionCtrl;

  final MovimientoStockHelper stock;

  final bool guardando;

  final Future<void> Function(int?) onTipoChanged;
  final Future<void> Function(Producto?) onProductoChanged;
  final void Function(Ubicacion?) onUbicacionChanged;
  final Future<void> Function() onRegistrar;

  const MovimientoFormSectionCard({
    super.key,
    required this.title,
    required this.formKey,
    required this.productos,
    required this.ubicaciones,
    required this.tipoMovimiento,
    required this.productoSeleccionado,
    required this.ubicacionSeleccionada,
    required this.cantidadCtrl,
    required this.descripcionCtrl,
    required this.stock,
    required this.guardando,
    required this.onTipoChanged,
    required this.onProductoChanged,
    required this.onUbicacionChanged,
    required this.onRegistrar,
  });

  @override
  Widget build(BuildContext context) {
    final isSalida = tipoMovimiento == 0;
    final idProducto = productoSeleccionado?.idProducto;

    final ubicacionesDisponibles = isSalida
        ? stock.ubicacionesConStock(idProducto, ubicaciones)
        : stock.ubicacionesAfiliadasAlProducto(idProducto, ubicaciones);

    final Ubicacion? ubicValue =
        (ubicacionSeleccionada != null &&
            ubicacionesDisponibles.any(
              (u) => u.idUbicacion == ubicacionSeleccionada!.idUbicacion,
            ))
        ? ubicacionSeleccionada
        : null;

    final showStock = productoSeleccionado != null && ubicValue != null;
    final stockValue = showStock
        ? stock.stockEnUbicacion(idProducto, ubicValue)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Crear movimiento de inventario",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 12),
        CustomCard(
          content: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int>(
                        value: tipoMovimiento,
                        decoration: const InputDecoration(
                          labelText: 'Tipo movimiento',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Entrada')),
                          DropdownMenuItem(value: 0, child: Text('Salida')),
                        ],
                        onChanged: (v) => onTipoChanged(v),
                      ),
                    ),
                    SizedBox(
                      width: 320,
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
                                child: Text(
                                  p.nombre,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => onProductoChanged(v),
                        validator: (_) => productoSeleccionado == null
                            ? 'Selecciona un producto'
                            : null,
                      ),
                    ),
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<Ubicacion>(
                        value: ubicValue,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación',
                          border: OutlineInputBorder(),
                        ),
                        items: ubicacionesDisponibles.map((u) {
                          final display = isSalida && idProducto != null
                              ? '${u.nombreAlmacen} '
                              : u.nombreAlmacen;
                          return DropdownMenuItem(
                            value: u,
                            child: Text(display),
                          );
                        }).toList(),
                        onChanged: onUbicacionChanged,
                        validator: (v) {
                          if (ubicacionesDisponibles.isEmpty) {
                            return isSalida
                                ? 'Sin stock en almacenes'
                                : 'Producto sin ubicaciones afiliadas';
                          }
                          if (v == null) return 'Selecciona una ubicación';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                if (showStock) ...[
                  const SizedBox(height: 10),
                  StockBanner(
                    isSalida: isSalida,
                    ubicacionNombre: ubicValue.nombreAlmacen,
                    stock: stockValue,
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextFormField(
                        controller: cantidadCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final c = parseIntSafe(v ?? '');
                          if (c <= 0) return 'Cantidad inválida';
                          if (isSalida) {
                            final st = stock.stockEnUbicacion(
                              idProducto,
                              ubicValue,
                            );
                            if (c > st) return 'Stock insuficiente ($st)';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(
                      width: 520,
                      child: TextFormField(
                        controller: descripcionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty)
                            return 'Describe el movimiento';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: guardando ? null : onRegistrar,
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
