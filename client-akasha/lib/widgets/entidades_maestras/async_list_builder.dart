import 'package:flutter/material.dart';

class AsyncListBuilder<T> extends StatelessWidget {
  final Future<List<T>> future;
  final String emptyMessage;
  final String? errorPrefix;
  final Widget Function(List<T> data) builder;

  const AsyncListBuilder({
    super.key,
    required this.future,
    required this.emptyMessage,
    required this.builder,
    this.errorPrefix,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final prefix = errorPrefix?.trim();
          final msg = prefix == null || prefix.isEmpty
              ? 'Error: ${snapshot.error}'
              : '$prefix ${snapshot.error}';
          return Center(child: Text(msg));
        }

        final data = snapshot.data ?? <T>[];
        if (data.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        return builder(data);
      },
    );
  }
}
