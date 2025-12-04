import 'detalle_venta.dart';

/// Representa la cabecera de una venta o factura.
class Venta {
  int? idVenta;
  DateTime fecha;
  String nroComprobante;
  String nombreCliente;
  String? idTipoComprobante;
  double subtotal;
  double impuesto;
  String metodoPago;
  String registradoPor;
  String email;
  String nombreTipoUsuario;
  double total;

  Venta({
    required this.idVenta,
    required this.fecha,
    required this.nroComprobante,
    required this.nombreCliente,
    this.idTipoComprobante,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.metodoPago,
    required this.registradoPor,
    required this.email,
    required this.nombreTipoUsuario,
  });

  /// Crea una instancia de Venta desde un mapa JSON.
  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      idVenta: json['id_venta'] as int?,
      // Tu backend envía "2025-11-17 14:30:00"
      fecha: DateTime.parse(json['fecha'] as String),
      nroComprobante: json['numero_comprobante'] as String,
      nombreCliente: json['nombre_cliente'] as String,
      idTipoComprobante: json['id_tipo_comprobante']?.toString(),
      subtotal: double.parse(json['subtotal'].toString()),
      impuesto: double.parse(json['impuesto'].toString()),
      total: double.parse(json['total'].toString()),
      metodoPago: json['metodo_pago'] as String,
      registradoPor: json['registrado_por'] as String,
      email: json['email'] as String,
      nombreTipoUsuario: json['nombre_tipo_usuario'] as String,

    );
  }


}
