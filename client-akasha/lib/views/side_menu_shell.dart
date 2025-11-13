import 'package:akasha/views/transaccion_view.dart';
import 'package:akasha/views/inventario_view.dart';
import 'package:akasha/views/notificacion_view.dart';
import 'package:akasha/views/proveedor_view.dart';
import 'package:akasha/views/reporte_view.dart';
import 'package:akasha/views/usuario_view.dart';
import 'package:flutter/material.dart';

class SideMenuShell extends StatefulWidget {
  const SideMenuShell({super.key});

  @override
  State<SideMenuShell> createState() => _SideMenuShellState();
}

class _SideMenuShellState extends State<SideMenuShell> {
  int _index = 0;

  // Keys estables para reforzar la preservación de estados
  final _pages = const [
    // KeyedSubtree(key: PageStorageKey('inicio'), child: InicioView()),
    KeyedSubtree(key: PageStorageKey('inventario'), child: InventarioView()),
    KeyedSubtree(key: PageStorageKey('proveedor'), child: ProveedorView()),
    KeyedSubtree(key: PageStorageKey('transaccion'), child: TransaccionView()),
    KeyedSubtree(key: PageStorageKey('reporte'), child: ReporteView()),
    KeyedSubtree(
      key: PageStorageKey('notificación'),
      child: NotificacionView(),
    ),
    KeyedSubtree(key: PageStorageKey('Usuario'), child: UsuarioView()),
  ];

  final _bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth >= 800; // umbral responsive

        return Scaffold(
          body: PageStorage(
            bucket: _bucket,
            child: Row(
              children: [
                // -- Layout con NavigationRail (Lateral) --
                if (isWide)
                  //Menu Lateral: Simple y efieciente
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    leading: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: FlutterLogo(size: 32),
                    ),
                    destinations: [
                      // NavigationRailDestination(
                      //   icon: Icon(Icons.home_outlined),
                      //   selectedIcon: Icon(Icons.home),
                      //   label: Text("Inicio"),
                      // ),
                      NavigationRailDestination(
                        icon: Icon(Icons.business_center_outlined),
                        selectedIcon: Icon(Icons.business_center),
                        label: Text("Producto"),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.local_shipping_outlined),
                        selectedIcon: Icon(Icons.local_shipping),
                        label: Text("Proveedor"),
                      ),
                      // NavigationRailDestination(
                      //   icon: Icon(Icons.compare_arrows_outlined),
                      //   selectedIcon: Icon(Icons.compare_arrows),
                      //   label: Text("Transacción"),
                      // ),
                      // NavigationRailDestination(
                      //   icon: Icon(Icons.assignment_outlined),
                      //   selectedIcon: Icon(Icons.assignment),
                      //   label: Text("Reporte"),
                      // ),
                      // NavigationRailDestination(
                      //   icon: Icon(Icons.warning_outlined),
                      //   selectedIcon: Icon(Icons.warning),
                      //   label: Text("Noficación"),
                      // ),
                      // NavigationRailDestination(
                      //   icon: Icon(Icons.person_outlined),
                      //   selectedIcon: Icon(Icons.person),
                      //   label: Text("Usuario"),
                      // ),
                    ],
                  ),
                //Contenido: IndexedStack conserva estado de cada vista
                Expanded(
                  child: IndexedStack(index: _index, children: _pages),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : // ---- Layout con BottomNavigationBar ----,
                NavigationBar(
                  
                  
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    // NavigationDestination(
                    //   icon: Icon(Icons.home_outlined),
                    //   selectedIcon: Icon(Icons.home),
                    //   label: "",
                    // ),
                    NavigationDestination(
                      icon: Icon(Icons.business_center_outlined),
                      selectedIcon: Icon(Icons.business_center),
                      label: "",
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.local_shipping_outlined),
                      selectedIcon: Icon(Icons.local_shipping),
                      label: "",
                    ),
                    // NavigationDestination(
                    //   icon: Icon(Icons.compare_arrows_outlined),
                    //   selectedIcon: Icon(Icons.compare_arrows),
                    //   label: "",
                    // ),
                    // NavigationDestination(
                    //   icon: Icon(Icons.assignment_outlined),
                    //   selectedIcon: Icon(Icons.assignment),
                    //   label: "",
                    // ),
                    // NavigationDestination(
                    //   icon: Icon(Icons.warning_outlined),
                    //   selectedIcon: Icon(Icons.warning),
                    //   label: "",
                    // ),
                    // NavigationDestination(
                    //   icon: Icon(Icons.person_outlined),
                    //   selectedIcon: Icon(Icons.person),
                    //   label: "",
                    // ),
                  ],
                ),
        );
      },
    );
  }
}
