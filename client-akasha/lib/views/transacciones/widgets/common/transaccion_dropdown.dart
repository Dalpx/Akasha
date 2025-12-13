import 'package:flutter/material.dart';

class TransaccionDropdown<T> extends StatelessWidget {
  final double width;
  final String labelText;
  final T? value;
  final List<T> items;
  final String Function(T item) itemText;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const TransaccionDropdown({
    super.key,
    required this.width,
    required this.labelText,
    required this.value,
    required this.items,
    required this.itemText,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        items: items
            .map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemText(item)),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
        validator: validator,
      ),
    );
  }
}
