/// Representa una ubicación física en el almacén,
/// por ejemplo: "Depósito A - Estante 3 - Nivel 2".
class Ubicacion {
  int? idUbicacion;
  String nombreAlmacen;
  String? descripcion;
  bool activa;

  Ubicacion({
    this.idUbicacion,
    required this.nombreAlmacen,
    this.descripcion,
    required this.activa,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      idUbicacion: json['id_ubicacion'] as int?,
      nombreAlmacen: json['nombre_almacen'] as String,
      descripcion: json['descripcion'] as String?,
      activa: (json['activo'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_ubicacion': idUbicacion,
      'nombre_almacen': nombreAlmacen,
      'descripcion': descripcion,
      'activo': activa ? 1 : 0,
    };
  }
}
