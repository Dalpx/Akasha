import 'package:flutter/material.dart';

class StockBanner extends StatelessWidget {
  final bool isSalida;
  final String ubicacionNombre;
  final int stock;

  const StockBanner({
    super.key,
    required this.isSalida,
    required this.ubicacionNombre,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    final color = stock > 0
        ? Colors.green.shade50
        : (isSalida ? Colors.red.shade50 : Colors.blue.shade50);

    final borderColor = stock > 0
        ? Colors.green.shade300
        : (isSalida ? Colors.red.shade300 : Colors.blue.shade300);

    final textColor = stock > 0
        ? Colors.green.shade700
        : (isSalida ? Colors.red.shade700 : Colors.blue.shade700);

    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stock actual en $ubicacionNombre:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '$stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
