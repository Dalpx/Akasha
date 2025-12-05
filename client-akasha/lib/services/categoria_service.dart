import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/categoria.dart';

/// Servicio que maneja la obtención y gestión de categorías.
/// En esta versión, los datos se mantienen en memoria.
class CategoriaService {

  final String _categoriaUrl =
      "http://localhost/akasha/server-akasha/src/categoria";

  /// Devuelve la lista completa de categorías.
  Future<List<Categoria>> obtenerCategorias() async {
     final url = Uri.parse(_categoriaUrl);
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonCateogria = jsonDecode(response.body);

        //Convertimos a lista de cateogrias
        final List<Categoria> categorias = jsonCateogria
            .map(
              (categoria) => Categoria.fromJson(categoria as Map<String, dynamic>),
            )
            .toList();

        return categorias;
      } else {
        log("Fallo el codigo: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("El error fue en ObtenerCategorias: $e");
      return [];
    }
  }

  /// Crea una nueva categoría y la agrega a la lista en memoria.
  Future<void> crearCategoria(Categoria categoria) async {
    final url = Uri.parse(_categoriaUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          categoria.toJson(),
        ), // Usamos toJson() del modelo Cateogria
      );

      if (response.statusCode == 201) {
        // 201 Created es la respuesta estándar para una creación exitosa
        log("Categoria creado con éxito. ID: ${response.body}");
      } else {
        log(
          "Fallo al crear categoria. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar crear categoria: $e");
    }
  }

  /// Actualiza los datos de una categoría existente.
  Future<void> actualizarCategoria(Categoria categoria) async {
    final url = Uri.parse(
      '$_categoriaUrl/${categoria.idCategoria}',
    ); // Asegúrate de que categoria tenga un 'id'

    try {
      final response = await http.put(
        // Se usa PUT para reemplazar completamente el recurso
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(categoria.toJson()),
      );

      if (response.statusCode == 200) {
        log("categoria actualizado con éxito.");
      } else {
        log(
          "Fallo al actualizar categoria. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar actualizar categoria: $e");
    }
  }

  /// Elimina una categoría de la lista (eliminación física en memoria).
  /// En una base de datos real, probablemente se haría eliminación lógica.
  Future<void> eliminarCategoria(int idCategoria) async {
    final url = Uri.parse("$_categoriaUrl/$idCategoria");
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'id_categoria': idCategoria}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content es común para un DELETE exitoso
        log("Categoria con ID $idCategoria eliminado con éxito.");
      } else {
        log(
          "Fallo al eliminar Categoria. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar eliminar Categoria: $e");
    }
  }
}
