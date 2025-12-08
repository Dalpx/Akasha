class MovimientoInventario {
  final int idMovimiento;
  final String tipoMovimiento; // 'entrada' | 'salida' (viene del GET)
  final int cantidad;
  final String fecha;
  final String descripcion;
  final String? nombreProducto;
  final String? nombreUsuario;
  final String? nombreProveedor;

  MovimientoInventario({
    required this.idMovimiento,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.fecha,
    required this.descripcion,
    this.nombreProducto,
    this.nombreUsuario,
    this.nombreProveedor,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    return MovimientoInventario(
      idMovimiento: int.tryParse(json['id_movimiento'].toString()) ?? 0,
      tipoMovimiento: json['tipo_movimiento']?.toString() ?? '',
      cantidad: int.tryParse(json['cantidad'].toString()) ?? 0,
      fecha: json['fecha']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      nombreProducto: json['nombre_producto']?.toString(),
      nombreUsuario: json['nombre_usuario']?.toString(),
      nombreProveedor: json['nombre_proveedor']?.toString(),
    );
  }
}

/// DTO para POST
class MovimientoCreate {
  final int tipoMovimiento; // 1 = entrada, 0 = salida
  final int cantidad;
  final String descripcion;
  final int idProducto;
  final int idUsuario;

  /// OBLIGATORIO para actualizar stock
  final int idUbicacion;

  MovimientoCreate({
    required this.tipoMovimiento,
    required this.cantidad,
    required this.descripcion,
    required this.idProducto,
    required this.idUsuario,
    required this.idUbicacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo_movimiento': tipoMovimiento,
      'cantidad': cantidad,
      'descripcion': descripcion,
      'id_producto': idProducto,
      'id_usuario': idUsuario,
      'id_ubicacion': idUbicacion,
    };
  }
}
