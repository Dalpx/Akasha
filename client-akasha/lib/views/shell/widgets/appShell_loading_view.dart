import 'package:flutter/material.dart';

class AppShellLoadingView extends StatelessWidget {
  const AppShellLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
