import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/proveedor.dart';

/// Servicio que maneja la obtención y gestión de proveedores.
/// En esta versión, los datos se mantienen en memoria.
/// En una app real, aquí irían las llamadas HTTP al backend.
class ProveedorService {
  final List<Proveedor> _proveedores = <Proveedor>[];

  final String _baseUrl = "http://localhost/akasha/server-akasha/src/proveedor";

  /// Devuelve la lista de proveedores activos.
  Future<List<Proveedor>> obtenerProveedoresActivos() async {
    final url = Uri.parse(_baseUrl);
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonProveedor = jsonDecode(response.body);

        //Convertimos a lista de productos
        final List<Proveedor> proovedor = jsonProveedor
            .map(
              (proveedor) =>
                  Proveedor.fromJson(proveedor as Map<String, dynamic>),
            )
            .toList();

        return proovedor;
      } else {
        log("Fallo el codigo: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("El error fue: ${e}");
      return [];
    }
  }

  /// Crea un nuevo proveedor y lo agrega a la lista en memoria.
  Future<void> crearProveedor(Proveedor proveedor) async {
    final url = Uri.parse(_baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          proveedor.toJson(),
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

  /// Actualiza los datos de un proveedor existente.
  Future<void> actualizarProveedor(Proveedor proveedorActualizado) async {
    final url = Uri.parse(
      '$_baseUrl/${proveedorActualizado.idProveedor}',
    ); // Asegúrate de que Producto tenga un 'id'


    try {
      final response = await http.put(
        // Se usa PUT para reemplazar completamente el recurso
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(proveedorActualizado.toJson()),
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

  /// Elimina lógicamente un proveedor (lo marca como inactivo).
  Future<void> eliminarProveedor(int idProveedor) async {
    final url = Uri.parse("${_baseUrl}/${idProveedor}");
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'id_prov': idProveedor}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content es común para un DELETE exitoso
        log("Producto con ID ${idProveedor} eliminado con éxito.");
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
