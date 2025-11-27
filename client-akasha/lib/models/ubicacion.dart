/// Representa una ubicación física en el almacén,
/// por ejemplo: "Depósito A - Estante 3 - Nivel 2".
class Ubicacion {
  int? idUbicacion;
  String nombre;
  String? descripcion;
  bool activa;

  Ubicacion({
    this.idUbicacion,
    required this.nombre,
    this.descripcion,
    required this.activa,
  });

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    return Ubicacion(
      idUbicacion: json['id_ubicacion'] as int?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      activa: (json['activa'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_ubicacion': idUbicacion,
      'nombre': nombre,
      'descripcion': descripcion,
      'activa': activa ? 1 : 0,
    };
  }
}
