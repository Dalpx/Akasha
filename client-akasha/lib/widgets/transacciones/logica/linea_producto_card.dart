import 'package:akasha/widgets/transacciones/logica/base_operacion_tab_state.dart';
import 'package:flutter/material.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/ubicacion.dart';


class LineaProductoCard extends StatelessWidget {
  final int index;
  final LineaProductoForm linea;

  final List<Producto> productos;
  final List<Ubicacion> ubicaciones;

  final VoidCallback? onRemove;
  final ValueChanged<Producto?> onProductoChanged;
  final ValueChanged<Ubicacion?> onUbicacionChanged;

  final String precioLabel;

  const LineaProductoCard({
    super.key,
    required this.index,
    required this.linea,
    required this.productos,
    required this.ubicaciones,
    required this.onProductoChanged,
    required this.onUbicacionChanged,
    required this.precioLabel,
    this.onRemove,
  });

  int _parseIntLocal(String v) => int.tryParse(v.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Producto>(
                    value: linea.producto,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                    ),
                    items: productos
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p.nombre)))
                        .toList(),
                    onChanged: onProductoChanged,
                    validator: (_) =>
                        linea.producto == null ? 'Selecciona un producto' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete),
                  tooltip: 'Quitar producto',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: linea.cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final c = _parseIntLocal(value ?? '');
                      if (c <= 0) return 'Cantidad inválida';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: linea.precioCtrl,
                    readOnly: true,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: precioLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<Ubicacion>(
                    value: linea.ubicacionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(),
                    ),
                    items: ubicaciones
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.nombreAlmacen),
                            ))
                        .toList(),
                    onChanged: onUbicacionChanged,
                    validator: (_) {
                      if (ubicaciones.isEmpty) return 'No hay almacenes';
                      if (linea.ubicacionSeleccionada == null) {
                        return 'Selecciona una ubicación';
                      }
                      return null;
                    },
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
