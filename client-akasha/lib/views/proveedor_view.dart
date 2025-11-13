// lib/views/proveedor_view.dart

import 'dart:developer';
import 'dart:math';

import 'package:akasha/models/proveedor.dart';
import 'package:akasha/services/proveedor_service.dart';
import 'package:flutter/material.dart';

class ProveedorView extends StatefulWidget {
  const ProveedorView({super.key});

  @override
  State<ProveedorView> createState() => _ProveedorViewState();
}

class _ProveedorViewState extends State<ProveedorView> {
  // Servicio que se encarga de llamar a la API de Proveedores
  final ProveedorService _proveedorService = ProveedorService();

  // Future que usa el FutureBuilder para pintar la lista de proveedores
  late Future<List<Proveedor>> _futureProveedores;

  // Controllers para el formulario del modal
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController canalController = TextEditingController();
  final TextEditingController contactoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargamos los proveedores cuando se abre la vista
    _futureProveedores = _proveedorService.fetchApiData();
  }

  @override
  void dispose() {
    // Liberamos memoria de los controllers
    nombreController.dispose();
    canalController.dispose();
    contactoController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  // Vuelve a pedir la lista de proveedores al servicio
  // y fuerza el rebuild del FutureBuilder
  void _recargarProveedores() {
    setState(() {
      _futureProveedores = _proveedorService.fetchApiData();
    });
  }

  // Modal para Crear / Editar proveedor
  // Si idProveedor == null → Crear
  // Si idProveedor != null → Editar
  void openProveedorBox({int? idProveedor}) async {
    // 1. Limpia el formulario
    nombreController.clear();
    canalController.clear();
    contactoController.clear();
    direccionController.clear();

    // 2. Si hay idProveedor, estamos editando: cargamos datos desde el servicio
    if (idProveedor != null) {
      try {
        final Proveedor? proveedor = await _proveedorService
            .obtenerProveedorPorID(idProveedor);

        if (proveedor != null) {
          nombreController.text = proveedor.nombre;
          canalController.text = proveedor.canal;
          contactoController.text = proveedor.contacto;
          direccionController.text = proveedor.direccion;
        }
      } catch (e) {
        print('Error al obtener proveedor por ID: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                idProveedor == null ? "Agregar proveedor" : "Editar proveedor",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(label: Text("Nombre")),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: canalController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(label: Text("Teléfono")),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contactoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(label: Text("Correo")),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: direccionController,
                decoration: const InputDecoration(label: Text("Dirección")),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              try {
                bool ok = false;

                if (idProveedor == null) {
                  // --- CREATE ---
                  ok = await _proveedorService.createProveedor(
                    Proveedor(
                      idProveedor: Random().nextInt(100000),
                      nombre: nombreController.text,
                      canal: canalController.text,
                      contacto: contactoController.text,
                      direccion: direccionController.text,
                      activo: 1,
                    ),
                  );
                } else {
                  // --- UPDATE ---
                  ok = await _proveedorService.updateProveedor(
                    Proveedor(
                      idProveedor: idProveedor,
                      nombre: nombreController.text,
                      canal: canalController.text,
                      contacto: contactoController.text,
                      direccion: direccionController.text,
                      activo: 1,
                    ),
                  );
                }

                if (ok) {
                  // Si la API respondió bien, recargamos la lista
                  _recargarProveedores();

                  // Limpiamos los campos del formulario
                  nombreController.clear();
                  canalController.clear();
                  contactoController.clear();
                  direccionController.clear();

                  // Cerramos el modal
                  Navigator.pop(context);
                }
              } catch (e) {
                print('Error al guardar proveedor: $e');
              }
            },
            child: Text(idProveedor == null ? "Agregar" : "Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Proveedores"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              print("Redirigir a notificaciones");
            },
            icon: Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
              print("Cerrar Sesion");
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-agregar-proveedor',
        // Abrimos el modal en modo "Agregar"
        onPressed: () => openProveedorBox(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Proveedor>>(
        // Usamos el Future que guardamos en el estado
        future: _futureProveedores,
        builder: (context, snapshot) {
          // 1) Mientras se cargan datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2) Si hubo error
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar los proveedores: ${snapshot.error}'),
            );
          }

          // 3) Si hay datos
          if (snapshot.hasData) {
            // Filtramos solo activos (si usas campo "activo")
            final proveedores = snapshot.data!
                .where((p) => p.activo == 1)
                .toList();

            if (proveedores.isEmpty) {
              return const Center(
                child: Text('No se encontraron proveedores.'),
              );
            }

            return ListView.builder(
              itemCount: proveedores.length,
              itemBuilder: (context, index) {
                final proveedor = proveedores[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  child: ListTile(
                    // Tap corto → editar
                    onTap: () {
                      openProveedorBox(idProveedor: proveedor.idProveedor);
                    },
                    // Long press → eliminar
                    onLongPress: () async {
                      try {
                        final eliminado = await _proveedorService
                            .deleteProveedor(proveedor);

                        if (eliminado) {
                          _recargarProveedores();
                        }
                      } catch (e) {
                        print('Error al eliminar proveedor: $e');
                      }
                    },
                    leading: CircleAvatar(
                      child: Text(
                        proveedor.nombre.isNotEmpty
                            ? proveedor.nombre[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(proveedor.nombre),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Canal: ${proveedor.canal}'),
                        Text('Contacto: ${proveedor.contacto}'),
                        Text('Dirección: ${proveedor.direccion}'),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          // Caso extremo: sin datos ni error
          return const Center(
            child: Text('Inicie la carga de datos de proveedores.'),
          );
        },
      ),
    );
  }
}
