// lib/services/proveedor_service.dart

import 'dart:convert';
import 'dart:developer';

import 'package:akasha/models/proveedor.dart';
import 'package:http/http.dart' as http;

class ProveedorService {
  // 🔧 Ajusta esta URL a la de tu backend
  final String baseUrl = 'http://localhost/akasha/server-akasha/src/proveedor';

  // Trae la lista de proveedores desde la API
  Future<List<Proveedor>> fetchApiData() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Proveedor.fromJson(e)).toList();
      } else {
        log('Error al cargar proveedores: ${response.statusCode}');
        throw Exception('Error al cargar proveedores');
      }
    } catch (e) {
      log('Excepción en fetchApiData Proveedor: $e');
      rethrow;
    }
  }

  // Obtiene un proveedor por su ID (para editar)
  Future<Proveedor?> obtenerProveedorPorID(int idProveedor) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/$idProveedor'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Proveedor.fromJson(data);
      } else if (response.statusCode == 404) {
        // No encontrado
        return null;
      } else {
        log('Error al obtener proveedor por ID: ${response.statusCode}');
        throw Exception('Error al obtener proveedor por ID');
      }
    } catch (e) {
      log('Excepción en obtenerProveedorPorID: $e');
      rethrow;
    }
  }

  // Crea un nuevo proveedor
  Future<bool> createProveedor(Proveedor proveedor) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(proveedor.toJson(1)),
      );

      print(response.body.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        log('Error al crear proveedor: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('Excepción en createProveedor: $e');
      return false;
    }
  }

  // Actualiza un proveedor existente
  Future<bool> updateProveedor(Proveedor proveedor) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${proveedor.idProveedor}'),
        headers: {'Content-Type': 'application/json'},
        // body: jsonEncode(proveedor.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        log('Error al actualizar proveedor: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('Excepción en updateProveedor: $e');
      return false;
    }
  }

  // Elimina un proveedor (puede ser baja lógica según tu API)
  Future<bool> deleteProveedor(Proveedor proveedor) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/${proveedor.idProveedor}'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        log('Error al eliminar proveedor: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('Excepción en deleteProveedor: $e');
      return false;
    }
  }
}
