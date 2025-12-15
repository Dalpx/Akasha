import 'package:akasha/core/constants.dart';
import 'package:flutter/material.dart';

class ResumenItem extends StatelessWidget {
  final String label;
  final double value;
  final TextStyle? style;

  const ResumenItem({
    required this.label,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: Constants().primaryForeground),),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(2),
          style: style,
        ),
         
      ],
    );
  }
}
