import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/venta.dart';
import '../models/detalle_venta.dart';

class VentaService {
  // Mantengo tu endpoint base. Si lo quieres, muévelo a un ApiConfig central.
  final String _baseUrl = "http://localhost/akasha/server-akasha/src/venta";

  Map<String, String> get _headers => const {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        HttpHeaders.acceptHeader: 'application/json',
      };

  /// GET de ventas (lista). Soporta:
  /// - [ { ... }, ... ]
  /// - { message: "...", data: [ { ... } ] }
  Future<List<Venta>> obtenerVentas({int? idVenta}) async {
    final uri = Uri.parse(idVenta == null ? _baseUrl : '$_baseUrl?id_venta=$idVenta');
    final resp = await http.get(uri, headers: _headers);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('Error ${resp.statusCode} al obtener ventas: ${resp.body}');
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));
    final dynamic payload = (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : decoded;

    if (payload is List) {
      return payload.map((e) => Venta.fromJson(e as Map<String, dynamic>)).toList();
    } 
    return const <Venta>[];
  }

  Future<List<DetalleVenta>> obtenerDetallesVenta(int idVenta) async {
  // Endpoint correcto: /venta/{idVenta}
  final uri = Uri.parse('$_baseUrl/$idVenta');
  final resp = await http.get(uri, headers: _headers);

  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    throw HttpException(
      'Error ${resp.statusCode} al obtener detalle de venta: ${resp.body}',
    );
  }

  final decoded = json.decode(utf8.decode(resp.bodyBytes));

  // El endpoint devuelve un objeto con detalle_venta dentro
  if (decoded is Map<String, dynamic>) {
    final raw = decoded['detalle_venta'];

    if (raw is List) {
      return raw
          .map((e) => DetalleVenta.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  // // fallback por si el backend cambia a wrapper { data: { detalle_venta: [] } }
  // if (decoded is Map && decoded['data'] is Map) {
  //   final data = decoded['data'] as Map;
  //   final raw = data['detalle_venta'];
  //   if (raw is List) {
  //     return raw
  //         .map((e) => DetalleVenta.fromJson(e as Map<String, dynamic>))
  //         .toList();
  //   }
  // }

  return const <DetalleVenta>[];
}



  Future<bool> registrarVenta({
    required VentaCreate cabecera,
    required List<DetalleVenta> detalles,
  }) async {
    final body = jsonEncode({
      'venta': cabecera.toJson(),
      'detalle_venta': detalles.map((d) => d.toJson()).toList(),
    });

    print(body);

    final resp = await http.post(Uri.parse(_baseUrl), headers: _headers, body: body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('Error ${resp.statusCode} al registrar venta: ${resp.body}');
    }

    // El controller típico devuelve { "ok": true } o { "message": "...", "id_venta": N }.
    final decoded = json.decode(utf8.decode(resp.bodyBytes));
    if (decoded is Map) {
      if (decoded['ok'] == true) return true;
      if (decoded['id_venta'] != null) return true;
      if ((decoded['message'] ?? '').toString().toLowerCase().contains('exito') ||
          (decoded['status'] ?? '').toString().toLowerCase() == 'success') {
        return true;
      }
    }

    // Si no hay una marca clara, asumimos OK porque el HTTP ya fue 2xx.
    return true;
  }
}
