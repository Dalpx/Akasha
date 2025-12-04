import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/compra.dart';
import '../models/detalle_compra.dart';

/// Servicio que encapsula la lógica de negocio de las compras.
/// Ahora trabaja contra la API (igual que VentaService), no con listas en memoria.
class CompraService {
  // Ajusta la URL si tu endpoint es distinto
  final String _compraUrl = "http://localhost/akasha/server-akasha/src/compra";

  Future<Compra> registrarCompra(
    Compra compra,
    List<DetalleCompra> detalles,
  ) async {
    final uri = Uri.parse(_compraUrl);

    final Map<String, dynamic> body = {
      'compra': compra.toJsonRegistro(),
      'detalle_compra': detalles
          .map((d) => d.toJsonRegistro())
          .toList(), // <--- IMPORTANTE
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al registrar compra: ${response.statusCode} - ${response.body}',
      );
    }

    // Parseo de respuesta o return compra, como prefieras
    return compra;
  }

  /// Devuelve todas las compras registradas (GET /compra).
  Future<List<Compra>> obtenerCompras() async {
    final uri = Uri.parse(_compraUrl);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      log(
        'Error al obtener compras: ${response.statusCode} - ${response.body}',
        name: 'CompraService',
      );
      throw Exception('Error al obtener compras: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    // Si tu API responde { "message": "...", "data": [ ... ] }
    // usamos decoded['data']; si no, asumimos que decoded ya es la lista.
    final List<dynamic> jsonCompras = decoded is Map<String, dynamic>
        ? (decoded['data'] ?? [])
        : decoded;

    final compras = jsonCompras
        .map((compra) => Compra.fromJson(compra as Map<String, dynamic>))
        .toList();

    return compras;
  }

  /// Devuelve los detalles de una compra específica (GET /compra/{id}).
  Future<List<DetalleCompra>> obtenerDetallesPorCompra(int idCompra) async {
    final uri = Uri.parse("$_compraUrl/$idCompra");

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      log(
        'Error al obtener detalles de la compra: '
        '${response.statusCode} - ${response.body}',
        name: 'CompraService',
      );
      throw Exception(
        'Error al obtener detalles de la compra: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    // Esperamos algo tipo:
    // { "message": "...", "detalle_compra": [ {...}, {...} ] }
    final List<dynamic> detallesJson = decoded is Map<String, dynamic>
        ? (decoded['detalle_compra'] ?? [])
        : [];

    final detalles = detallesJson
        .map((e) => DetalleCompra.fromJson(e as Map<String, dynamic>))
        .toList();

    return detalles;
  }
}
