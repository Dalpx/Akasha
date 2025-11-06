// ignore_for_file: public_member_api_docs, sort_constructors_first
class Producto {

  String nombre;
  String sku;
  String descripcion;
  double precioCosto;
  double precioVenta;
  int id_proveedor;

  Producto(
    this.nombre, {

    required this.sku,
    required this.descripcion,
    required this.precioCosto,
    required this.precioVenta,
    required this.id_proveedor,
  });

  //Metodos

  @override
  String toString() {
    return 'Producto(nombre: $nombre, sku: $sku, descripcion: $descripcion, precioCosto: $precioCosto, precioVenta: $precioVenta, id_proveedor: $id_proveedor)';
  }
}

//ESTO SE VA A BORRAR
// ----------------------------------------------------
// CLASE PARA ALMACENAR LA LISTA DE PRODUCTOS
// ----------------------------------------------------
class ProductoData {
  // 1. Declaración de la lista de productos
  final List<Producto> productos;

  // 2. Constructor que inicializa la lista con las 3 instancias
  ProductoData()
    : productos = [
        Producto(
          'Laptop Ultrabook X1',
          sku: 'LTX1-G10',
          descripcion: 'Laptop ligera de alto rendimiento para profesionales.',
          precioCosto: 850.00,
          precioVenta: 1299.99,
          id_proveedor: 1,
        ),
        Producto(
          'Mouse Ergonómico Inalámbrico',
          sku: 'MEI-3000',
          descripcion:
              'Mouse con diseño vertical para reducir la fatiga de la muñeca.',
          precioCosto: 15.50,
          precioVenta: 39.99,
          id_proveedor: 2,
        ),
        Producto(
          'Monitor LED 4K 27"',
          sku: 'ML4K-27A',
          descripcion:
              'Monitor de alta resolución con excelente precisión de color.',
          precioCosto: 350.00,
          precioVenta: 599.00,
          id_proveedor: 1,
        ),
      ];

  // Convierte la lista de productos en un Stream
  Stream<Producto> getProductosStream() {
   return Stream.fromIterable(productos);
  }

  // Si quieres que el stream emita la lista completa:
  Stream<List<Producto>> getProductosListStream() {
    return Stream.value(productos);
  }
}

// Acceder a la lista e iterar sobre ella
  // for (var producto in miBaseDeDatos.productos) {
  //   print(producto.toString());
  // }