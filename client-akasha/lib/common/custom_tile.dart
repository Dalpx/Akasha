import 'package:akasha/core/constants.dart';
import 'package:flutter/material.dart';

class CustomTile extends StatelessWidget {
  final ListTile listTile;

  const CustomTile({super.key, required this.listTile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsGeometry.only(bottom: 8.0),
      child: Card(
        color: Constants().background, // Usando tus constantes originales
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Constants().borderInput, width: 1.0),
        ),
        child: listTile,
      ),
    );
  }
}
