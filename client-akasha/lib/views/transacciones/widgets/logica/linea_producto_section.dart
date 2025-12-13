import 'package:akasha/views/transacciones/widgets/logica/base_operacion_tab_state.dart';
import 'package:flutter/material.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/ubicacion.dart';
import 'linea_producto_card.dart';

class LineasProductoSection extends StatelessWidget {
  final String titulo;
  final List<LineaProductoForm> lineas;

  final List<Producto> productos;
  final List<Ubicacion> ubicaciones;

  final VoidCallback onAgregar;
  final void Function(int index) onEliminar;

  final void Function(LineaProductoForm linea, Producto? p) onProductoChanged;
  final void Function(LineaProductoForm linea, Ubicacion? u) onUbicacionChanged;

  final String precioLabel;

  const LineasProductoSection({
    super.key,
    required this.titulo,
    required this.lineas,
    required this.productos,
    required this.ubicaciones,
    required this.onAgregar,
    required this.onEliminar,
    required this.onProductoChanged,
    required this.onUbicacionChanged,
    required this.precioLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: onAgregar,
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: lineas.length,
            itemBuilder: (_, i) {
              final linea = lineas[i];
              return LineaProductoCard(
                index: i,
                linea: linea,
                productos: productos,
                ubicaciones: ubicaciones,
                precioLabel: precioLabel,
                onRemove: lineas.length > 1 ? () => onEliminar(i) : null,
                onProductoChanged: (p) => onProductoChanged(linea, p),
                onUbicacionChanged: (u) => onUbicacionChanged(linea, u),
              );
            },
          ),
        ),
      ],
    );
  }
}
