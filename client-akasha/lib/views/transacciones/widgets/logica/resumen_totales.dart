import 'package:akasha/core/constants.dart';
import 'package:akasha/views/transacciones/widgets/logica/resumen_item.dart';

import 'package:flutter/material.dart';

class ResumenTotales extends StatelessWidget {
  final double subtotal;
  final double impuesto;
  final double total;
  final String labelImpuesto;

  const ResumenTotales({
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.labelImpuesto,
    super.key, // Añadir key para buenas prácticas
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foregroundColor = Constants().primaryForeground;

    // Estilo común para los textos de los totales
    final regularTextStyle = textTheme.bodyMedium?.copyWith(
      color: foregroundColor,
    );

    // Estilo especial para el Total
    final totalTextStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: foregroundColor,
    );

    // Estilo del separador
    const divider = VerticalDivider(
      color: Colors.white70,
      width: 16,
      indent: 4,
      endIndent: 4,
    );

    return Card(
      color: Constants().primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: ResumenItem(
                  label: 'Subtotal',
                  value: subtotal,
                  style: regularTextStyle,
                ),
              ),

              divider,

              Expanded(
                child: ResumenItem(
                  label: labelImpuesto,
                  value: impuesto,
                  style: regularTextStyle,
                ),
              ),

              divider,

              Expanded(
                child: ResumenItem(
                  label: 'Total',
                  value: total,
                  style: totalTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
