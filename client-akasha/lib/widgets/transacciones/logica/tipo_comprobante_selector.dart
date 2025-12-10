import 'package:flutter/material.dart';
import 'package:akasha/models/tipo_comprobante.dart';

class TipoComprobanteSelector extends StatelessWidget {
  final List<TipoComprobante> items;
  final TipoComprobante? value;
  final ValueChanged<TipoComprobante?> onChanged;
  final String label;

  const TipoComprobanteSelector({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label = 'Tipo comprobante / pago',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TipoComprobante>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((t) => DropdownMenuItem(value: t, child: Text(t.nombre)))
          .toList(),
      onChanged: onChanged,
      validator: (_) => value == null ? 'Selecciona un tipo de pago' : null,
    );
  }
}
