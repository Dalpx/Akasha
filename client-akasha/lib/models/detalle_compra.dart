class DetalleCompra {
  final int? idDetalleCompra;
  final int idProducto;
  final String? nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  // Solo para enviar al backend (no viene en el GET del detalle)
  final int? idUbicacion;

  DetalleCompra({
    this.idDetalleCompra,
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

  factory DetalleCompra.fromJson(Map<String, dynamic> json) {
    return DetalleCompra(
      idDetalleCompra: json['id_detalle_compra'] != null
          ? int.tryParse(json['id_detalle_compra'].toString())
          : null,
      idProducto: int.tryParse(json['id_producto'].toString()) ?? 0,
      nombreProducto: json['nombre_producto']?.toString(),
      cantidad: int.tryParse(json['cantidad'].toString()) ?? 0,
      precioUnitario: _toDouble(json['precio_unitario']),
      subtotal: _toDouble(json['subtotal']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      // el backend recalcula subtotal, pero lo enviamos igual
      'subtotal': subtotal,
      // CLAVE para el update de stock en compraController
      if (idUbicacion != null) 'id_ubicacion': idUbicacion,
    };
  }
}
