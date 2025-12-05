import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/compra.dart';
import '../models/detalle_compra.dart';

class CompraService {
  final String _baseUrl =
      'http://localhost/akasha/server-akasha/src/compra';

  Map<String, String> get _headers => const {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      };

  Future<List<Compra>> obtenerCompras() async {
    final resp = await http.get(Uri.parse(_baseUrl), headers: _headers);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(
          'Error ${resp.statusCode} al obtener compras: ${resp.body}');
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));

    if (decoded is List) {
      return decoded
          .map((e) => Compra.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (decoded is Map && decoded['data'] is List) {
      final data = decoded['data'] as List;
      return data
          .map((e) => Compra.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return const <Compra>[];
  }

  Future<List<DetalleCompra>> obtenerDetallesCompra(int idCompra) async {
    final resp =
        await http.get(Uri.parse('$_baseUrl/$idCompra'), headers: _headers);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(
          'Error ${resp.statusCode} al obtener compra: ${resp.body}');
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));

    if (decoded is Map<String, dynamic>) {
      final raw = decoded['detalle_compra'];
      if (raw is List) {
        return raw
            .map((e) => DetalleCompra.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    if (decoded is Map && decoded['data'] is Map) {
      final data = decoded['data'] as Map;
      final raw = data['detalle_compra'];
      if (raw is List) {
        return raw
            .map((e) => DetalleCompra.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return const <DetalleCompra>[];
  }

  Future<bool> registrarCompra({
    required CompraCreate cabecera,
    required List<DetalleCompra> detalles,
  }) async {
    final body = {
      'compra': cabecera.toJson(),
      'detalle_compra': detalles.map((d) => d.toJson()).toList(),
    };

    final resp = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: json.encode(body),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return true;
    }

    throw HttpException(
        'Error ${resp.statusCode} al registrar compra: ${resp.body}');
  }
}
