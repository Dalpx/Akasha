import 'dart:developer';
import 'dart:math';

import 'package:akasha/models/producto.dart';
import 'package:akasha/services/producto_service.dart';
import 'package:flutter/material.dart';

class InventarioView extends StatefulWidget {
  const InventarioView({super.key});

  @override
  State<InventarioView> createState() => _InventarioViewState();
}

class _InventarioViewState extends State<InventarioView> {
  // Servicio que se encarga de comunicarse con el backend / API
  final ProductoService _productoService = ProductoService();

  // Future que usa el FutureBuilder para pintar la lista de productos.
  // Lo guardamos en estado para poder "recargarlo" después de un CRUD.
  late Future<List<Producto>> _futureProductos;

  // Controllers para los campos del formulario (modal de crear/editar)
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController precioCostoController = TextEditingController();
  final TextEditingController precioVentaController = TextEditingController();
  final TextEditingController nomProveedorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cuando se crea la vista, disparamos la primera carga de datos
    _futureProductos = _productoService.fetchApiData();
  }

  @override
  void dispose() {
    // Liberamos los controllers cuando la vista se destruye
    nombreController.dispose();
    skuController.dispose();
    descripcionController.dispose();
    precioCostoController.dispose();
    precioVentaController.dispose();
    nomProveedorController.dispose();
    super.dispose();
  }

  // Esta función vuelve a pedir los productos al servicio y
  // fuerza el rebuild del FutureBuilder SIN recargar la página.
  void _recargarProductos() {
    setState(() {
      _futureProductos = _productoService.fetchApiData();
    });
  }

  // Modal para crear / editar un producto
  // Si idProducto viene null => modo "Agregar"
  // Si idProducto trae un valor => modo "Editar"
  void openNoteBox({int? idProducto}) async {
    // 1. Limpiamos los campos para asegurarnos de que el formulario
    //    siempre empiece vacío
    nombreController.clear();
    skuController.clear();
    descripcionController.clear();
    precioCostoController.clear();
    precioVentaController.clear();
    nomProveedorController.clear();

    // 2. Si estamos en modo edición, traemos los datos del producto
    if (idProducto != null) {
      try {
        final Producto? producto = await _productoService.obtenerProductoPorID(
          idProducto,
        );

        if (producto != null) {
          nombreController.text = producto.nombre;
          skuController.text = producto.sku;
          descripcionController.text = producto.descripcion;
          precioCostoController.text = producto.precioCosto.toString();
          precioVentaController.text = producto.precioVenta.toString();
          nomProveedorController.text = producto.idProveedor.toString();
        }
      } catch (e) {
        print('Error al obtener producto por ID: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                idProducto == null ? "Agregar" : "Editar",
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
                controller: skuController,
                decoration: const InputDecoration(label: Text("SKU")),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(label: Text("Descripción")),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: precioCostoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(label: Text("Precio Costo")),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: precioVentaController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(label: Text("Precio Venta")),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nomProveedorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(label: Text("Proveedor")),
              ),
            ],
          ),
        ),
        actions: [
          // Botón Agregar / Guardar
          ElevatedButton(
            // Hacemos la función async para poder esperar el llamado al servicio
            onPressed: () async {
              try {
                if (idProducto == null) {
                  // --- CREATE ---
                  await _productoService.createProducto(
                    Producto(
                      idProducto: Random().nextInt(100),
                      nombre: nombreController.text,
                      sku: skuController.text,
                      descripcion: descripcionController.text,
                      precioCosto: double.parse(precioCostoController.text),
                      precioVenta: double.parse(precioVentaController.text),
                      idProveedor: int.parse(nomProveedorController.text),
                      activo: 1,
                    ),
                  );
                } else {
                  // --- UPDATE ---
                  await _productoService.updateProducto(
                    Producto(
                      idProducto: idProducto,
                      nombre: nombreController.text,
                      sku: skuController.text,
                      descripcion: descripcionController.text,
                      precioCosto: double.parse(precioCostoController.text),
                      precioVenta: double.parse(precioVentaController.text),
                      idProveedor: int.parse(nomProveedorController.text),
                      activo: 1,
                    ),
                  );
                }

                // Si llegamos aquí, la operación se ejecutó sin lanzar excepción

                //  Volvemos a cargar la lista de productos
                //    Esto es lo que hace que la vista se actualice sin recargar toda la página
                _recargarProductos();

                // Limpiamos los controladores
                nombreController.clear();
                skuController.clear();
                descripcionController.clear();
                precioCostoController.clear();
                precioVentaController.clear();
                nomProveedorController.clear();

                // Cerramos el modal
                Navigator.pop(context);
              } catch (e) {
                print('Error al guardar producto: $e');
              }
            },
            // Texto dinámico según si estamos agregando o editando
            child: Text(idProducto == null ? "Agregar" : "Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Producto"),
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
        heroTag: 'fab-agregar-producto',
        onPressed: () {
          // Abrimos el formulario en modo "Agregar"
          openNoteBox();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Producto>>(
        // ✅ Usamos el Future almacenado en el estado
        future: _futureProductos,

        // builder = cómo reaccionar a cada estado del Future
        builder: (context, snapshot) {
          // --- 1) MIENTRAS SE ESPERA RESPUESTA DEL API ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- 2) SI HUBO ERROR EN LA PETICIÓN ---
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar los datos: ${snapshot.error}'),
            );
          }

          // --- 3) CUANDO LLEGAN LOS DATOS CORRECTAMENTE ---
          if (snapshot.hasData) {
            // Tomamos solo productos activos
            final List<Producto> productos = snapshot.data!
                .where((producto) => producto.activo == 1)
                .toList();

            // Si la lista está vacía, mostramos un mensaje
            if (productos.isEmpty) {
              return const Center(child: Text('No se encontraron productos.'));
            }

            // ListView.builder para renderizar cada producto
            return ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];

                return Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: ListTile(
                    // Tap corto -> editar producto
                    onTap: () {
                      openNoteBox(idProducto: producto.idProducto);
                    },
                    // Long press -> eliminar producto
                    onLongPress: () async {
                      try {
                        await _productoService.deleteProducto(producto);

                        // Después de borrar, refrescamos la lista
                        _recargarProductos();
                      } catch (e) {
                        print('Error al eliminar producto: $e');
                      }
                    },
                    leading: Text(
                      producto.idProducto.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    title: Text(producto.nombre),
                    subtitle: Text(
                      'Costo: \$${producto.precioCosto.toStringAsFixed(2)} | Venta: \$${producto.precioVenta.toStringAsFixed(2)}',
                    ),
                    trailing: Text(producto.sku),
                  ),
                );
              },
            );
          }

          // Si llegamos aquí, no hay datos ni error (caso poco común)
          return const Center(child: Text('Inicie la carga de datos.'));
        },
      ),
    );
  }
}
