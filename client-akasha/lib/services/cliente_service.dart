import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/cliente.dart';

/// Servicio que maneja la lógica de negocio relacionada con los clientes.
/// En esta versión, la información se mantiene en memoria para fines didácticos.
class ClienteService {
  final List<Cliente> _clientes = <Cliente>[];

  final String _clienteUrl =
      "http://localhost/akasha/server-akasha/src/cliente";

  /// Obtiene todos los clientes activos.
  Future<List<Cliente>> obtenerClientesActivos() async {
    final url = Uri.parse(_clienteUrl);
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonCliente = jsonDecode(response.body);

        //Convertimos a lista de cateogrias
        final List<Cliente> clientes = jsonCliente
            .map((cliente) => Cliente.fromJson(cliente as Map<String, dynamic>))
            .toList();

        return clientes;
      } else {
        log("Fallo el codigo: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("El error fue al obtenerClientes: $e");
      return [];
    }
  }

  /// Crea un nuevo cliente y lo agrega a la lista en memoria.
  Future<Cliente> crearCliente(Cliente cliente) async {
    final url = Uri.parse(_clienteUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          cliente.toJson(),
        ),
      );
      
      if (response.statusCode == 201) {
        // 201 Created es la respuesta estándar para una creación exitosa
        log("Cliente creado con éxito. ID: ${response.body}");
      } else {
        log(
          "Fallo al crear cliente. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
        throw Exception();
      }
    } catch (e) {
      log("Error al intentar crear cliente: $e");
    }
    return cliente;
  }

  /// Actualiza un cliente existente.
  Future<void> actualizarCliente(Cliente clienteActualizado) async {
    final url = Uri.parse(
      '$_clienteUrl/${clienteActualizado.idCliente}',
    ); // Asegúrate de que categoria tenga un 'id'

    try {
      final response = await http.put(
        // Se usa PUT para reemplazar completamente el recurso
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(clienteActualizado.toJson()),
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

  /// Elimina lógicamente un cliente (lo marca como inactivo).
  Future<void> eliminarCliente(int idCliente) async {
    final url = Uri.parse("$_clienteUrl/$idCliente");
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'id_cliente': idCliente}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 204 No Content es común para un DELETE exitoso
        log("Cliente con ID $idCliente eliminado con éxito.");
      } else {
        log(
          "Fallo al eliminar Cliente. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar eliminar Cliente: $e");
    }
  }
}
