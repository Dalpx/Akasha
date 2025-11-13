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
  //Servicio
  final ProductoService _productoService = ProductoService();

  //text controller
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController precioCostoController = TextEditingController();
  final TextEditingController precioVentaController = TextEditingController();
  final TextEditingController nomProveedorController = TextEditingController();

  void openNoteBox({int? idProducto}) async {
    // 2. Clear controllers first to ensure a fresh start
    nombreController.clear();
    skuController.clear();
    descripcionController.clear();
    precioCostoController.clear();
    precioVentaController.clear();
    nomProveedorController.clear();

    // 3. Check if we are in 'Edit' mode
    if (idProducto != null) {
      // 4. Fetch the product data
      Producto? producto = await _productoService.obtenerProductoPorID(idProducto);

      // 5. If data is found, set the text for each controller
      if (producto != null) {
        nombreController.text = producto.nombre;
        skuController.text = producto.sku;
        descripcionController.text = producto.descripcion;
        // Convert numbers to String for TextField
        precioCostoController.text = producto.precioCosto.toString();
        precioVentaController.text = producto.precioVenta.toString();
        nomProveedorController.text = producto.idProveedor.toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 380),
          child: Column(
            children: [
              Text(
                idProducto == null ? "Agregar" : "Editar",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              TextField(
                controller: nombreController,
                decoration: InputDecoration(label: Text("Nombre")),
              ),
              SizedBox(height: 8),
              TextField(
                controller: skuController,
                decoration: InputDecoration(label: Text("SKU")),
              ),
              SizedBox(height: 8),
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(label: Text("descripcion")),
              ),
              SizedBox(height: 8),
              TextField(
                controller: precioCostoController,
                decoration: InputDecoration(label: Text("Precio Costo")),
              ),
              SizedBox(height: 8),
              TextField(
                controller: precioVentaController,
                decoration: InputDecoration(label: Text("Precio Venta")),
              ),
              SizedBox(height: 8),
              TextField(
                controller: nomProveedorController,
                decoration: InputDecoration(label: Text("Proveedor")),
              ),
            ],
          ),
        ),
       actions: [
        //Boton agregar/editar
        ElevatedButton(
          onPressed: () {
            try {
              if (idProducto == null) {
                //Agrega un nuevo producto
                _productoService.createProducto(
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
                //Actualiza un producto
                print(idProducto);
                _productoService.updateProducto(
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
            } catch (e) {
              print(e);
            }

            //Limpia los controladores de texto SOLO DESPUÉS DE LA OPERACIÓN
            nombreController.clear();
            skuController.clear();
            descripcionController.clear();
            precioCostoController.clear();
            precioVentaController.clear();
            nomProveedorController.clear();

            //Cierra la modal
            Navigator.pop(context);
          },
          // Change button text dynamically
          child: Text(idProducto == null ? "Agregar" : "Guardar"), 
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inventario")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openNoteBox();
        },
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<List<Producto>>(
        // 1. EL FUTURE: Llama a la función que devuelve Future<List<Producto>>
        future: _productoService.fetchApiData(),

        // 2. EL BUILDER: Define cómo construir la interfaz en cada estado
        builder: (context, snapshot) {
          // --- ESTADO 1: ESPERANDO ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- ESTADO 2: CON ERROR ---
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar los datos: ${snapshot.error}'),
            );
          }

          // --- ESTADO 3: CON DATOS (List<Producto>) ---
          if (snapshot.hasData) {
            final List<Producto> productos = snapshot.data!
                .where((producto) => producto.activo == 1)
                .toList();

            // Si la lista está vacía
            if (productos.isEmpty) {
              return const Center(child: Text('No se encontraron productos.'));
            }

            // Construcción de la ListView con los datos
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
                    onTap: () {
                      openNoteBox(idProducto: producto.idProducto);
                    },
                    onLongPress: () =>
                        _productoService.deleteProducto(producto),
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

          // Si por alguna razón no hay datos ni error (debería ser capturado arriba)
          return const Center(child: Text('Inicie la carga de datos.'));
        },
      ),
    );
  }
}
