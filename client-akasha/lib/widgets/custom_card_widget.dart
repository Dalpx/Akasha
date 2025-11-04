import 'package:akasha/utils/constant.dart';
import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const CustomCard({super.key, required this.child, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(UxRadius.radiusTile),
        color: color ?? UxColor.cardBackgroundColor,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}
