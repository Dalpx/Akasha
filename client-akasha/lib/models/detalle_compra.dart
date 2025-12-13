class DetalleCompra {
  final int? idDetalleCompra;
  final int idProducto;
  final String? nombreProducto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  
  // Agregado para mostrar en la factura (backend debe enviar 'nombre_almacen')
  final String? nombreAlmacen; 

  // Solo para enviar al backend (update de stock)
  final int? idUbicacion;

  DetalleCompra({
    this.idDetalleCompra,
    required this.idProducto,
    this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.nombreAlmacen,
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
      nombreProducto: json['nombre_producto']?.toString(), // Ojo: tu backend debe enviar este JOIN
      cantidad: int.tryParse(json['cantidad'].toString()) ?? 0,
      precioUnitario: _toDouble(json['precio_unitario']),
      subtotal: _toDouble(json['subtotal']),
      
      // Agregamos la lectura del almacén si viene del backend
      nombreAlmacen: json['nombre_almacen']?.toString(), 
      
      // Intentamos leer id_ubicacion por si acaso viene en el GET, aunque sea opcional
      idUbicacion: json['id_ubicacion'] != null 
          ? int.tryParse(json['id_ubicacion'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_producto': idProducto,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
      'id_ubicacion': idUbicacion,
    };
  }
}