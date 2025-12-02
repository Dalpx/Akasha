import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/ubicacion.dart';

/// Servicio que gestiona el catálogo de ubicaciones del almacén.
/// Implementado como singleton para que toda la app comparta
/// la misma lista en memoria.
class UbicacionService {
  final String _baseUrl = "http://localhost/akasha/server-akasha/src/ubicacion";

  /// Obtiene todas las ubicaciones activas.
  Future<List<Ubicacion>> obtenerUbicacionesActivas() async {
    final url = Uri.parse(_baseUrl);
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonUbicacion = jsonDecode(response.body);

        //Convertimos a lista de productos
        final List<Ubicacion> ubicacion = jsonUbicacion
            .map(
              (ubicacion) =>
                  Ubicacion.fromJson(ubicacion as Map<String, dynamic>),
            )
            .toList();

        final List<Ubicacion> ubicacionesActivas = [];

        for (var element in ubicacion) {
          if (element.activa) {
            ubicacionesActivas.add(element);
          }
        }

        return ubicacionesActivas;
      } else {
        log("Fallo el codigo: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("El error fue al obtener Ubicaciones: ${e}");
      return [];
    }
  }

  /// Crea una nueva ubicación.
  Future<void> crearUbicacion(Ubicacion ubicacion) async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          ubicacion.toJson(),
        ), // Usamos toJson() del modelo Producto
      );

      if (response.statusCode == 201) {
        // 201 Created es la respuesta estándar para una creación exitosa
        log("ubicación creado con éxito. ID: ${response.body}");
      } else {
        log(
          "Fallo al crear ubicación. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar crear ubicación: $e");
    }
  }

  /// Actualiza una ubicación existente.
  Future<void> actualizarUbicacion(Ubicacion ubicacionActualizada) async {
    final url = Uri.parse(
      '$_baseUrl/${ubicacionActualizada.idUbicacion}',
    ); // Asegúrate de que Producto tenga un 'id'

    try {
      final response = await http.put(
        // Se usa PUT para reemplazar completamente el recurso
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(ubicacionActualizada.toJson()),
      );

      if (response.statusCode == 200) {
        log("Ubicacion actualizada con éxito.");
      } else {
        log(
          "Fallo al actualizar ubicacion. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar actualizar ubicacion: $e");
    }
  }

  /// Elimina lógicamente una ubicación (la marca como inactiva).
  Future<void> eliminarUbicacion(int idUbicacion) async {
    final url = Uri.parse("${_baseUrl}/${idUbicacion}");
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'id_ubicacion': idUbicacion}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content es común para un DELETE exitoso
        log("ubicacion con ID ${idUbicacion} eliminado con éxito.");
      } else {
        log(
          "Fallo al eliminar ubicacion. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar eliminar ubicacion: $e");
    }
  }
}
