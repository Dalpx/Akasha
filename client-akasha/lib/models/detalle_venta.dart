/// Representa una línea (detalle) dentro de una venta o factura.
class DetalleVenta {
  int? idDetalleVenta;
  int idProducto;
  String nombreProducto;
  int cantidad;
  String precioUnitario;
  String subtotal;
  String? idUbicacion; // ubicación desde donde sale el producto

  DetalleVenta({
    required this.idDetalleVenta,
    required this.idProducto,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    // required this.idUbicacion,
  });

  /// Crea una instancia de DetalleVenta desde un mapa JSON.
  factory DetalleVenta.fromJson(Map<String, dynamic> json) {
    return DetalleVenta(
      idDetalleVenta:  json['id_detalle_venta'] as int,
      idProducto: json['id_producto'] as int,
      nombreProducto: json['nombre_producto'] as String,
      cantidad: json['cantidad'] as int,
      precioUnitario: (json['precio_unitario'] as String),
      subtotal: (json['subtotal'] as String),
      // idUbicacion: json['id_ubicacion'] as String,
    );
  }

  /// Convierte el objeto DetalleVenta a un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_producto': idProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      // 'id_ubicacion': idUbicacion,
      'id_ubicacion': 1,
    };
  }
}
