import 'dart:convert';
import 'dart:developer';

import 'package:akasha/models/stock_ubicacion.dart';
import 'package:http/http.dart' as http;

import '../models/producto.dart';

class InventarioService {
  // Lista interna de productos en memoria.
  final List<Producto> _productosEnMemoria = <Producto>[];
  final List<StockUbicacion> _stockUbicaciones = <StockUbicacion>[];

  final String _productoUrl =
      "http://localhost/akasha/server-akasha/src/producto";

  /// Obtiene todos los productos activos.
  Future<List<Producto>> obtenerProductos() async {
    final url = Uri.parse(_productoUrl);
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonProducto = jsonDecode(response.body);

        //Convertimos a lista de productos
        final List<Producto> productos = jsonProducto
            .map(
              (producto) => Producto.fromJson(producto as Map<String, dynamic>),
            )
            .toList();

        return productos;
      } else {
        log("Fallo el codigo: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("El error fue en ObtenerProductos: ${e}");
      return [];
    }
  }

  /// Crea un nuevo producto y lo agrega a la lista en memoria.
  Future<void> crearProducto(Producto producto) async {
    final url = Uri.parse(_productoUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          producto.toJson(),
        ), // Usamos toJson() del modelo Producto
      );

      if (response.statusCode == 201) {
        // 201 Created es la respuesta estándar para una creación exitosa
        log("Producto creado con éxito. ID: ${response.body}");
      } else {
        log(
          "Fallo al crear producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar crear producto: $e");
    }
  }

  /// Actualiza un producto ya existente.
  Future<void> actualizarProducto(Producto producto) async {
    final url = Uri.parse(
      '$_productoUrl/${producto.idProducto}',
    ); // Asegúrate de que Producto tenga un 'id'

    try {
      final response = await http.put(
        // Se usa PUT para reemplazar completamente el recurso
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson()),
      );

      if (response.statusCode == 200) {
        log("Producto actualizado con éxito.");
      } else {
        log(
          "Fallo al actualizar producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar actualizar producto: $e");
    }
  }

  /// Marca un producto como inactivo (eliminación lógica).
  Future<void> eliminarProducto(int idProducto) async {
    // URL: http://localhost/akasha/server-akasha/src/producto/123
    final url = Uri.parse("${_productoUrl}/${idProducto}");
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'id_producto': idProducto}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content es común para un DELETE exitoso
        log("Producto con ID ${idProducto} eliminado con éxito.");
      } else {
        log(
          "Fallo al eliminar producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar eliminar producto: $e");
    }
  }

  /// Busca un producto por su id dentro de la lista en memoria.
  Producto? buscarPorId(int idProducto) {
    for (int i = 0; i < _productosEnMemoria.length; i++) {
      Producto producto = _productosEnMemoria[i];
      if (producto.idProducto == idProducto) {
        return producto;
      }
    }
    return null;
  }

  /// Disminuye el stock de un producto según una cantidad vendida.
  /// Si la cantidad supera el stock actual, el stock se deja en 0.
  Future<void> disminuirStock(int idProducto, int cantidadVendida) async {
    await Future.delayed(const Duration(milliseconds: 100));

    for (int i = 0; i < _productosEnMemoria.length; i++) {
      Producto actual = _productosEnMemoria[i];
      if (actual.idProducto == idProducto) {
        // int nuevoStock = actual.stock - cantidadVendida;
        // if (nuevoStock < 0) {
        //   nuevoStock = 0;
        // }
        // actual.stock = nuevoStock;
      }
    }
  }

  /// Aumenta el stock de un producto según una cantidad comprada.
  Future<void> aumentarStock(int idProducto, int cantidadComprada) async {
    await Future.delayed(const Duration(milliseconds: 100));

    for (int i = 0; i < _productosEnMemoria.length; i++) {
      Producto actual = _productosEnMemoria[i];
      if (actual.idProducto == idProducto) {
        // int nuevoStock = actual.stock + cantidadComprada;
        // actual.stock = nuevoStock;
      }
    }
  }

  //NUEVAS FUNCIONES PARA GESTIONAR LA UBICACIÓN
  /// Devuelve la lista de registros de stock por ubicación para un producto.
  Future<List<StockUbicacion>> obtenerStockPorUbicacionDeProducto(
    int idProducto,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    List<StockUbicacion> resultado = <StockUbicacion>[];

    for (int i = 0; i < _stockUbicaciones.length; i++) {
      StockUbicacion stock = _stockUbicaciones[i];
      if (stock.idProducto == idProducto) {
        resultado.add(stock);
      }
    }

    return resultado;
  }

  /// Establece (crea o actualiza) la cantidad de stock de un producto
  /// en una ubicación específica. Después recalcula el stock total del producto.
  Future<void> establecerStockEnUbicacion(
    int idProducto,
    String idUbicacion,
    int cantidad,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    StockUbicacion? existente;
    for (int i = 0; i < _stockUbicaciones.length; i++) {
      StockUbicacion s = _stockUbicaciones[i];
      if (s.idProducto == idProducto && s.idUbicacion == idUbicacion) {
        existente = s;
      }
    }

    if (existente == null) {
      StockUbicacion nuevo = StockUbicacion(
        idProducto: idProducto,
        idUbicacion: idUbicacion,
        cantidad: cantidad,
      );
      nuevo.idStockUbicacion = _stockUbicaciones.length + 1;
      _stockUbicaciones.add(nuevo);
    } else {
      existente.cantidad = cantidad;
    }

    // Recalcular el stock total en Producto.
    await _recalcularStockTotalProducto(idProducto);
  }

  /// Calcula la suma de stock en todas las ubicaciones para un producto
  /// y la guarda en el campo `stock` del modelo Producto.
  Future<void> _recalcularStockTotalProducto(int idProducto) async {
    int total = 0;

    for (int i = 0; i < _stockUbicaciones.length; i++) {
      StockUbicacion s = _stockUbicaciones[i];
      if (s.idProducto == idProducto) {
        total = total + s.cantidad;
      }
    }

    Producto? producto = buscarPorId(idProducto);
    if (producto != null) {
      // producto.stock = total;
    }
  }

  /// Disminuye el stock de un producto en una ubicación específica.
  /// Si la cantidad vendida es mayor que el stock actual, el stock se deja en 0.
  Future<void> disminuirStockEnUbicacion(
    int idProducto,
    String idUbicacion,
    int cantidadVendida,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    int cantidadActual = 0;
    StockUbicacion? existente;

    for (int i = 0; i < _stockUbicaciones.length; i++) {
      StockUbicacion stock = _stockUbicaciones[i];
      if (stock.idProducto == idProducto && stock.idUbicacion == idUbicacion) {
        existente = stock;
        cantidadActual = stock.cantidad;
      }
    }

    int nuevaCantidad = cantidadActual - cantidadVendida;
    if (nuevaCantidad < 0) {
      nuevaCantidad = 0;
    }

    if (existente == null) {
      StockUbicacion nuevo = StockUbicacion(
        idProducto: idProducto,
        idUbicacion: idUbicacion,
        cantidad: nuevaCantidad,
      );
      nuevo.idStockUbicacion = _stockUbicaciones.length + 1;
      _stockUbicaciones.add(nuevo);
    } else {
      existente.cantidad = nuevaCantidad;
    }

    await _recalcularStockTotalProducto(idProducto);
  }

  /// Aumenta el stock de un producto en una ubicación específica.
  Future<void> aumentarStockEnUbicacion(
    int idProducto,
    String idUbicacion,
    int cantidadComprada,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));

    int cantidadActual = 0;
    StockUbicacion? existente;

    for (int i = 0; i < _stockUbicaciones.length; i++) {
      StockUbicacion stock = _stockUbicaciones[i];
      if (stock.idProducto == idProducto && stock.idUbicacion == idUbicacion) {
        existente = stock;
        cantidadActual = stock.cantidad;
      }
    }

    int nuevaCantidad = cantidadActual + cantidadComprada;

    if (existente == null) {
      StockUbicacion nuevo = StockUbicacion(
        idProducto: idProducto,
        idUbicacion: idUbicacion,
        cantidad: nuevaCantidad,
      );
      nuevo.idStockUbicacion = _stockUbicaciones.length + 1;
      _stockUbicaciones.add(nuevo);
    } else {
      existente.cantidad = nuevaCantidad;
    }

    await _recalcularStockTotalProducto(idProducto);
  }
}
