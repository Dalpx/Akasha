import 'dart:convert';
import 'dart:developer';

import 'package:akasha/models/producto.dart';
import 'package:http/http.dart' as http;

class ProductoService {
  final String _baseUrl = "http://localhost/akasha/server-akasha/src/producto";

  //CREATE (POST)
  Future<bool> createProducto(Producto producto) async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          producto.toJson(0),
        ), // Usamos toJson() del modelo Producto
      );

      if (response.statusCode == 201) {
        // 201 Created es la respuesta estándar para una creación exitosa
        log("Producto creado con éxito. ID: ${response.body}");
        return true;
      } else {
        log(
          "Fallo al crear producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
        return false;
      }
    } catch (e) {
      log("Error al intentar crear producto: $e");
      return false;
    }
  }

  //READ
  Future<List<Producto>> fetchApiData() async {
    final url = Uri.parse(_baseUrl);

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

        log("Datos recibidos con exito");
        return productos;
      } else {
        log("Fallo el codigo: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("El error fue: ${e}");
      return [];
    }
  }

  //UPDATE
  // Asumo que la API acepta el ID del producto en el path para la actualización
  Future<bool> updateProducto(Producto producto) async {
    final url = Uri.parse(
      '$_baseUrl/${producto.idProducto}',
    ); // Asegúrate de que Producto tenga un 'id'

    try {
      final response = await http.put(
        // Se usa PUT para reemplazar completamente el recurso
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson(1)),
      );

      if (response.statusCode == 200) {
        log("Producto actualizado con éxito.");
        return true;
      } else {
        log(
          "Fallo al actualizar producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
        return false;
      }
    } catch (e) {
      log("Error al intentar actualizar producto: $e");
      return false;
    }
  }

  //DELETE
  // Se necesita el ID del producto a eliminar
  Future<bool> deleteProducto(Producto producto) async {
    // URL: http://localhost/akasha/server-akasha/src/producto/123
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson(3)),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content es común para un DELETE exitoso
        log("Producto con ID ${producto.idProducto} eliminado con éxito.");
        return true;
      } else {
        log(
          "Fallo al eliminar producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
        return false;
      }
    } catch (e) {
      log("Error al intentar eliminar producto: $e");
      return false;
    }
  }

  //Obtener producto por ID
  Future<Producto?> obtenerProductoPorID(int id) async {
    // Asegúrate de que _baseUrl está definido en tu clase (por ejemplo, 'http://tuapi.com/productos')
    final url = Uri.parse("$_baseUrl/$id");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // 1. Decodificar el cuerpo de la respuesta de JSON a un Map de Dart
        final dynamic body = jsonDecode(response.body);

        // 2. Comprobar si la respuesta es un Map (que representa un solo producto)
        if (body is Map<String, dynamic>) {
          // 3. Convertir el Map a un objeto Producto usando el constructor fromJson
          final Producto producto = Producto.fromJson(body);
          print(producto.toString());
          return producto;
        } else {
          // Manejar casos donde la respuesta 200 no es un producto individual esperado
          log("Respuesta 200, pero el formato no es el esperado (Map).");
          return null;
        }
      } else if (response.statusCode == 404) {
        // Manejar el caso de 'No encontrado'
        log("Producto no encontrado. Código: 404");
        return null;
      } else {
        // Manejar otros errores HTTP (400, 500, etc.)
        log("Falló el código: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      // Manejar errores de red, decodificación, etc.
      log("El error fue: $e");
      return null; // Devolver null en caso de error
    }
  }
}
