/// Representa un movimiento aislado de inventario (ajuste),
/// que puede ser una ENTRADA o una SALIDA.
class MovimientoInventario {
  int? idMovimiento;
  int idProducto;
  int? idUbicacion;
  DateTime fecha;
  int cantidad;
  String tipo; // 'ENTRADA' o 'SALIDA'
  String descripcion;

  MovimientoInventario({
    this.idMovimiento,
    required this.idProducto,
    this.idUbicacion,
    required this.fecha,
    required this.cantidad,
    required this.tipo,
    required this.descripcion,
  });

  /// Crea una instancia de MovimientoInventario desde un mapa JSON.
  factory MovimientoInventario.fromJson(Map<String, dynamic> json) {
    return MovimientoInventario(
      idMovimiento: json['id_movimiento'] as int?,
      idProducto: json['id_producto'] as int,
      idUbicacion: json['id_ubicacion'] as int?,
      fecha: DateTime.parse(json['fecha'] as String),
      cantidad: json['cantidad'] as int,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
    );
  }

  /// Convierte el objeto MovimientoInventario a un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_movimiento': idMovimiento,
      'id_producto': idProducto,
      'id_ubicacion': idUbicacion,
      'fecha': fecha.toIso8601String(),
      'cantidad': cantidad,
      'tipo': tipo,
      'descripcion': descripcion,
    };
  }
}
