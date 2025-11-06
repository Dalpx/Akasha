import 'package:akasha/views/login_view.dart';
import 'package:akasha/views/side_menu_shell.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Akasha',
      initialRoute: '/',
      theme: ThemeData(
        //Background Color
        scaffoldBackgroundColor: Colors.grey.shade100,
        //Botones de la app
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        //Appbar
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        //Sidebar
        navigationRailTheme: NavigationRailThemeData(
          indicatorColor: Colors.lightBlueAccent,
          selectedIconTheme: IconThemeData(color: Colors.white),
          unselectedIconTheme: IconThemeData(color: Colors.white70),
          labelType: NavigationRailLabelType.none,
          backgroundColor: Colors.blue,
        ),

        //Bottom Navigation bar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.blue,
          indicatorColor: Colors.lightBlueAccent,
          // Estilo para los iconos NO seleccionados
          iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>((
            states,
          ) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(
                color: Colors.white,
              ); // El color del ícono seleccionado se hereda de 'indicatorColor' o 'labelTextStyle'
            }
            // Color para íconos no seleccionados
            return const IconThemeData(color: Colors.white70);
          }),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // Forzar el color de fondo (azul más oscuro)
            backgroundColor: Colors.blue,
            // Forzar el color del texto/ícono (blanco)
            foregroundColor: Colors.white,
            // Añadir un borde redondeado
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            // Ajustar el padding
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        // ElevatedButton
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          //Color del fondo
          backgroundColor: Colors.blue,
          // Color de los iconos y textos
          foregroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100.0),
          ),
        ),
      ),
      routes: {
        '/': (context) => LoginView(),
        '/SideMenuShell': (context) => SideMenuShell(),
      },
    );
  }
}
