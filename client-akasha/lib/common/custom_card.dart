import 'package:akasha/core/constants.dart';
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget content;
  final Color? color;
  const CustomCard({super.key, required this.content, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? Constants().card,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: content,
      ),
    );
  }
}