/// Representa el stock de un producto en una ubicación específica.
class StockUbicacion {
  // int? idStockUbicacion;
  int? idProducto;
  String idUbicacion;
  int cantidad;

  StockUbicacion({
    // this.idStockUbicacion,
    this.idProducto,
    required this.idUbicacion,
    required this.cantidad,
  });

  factory StockUbicacion.fromJson(Map<String, dynamic> json) {
    return StockUbicacion(
      // idStockUbicacion: json['id_stock_ubicacion'] as int?,
      idProducto: json['id_producto'] as int,
      idUbicacion: json['nombre_almacen'] as String,
      cantidad: json['stock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      // 'id_stock_ubicacion': idStockUbicacion,
      'id_producto': idProducto,
      'id_ubicacion': idUbicacion,
      // 'cantidad': cantidad,
    };
  }

  // 💡 Implementación del método toString()
  @override
  String toString() {
    return 'StockUbicacion('
        'Producto ID: $idProducto, '
        'Ubicación: $idUbicacion, '
        'Cantidad: $cantidad'
        ')';
  }
}
