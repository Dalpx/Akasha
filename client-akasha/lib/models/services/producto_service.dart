import 'package:akasha/models/producto.dart';

class ProductoService {
  // Obtener lista de productos
  final List<Producto> lista_productos = ProductoData().productos;

  //CREATE: agregar un nuevo producto
  Future<bool> agregarProducto(Producto nuevoProducto) async {
    if (nuevoProducto.sku.isNotEmpty) {
      //se supone que acá iría el metodo que la agregue a la base de datos
      lista_productos.add(nuevoProducto);
      //se supone que acá iría el metodo que la agregue a la base de datos

      return true; //Exito
    } else {
      return false; //Exito
    }
  }

  //READ: Obtiene los productos de la base de datos
  List<Producto> leerProductos() {
    return lista_productos;
  }

  //Update: Obtiene el ID de un producto y actualiza la info
  Future<bool> actualizarProducto(
    int index,
    Producto actualizacionProducto,
  ) async {
    if (actualizacionProducto.sku.isNotEmpty) {
      lista_productos[index] = actualizacionProducto;

      return true; //Exito
    } else {
      return false; //Exito
    }
  }

  //Delete: Obtiene el ID de un producto y lo elimina
  Future<bool> eliminarProducto(int index) async {
    if (lista_productos.isNotEmpty) {
      lista_productos.removeAt(index);

      return true; //Exito
    } else {
      return false; //Exito
    }
  }
}
