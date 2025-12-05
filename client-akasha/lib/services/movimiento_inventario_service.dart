import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/movimiento_inventario.dart';

class MovimientoInventarioService {
  final String _baseUrl =
      'http://localhost/akasha/server-akasha/src/movimiento';

  Map<String, String> get _headers => const {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      };

  Future<List<MovimientoInventario>> obtenerMovimientos() async {
    final resp = await http.get(Uri.parse(_baseUrl), headers: _headers);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(
          'Error ${resp.statusCode} al obtener movimientos: ${resp.body}');
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));

    if (decoded is List) {
      return decoded
          .map((e) => MovimientoInventario.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (decoded is Map && decoded['data'] is List) {
      final data = decoded['data'] as List;
      return data
          .map((e) => MovimientoInventario.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return const <MovimientoInventario>[];
  }

  Future<MovimientoInventario> obtenerMovimiento(int idMovimiento) async {
    final resp =
        await http.get(Uri.parse('$_baseUrl/$idMovimiento'), headers: _headers);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(
          'Error ${resp.statusCode} al obtener movimiento: ${resp.body}');
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));

    if (decoded is Map<String, dynamic>) {
      return MovimientoInventario.fromJson(decoded);
    }

    if (decoded is Map && decoded['data'] is Map) {
      return MovimientoInventario.fromJson(
          (decoded['data'] as Map).cast<String, dynamic>());
    }

    throw const FormatException('Formato inesperado en movimiento por ID.');
  }

  Future<bool> registrarMovimiento(MovimientoCreate mov) async {
    final resp = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: json.encode(mov.toJson()),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return true;
    }

    throw HttpException(
        'Error ${resp.statusCode} al registrar movimiento: ${resp.body}');
  }
}
