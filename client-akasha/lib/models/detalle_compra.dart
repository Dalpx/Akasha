/// Representa una línea (detalle) dentro de una compra.
/// Cada detalle indica cuántas unidades de un producto se compran
/// y a qué precio, en una ubicación específica de entrada.
class DetalleCompra {
  int? idDetalleCompra;
  int? idCompra;
  int idProducto;
  int cantidad;
  double precioUnitario;
  double subtotal;
  int? idUbicacion; // ubicación donde entra el stock

  DetalleCompra({
    this.idDetalleCompra,
    this.idCompra,
    required this.idProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.idUbicacion,
  });

  /// Crea una instancia de DetalleCompra desde un mapa JSON.
  factory DetalleCompra.fromJson(Map<String, dynamic> json) {
    return DetalleCompra(
      idDetalleCompra: json['id_detalle_compra'] as int?,
      idCompra: json['id_compra'] as int?,
      idProducto: json['id_producto'] as int,
      cantidad: json['cantidad'] as int,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      idUbicacion: json['id_ubicacion'] as int?,
    );
  }

  /// Convierte el objeto DetalleCompra a un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_detalle_compra': idDetalleCompra,
      'id_compra': idCompra,
      'id_producto': idProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'id_ubicacion': idUbicacion,
    };
  }
}
