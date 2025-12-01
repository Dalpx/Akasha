/// Representa la cabecera de una venta o factura.
class Venta {
  int? idVenta;
  int idCliente;
  DateTime fecha;
  double total;
  String numeroFactura;

  Venta({
    this.idVenta,
    required this.idCliente,
    required this.fecha,
    required this.total,
    required this.numeroFactura,
  });

  /// Crea una instancia de Venta desde un mapa JSON.
  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      idVenta: json['id_venta'] as int?,
      idCliente: json['id_cliente'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      total: (json['total'] as num).toDouble(),
      numeroFactura: json['numero_factura'] as String,
    );
  }

  /// Convierte el objeto Venta a un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_venta': idVenta,
      'id_cliente': idCliente,
      'fecha': fecha.toIso8601String(),
      'total': total,
      'numero_factura': numeroFactura,
    };
  }
}
