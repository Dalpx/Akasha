import 'package:akasha/utils/constant.dart';
import 'package:akasha/views/dashboard_view.dart';
import 'package:akasha/views/login_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akasha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: UxColor.bgColor,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginView(),
        '/dashboard': (context) => DashboardView()
      },
    );
  }
}
