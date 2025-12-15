import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/venta.dart';
import '../models/detalle_venta.dart';

class VentaService {
  // URL hardcodeada como en tu original
  final String _baseUrl = "http://localhost/akasha/server-akasha/src/venta";

  // Headers simples (Igual que CompraService, sin tokens)
  Map<String, String> get _headers => const {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        HttpHeaders.acceptHeader: 'application/json',
      };

  // --- OBTENER VENTAS ---
  Future<List<Venta>> obtenerVentas({int? idVenta}) async {
    final uri = Uri.parse(idVenta == null ? _baseUrl : '$_baseUrl?id_venta=$idVenta');
    final resp = await http.get(uri, headers: _headers);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('Error ${resp.statusCode} al obtener ventas: ${resp.body}');
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));
    
    // Manejo robusto de la respuesta (lista directa o envuelta en data)
    final dynamic payload = (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : decoded;

    if (payload is List) {
      return payload.map((e) => Venta.fromJson(e as Map<String, dynamic>)).toList();
    } 
    return const <Venta>[];
  }

  // --- OBTENER DETALLES (Usado por ReportesPage) ---
  Future<List<DetalleVenta>> obtenerDetallesVenta(int idVenta) async {
    final uri = Uri.parse('$_baseUrl/$idVenta');
    final resp = await http.get(uri, headers: _headers);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('Error ${resp.statusCode} al obtener detalle de venta: ${resp.body}');
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));

    // Buscamos la lista 'detalle_venta'
    if (decoded is Map<String, dynamic>) {
      // Intento 1: Directo en la raíz
      var raw = decoded['detalle_venta'];
      
      // Intento 2: Dentro de data (si tu backend lo envuelve)
      if (raw == null && decoded['data'] is Map) {
        raw = decoded['data']['detalle_venta'];
      }

      if (raw is List) {
        return raw.map((e) => DetalleVenta.fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return const <DetalleVenta>[];
  }

  // --- REGISTRAR VENTA ---
  Future<bool> registrarVenta({
    // Asumo que VentaCreate está en models/venta.dart o importado
    required dynamic cabecera,
    required List<DetalleVenta> detalles,
  }) async {
    final body = jsonEncode({
      'venta': cabecera.toJson(),
      'detalle_venta': detalles.map((d) => d.toJson()).toList(),
    });

    final resp = await http.post(Uri.parse(_baseUrl), headers: _headers, body: body);

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpException('Error ${resp.statusCode} al registrar venta: ${resp.body}');
    }

    final decoded = json.decode(utf8.decode(resp.bodyBytes));
    if (decoded is Map) {
      if (decoded['ok'] == true) return true;
      if (decoded['id_venta'] != null) return true;
      if ((decoded['message'] ?? '').toString().toLowerCase().contains('exito') ||
          (decoded['status'] ?? '').toString().toLowerCase() == 'success') {
        return true;
      }
    }
    return true;
  }
}