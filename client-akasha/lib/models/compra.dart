import 'detalle_compra.dart';

class Compra {
  final int idCompra;
  final String fechaHora;
  final String nroComprobante;
  final double subtotal;
  final double impuesto;
  final double total;

  final String tipoPago;
  final String proveedor;
  final String hechoPor;
  final String email;
  final String nombreTipoUsuario;

  final List<DetalleCompra> detalleCompra;

  Compra({
    required this.idCompra,
    required this.fechaHora,
    required this.nroComprobante,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.tipoPago,
    required this.proveedor,
    required this.hechoPor,
    required this.email,
    required this.nombreTipoUsuario,
    required this.detalleCompra,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }

  factory Compra.fromJson(Map<String, dynamic> json) {
    final rawDetalle = json['detalle_compra'];
    final detalles = (rawDetalle is List)
        ? rawDetalle
            .map((e) => DetalleCompra.fromJson(e as Map<String, dynamic>))
            .toList()
        : <DetalleCompra>[];

    return Compra(
      idCompra: int.tryParse(json['id_compra'].toString()) ?? 0,
      fechaHora: json['fecha_hora']?.toString() ?? '',
      nroComprobante: json['nro_comprobante']?.toString() ?? '',
      subtotal: _toDouble(json['subtotal']),
      impuesto: _toDouble(json['impuesto']),
      total: _toDouble(json['total']),
      tipoPago: json['tipo_pago']?.toString() ?? '',
      proveedor: json['proveedor']?.toString() ?? '',
      hechoPor: json['hecho_por']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nombreTipoUsuario: json['nombre_tipo_usuario']?.toString() ?? '',
      detalleCompra: detalles,
    );
  }
}

/// DTO para POST
class CompraCreate {
  final String nroComprobante;
  final int idTipoComprobante;
  final int idProveedor;
  final int idUsuario;
  final double subtotal;
  final double impuesto;
  final double total;
  final int estado;

  CompraCreate({
    required this.nroComprobante,
    required this.idTipoComprobante,
    required this.idProveedor,
    required this.idUsuario,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.estado,
  });

  Map<String, dynamic> toJson() {
    return {
      'nro_comprobante': nroComprobante,
      'id_tipo_comprobante': idTipoComprobante,
      'id_proveedor': idProveedor,
      'id_usuario': idUsuario,
      'subtotal': subtotal,
      'impuesto': impuesto,
      'total': total,
      'estado': estado,
    };
  }
}
