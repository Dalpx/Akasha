/// Representa una línea de detalle en una venta.
class DetalleVenta {
  final int? idDetalleVenta;
  final int idProducto;
  final String? nombreProducto; // opcional en creación
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final int? idUbicacion;

  DetalleVenta({
    this.idDetalleVenta,
    required this.idProducto,
    this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.idUbicacion,
  });

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }

  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
  return DetalleVenta(
    idDetalleVenta: json['id_detalle_venta'] != null
        ? int.tryParse(json['id_detalle_venta'].toString())
        : null,
    idProducto: int.tryParse(json['id_producto'].toString()) ?? 0,
    nombreProducto: json['nombre_producto']?.toString(), 
    cantidad: int.tryParse(json['cantidad'].toString()) ?? 0,
    precioUnitario: _toDouble(json['precio_unitario']),
    subtotal: _toDouble(json['subtotal']),
    idUbicacion: json['id_ubicacion'] != null
        ? int.tryParse(json['id_ubicacion'].toString())
        : null,
  );
}


  /// Lo que espera el controller al registrar (POST).
  Map<String, dynamic> toJson() => {
    'id_producto': idProducto.toString(),
    'cantidad': cantidad.toString(),
    'precio_unitario': precioUnitario.toString(),
    'subtotal': subtotal.toString(),
    if (idUbicacion != null) 'id_ubicacion': idUbicacion.toString(),
  };

  @override
  String toString() {
    return 'DetalleVenta {'
        '\n  idDetalleVenta: $idDetalleVenta,'
        '\n  idProducto: $idProducto,'
        '\n  nombreProducto: $nombreProducto,'
        '\n  cantidad: $cantidad,'
        '\n  precioUnitario: ${precioUnitario.toStringAsFixed(2)},'
        '\n  subtotal: ${subtotal.toStringAsFixed(2)},'
        '\n  idUbicacion: $idUbicacion'
        '\n}';
  }
}
