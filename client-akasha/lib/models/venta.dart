/// Representa la cabecera de una venta o factura (lectura desde API).
class Venta {
  final int idVenta;
  final DateTime fecha;
  final String numeroComprobante;
  final String nombreCliente;
  final double subtotal;
  final double impuesto;
  final double total;
  final String metodoPago;
  final String registradoPor;
  final String email;
  final String nombreTipoUsuario;

  const Venta({
    required this.idVenta,
    required this.fecha,
    required this.numeroComprobante,
    required this.nombreCliente,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.metodoPago,
    required this.registradoPor,
    required this.email,
    required this.nombreTipoUsuario,
  });

  /// Permite que `fecha` llegue como "fecha" o "fecha_hora"
  static DateTime _parseFecha(Map<String, dynamic> json) {
    final raw = (json['fecha'] ?? json['fecha_hora'])?.toString();
    return raw != null && raw.isNotEmpty ? DateTime.parse(raw) : DateTime.now();
    // Si llegara en otro formato, ajusta aquí.
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }

  factory Venta.fromJson(Map<String, dynamic> json) {
    // Soporta "nro_comprobante" o "numero_comprobante"
    final nro =
        (json['numero_comprobante'] ?? json['nro_comprobante'])?.toString() ??
        '';
    return Venta(
      idVenta: int.tryParse(json['id_venta'].toString()) ?? 0,
      fecha: _parseFecha(json),
      numeroComprobante: nro,
      nombreCliente: (json['nombre_cliente'] ?? '').toString(),
      subtotal: _toDouble(json['subtotal']),
      impuesto: _toDouble(json['impuesto']),
      total: _toDouble(json['total']),
      metodoPago: (json['metodo_pago'] ?? '').toString(),
      registradoPor: (json['registrado_por'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nombreTipoUsuario: (json['nombre_tipo_usuario'] ?? '').toString(),
    );
  }
}

class VentaCreate {
  final int idCliente;
  final int idTipoComprobante; // tipo de comprobante / método de pago
  final String nroComprobante;
  final double subtotal;
  final double impuesto;
  final double total;
  final int idUsuario;

  VentaCreate({
    required this.idCliente,
    required this.idTipoComprobante,
    required this.nroComprobante,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.idUsuario,
  });

  Map<String, dynamic> toJson() => {
    'nro_comprobante': nroComprobante.toString(),
    'id_tipo_comprobante': idTipoComprobante.toString(),
    'id_cliente': idCliente.toString(),
    'id_usuario': idUsuario.toString(),
    'subtotal': subtotal.toString(),
    'impuesto': impuesto.toString(),
    'total': total.toString(),
    'estado': 1.toString(),
  };
}
