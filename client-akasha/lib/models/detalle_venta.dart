/// Representa una línea (detalle) dentro de una venta o factura.
class DetalleVenta {
  int? idDetalleVenta;
  int? idVenta;
  int idProducto;
  int cantidad;
  double precioUnitario;
  double subtotal;
  int? idUbicacion; // ubicación desde donde sale el producto

  DetalleVenta({
    this.idDetalleVenta,
    this.idVenta,
    required this.idProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.idUbicacion,
  });

  /// Crea una instancia de DetalleVenta desde un mapa JSON.
  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      idDetalleVenta: json['id_detalle_venta'] as int?,
      idVenta: json['id_venta'] as int?,
      idProducto: json['id_producto'] as int,
      cantidad: json['cantidad'] as int,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      idUbicacion: json['id_ubicacion'] as int?,
    );
  }

  /// Convierte el objeto DetalleVenta a un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_detalle_venta': idDetalleVenta,
      'id_venta': idVenta,
      'id_producto': idProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'id_ubicacion': idUbicacion,
    };
  }
}
