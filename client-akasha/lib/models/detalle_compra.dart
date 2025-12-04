/// Representa una línea (detalle) dentro de una compra.
class DetalleCompra {
  int? idDetalleCompra;
  int? idCompra;          // puede venir o no en el JSON
  int idProducto;
  String nombreProducto;  // suele venir de un JOIN, por eso es “de vista”
  int cantidad;
  String precioUnitario;
  String subtotal;

  DetalleCompra({
    this.idDetalleCompra,
    this.idCompra,
    required this.idProducto,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  /// Para leer lo que devuelve el backend (SELECT con alias)
  factory DetalleCompra.fromJson(Map<String, dynamic> json) {
    return DetalleCompra(
      idDetalleCompra: json['id_detalle_compra'] != null
          ? int.tryParse(json['id_detalle_compra'].toString())
          : null,
      idCompra: json['id_compra'] != null
          ? int.tryParse(json['id_compra'].toString())
          : null,
      idProducto: int.tryParse(json['id_producto'].toString()) ?? 0,
      nombreProducto: (json['nombre_producto'] ?? '') as String,
      cantidad: int.tryParse(json['cantidad'].toString()) ?? 0,
      precioUnitario: json['precio_unitario'].toString(),
      subtotal: json['subtotal'].toString(),
    );
  }

  /// Para mandar/guardar un detalle de compra “completo”
  Map<String, dynamic> toJson() {
    return {
      'id_detalle_compra': idDetalleCompra,
      'id_compra': idCompra,
      'id_producto': idProducto,
      'nombre_producto': nombreProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }

  /// Para registrar detalle en el backend (INSERT),
  /// normalmente SIN id_detalle_compra ni id_compra (los gestiona el backend)
  Map<String, dynamic> toJsonRegistro() {
    return {
      'id_producto': idProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'id_ubicacion': 1
    };
  }
}
