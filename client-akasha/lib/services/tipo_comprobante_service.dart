import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/tipo_comprobante.dart';

class TipoComprobanteService {
  // Si tu ruta real es /comprobante, cámbiala aquí:
  // final String _baseUrl = 'http://localhost/akasha/server-akasha/src/comprobante';
  final String _baseUrl =
      'http://localhost/akasha/server-akasha/src/comprobante';

  Map<String, String> get _headers => const {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
      };

  Future<List<TipoComprobante>> obtenerTiposComprobante() async {
    final resp = await http.get(Uri.parse(_baseUrl), headers: _headers);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException(
        'Error ${resp.statusCode} al obtener tipos de comprobante: ${resp.body}',
      );
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));

    final dynamic payload =
        (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : decoded;

    if (payload is List) {
      return payload
          .map((e) => TipoComprobante.fromJson(e as Map<String, dynamic>))
          .toList();
    }


    return const <TipoComprobante>[];
  }
}
