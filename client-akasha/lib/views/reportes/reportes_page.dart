import 'package:flutter/material.dart';

/// Pantalla para visualizar reportes.
/// Por ejemplo: total de ventas, total de compras, productos más vendidos, etc.
class ReportesPage extends StatelessWidget {
  const ReportesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Módulo de Reportes (pendiente de implementación)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
