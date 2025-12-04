import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../models/venta.dart';
import '../models/detalle_venta.dart';

class VentaService {
  final String _ventaUrl = "http://localhost/akasha/server-akasha/src/venta";

  /// Registra una venta con sus detalles en el backend vía HTTP.
  Future<Venta> registrarVenta(Venta venta, List<DetalleVenta> detalles) async {
    final uri = Uri.parse(_ventaUrl);
    // Armamos el body como lo espera ventaController::addVenta()
    final Map<String, dynamic> body = {
      'venta': {
        'nro_comprobante': venta.nroComprobante,
        'id_tipo_comprobante': venta.idTipoComprobante,
        'id_ubicacion': 1,
        'id_cliente': 1,
        'id_usuario': 1,
        'subtotal': venta.subtotal,
        'impuesto': venta.impuesto,
        'total': venta.total,
        'estado': 1,
      },
      'detalle_venta': detalles.map((d) => d.toJson()).toList(),
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al registrar venta: ${response.statusCode} - ${response.body}',
      );
    }

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);

      // Ajusta esto a cómo esté devolviendo realmente tu API
      final data = decoded['data'] ?? decoded['venta'] ?? decoded;

      try {
        final ventaCreada = Venta.fromJson(data as Map<String, dynamic>);

        return ventaCreada;
      } catch (_) {
        return venta;
      }
    }

    return venta;
  }

  /// Devuelve todas las ventas registradas.
  Future<List<Venta>> obtenerVentas() async {
    final uri = Uri.parse(_ventaUrl);

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Error al obtener ventas: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    // Soporta varios formatos de respuesta posibles
    if (decoded is Map<String, dynamic>) {
      // Ejemplo: { "message": "...", "data": [ { venta1 }, { venta2 } ] }
      if (decoded['data'] is List) {
        final List data = decoded['data'];
        return data
            .map(
              (ventaJson) => Venta.fromJson(ventaJson as Map<String, dynamic>),
            )
            .toList();
      }

      // Ejemplo: { "id_venta": 1, ... } (una sola venta)
      return [Venta.fromJson(decoded)];
    } else if (decoded is List) {
      // Ejemplo: [ { venta1 }, { venta2 } ]
      return decoded
          .map((ventaJson) => Venta.fromJson(ventaJson as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Formato de respuesta inesperado al obtener ventas');
  }

  /// Devuelve todos los detalles de una venta específica,
  Future<List<DetalleVenta>> obtenerDetallesPorVenta(int idVenta) async {
    final uri = Uri.parse("$_ventaUrl/$idVenta");

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al obtener detalles de la venta: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // Tomamos la lista cruda del JSON
    final List<dynamic> detallesJson = decoded["detalle_venta"] ?? [];

    // La convertimos a List<DetalleVenta>
    final List<DetalleVenta> detalles = detallesJson
        .map(
          (element) => DetalleVenta.fromJson(element as Map<String, dynamic>),
        )
        .toList();

    // Y la devolvemos
    return detalles;
  }
}
