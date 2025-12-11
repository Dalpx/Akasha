import 'dart:convert';
import 'dart:developer';

import 'package:akasha/models/stock_ubicacion.dart';
import 'package:http/http.dart' as http;

import '../models/producto.dart';

class InventarioService {
  // Eliminamos las listas internas en memoria (o las dejamos vacías si se usaban para mocks iniciales,
  // pero la intención es que no se utilicen).
  // final List<Producto> _productosEnMemoria = <Producto>[];
  // final List<StockUbicacion> _stockUbicaciones = <StockUbicacion>[];

  final String _productoUrl =
      "http://localhost/akasha/server-akasha/src/producto";
  // Asumo un endpoint para la gestión de StockUbicacion.
  // Podría ser: http://localhost/akasha/server-akasha/src/stock_ubicacion
  final String _stockUbicacionUrl =
      "http://localhost/akasha/server-akasha/src/stock";

  /// Obtiene todos los productos activos. (Mantenido - Ya usa HTTP)
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
      log("El error fue en ObtenerProductos: $e");
      return [];
    }
  }

  // --- MÉTODOS DE PRODUCTO (CRUD - Mantenidos) ---

  /// Crea un nuevo producto. (Mantenido - Ya usa HTTP)
  Future<void> crearProducto(Producto producto) async {
    final url = Uri.parse(_productoUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson()),
      );

      if (response.statusCode == 201) {
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

  /// Actualiza un producto ya existente. (Mantenido - Ya usa HTTP)
  Future<void> actualizarProducto(Producto producto) async {
    final url = Uri.parse('$_productoUrl/${producto.idProducto}');
    
    print(producto.toString());
    try {
      final response = await http.put(
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

  /// Marca un producto como inactivo (eliminación lógica). (Mantenido - Ya usa HTTP)
  Future<void> eliminarProducto(int idProducto) async {
    final url = Uri.parse("$_productoUrl/$idProducto");
    try {
      // Nota: Aunque el original tenía body en un DELETE, lo más común es sin body.
      // Lo mantengo para simular el comportamiento anterior.
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'id_producto': idProducto}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        log("Producto con ID $idProducto eliminado con éxito.");
      } else {
        log(
          "Fallo al eliminar producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar eliminar producto: $e");
    }
  }

  Future<Producto?> buscarPorId(int idProducto) async {
    final url = Uri.parse("$_productoUrl/$idProducto");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonProducto = jsonDecode(response.body);
        return Producto.fromJson(jsonProducto);
      } else if (response.statusCode == 404) {
        log("Producto con ID $idProducto no encontrado.");
        return null;
      } else {
        log("Fallo al buscar producto por ID. Código: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      log("Error al intentar buscar producto por ID: $e");
      return null;
    }
  }

  Future<List<StockUbicacion>> obtenerStockPorUbicacionDeProducto(
    int idProducto,
  ) async {
    final url = Uri.parse("$_stockUbicacionUrl/$idProducto");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonStockUbicacion = jsonDecode(response.body);

        final List<StockUbicacion> resultado = jsonStockUbicacion
            .map(
              (stock) => StockUbicacion.fromJson(stock as Map<String, dynamic>),
            )
            .toList();

        return resultado;
      } else {
        log(
          "Fallo al obtener stock por ubicación. Código: ${response.statusCode}",
        );
        return [];
      }
    } catch (e) {
      log("Error al intentar obtener stock por ubicación: $e");
      return [];
    }
  }

  Future<int> obtenerStockTotalDeProducto(int idProducto) async {
    try {
      final List<StockUbicacion> stocks =
          await obtenerStockPorUbicacionDeProducto(idProducto);

      int stockTotal = stocks.fold(
        0,
        (sum, item) =>
            sum +
            item.cantidad, 
      );

      return stockTotal;
    } catch (e) {
      log("Error al calcular el stock total: $e");
      return 0; 
    }
  }

  Future<void> establecerStock(int idProducto, int idUbicacion) async {
    final url = Uri.parse(_stockUbicacionUrl);

    print("$idProducto $idUbicacion");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'id_producto': idProducto,
          'id_ubicacion': idUbicacion,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        log("Nueva instancia de ubicacion creada.");
      } else {
        log(
          "Fallo al establecer stock. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar establecer stock: $e");
    }
  }

  /// Marca un producto como inactivo (eliminación lógica). (Mantenido - Ya usa HTTP)
  Future<void> eliminarInstanciaUbicacion(
    int idProducto,
    int idUbicacion,
  ) async {
    final url = Uri.parse(_stockUbicacionUrl);
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'id_producto': idProducto,
          'id_ubicacion': idUbicacion,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        log("Producto con ID $idProducto eliminado con éxito.");
      } else {
        log(
          "Fallo al eliminar producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar eliminar producto: $e");
    }
  }
}
