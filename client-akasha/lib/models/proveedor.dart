/// Representa un registro de la tabla `proveedor` de la base de datos.
class Proveedor {
  int? idProveedor;
  String nombre;
  String telefono;
  String? correo;
  String? direccion;
  bool activo;

  Proveedor({
    this.idProveedor,
    required this.nombre,
    required this.telefono,
    this.correo,
    this.direccion,
    required this.activo,
  });

  /// Crea una instancia de Proveedor a partir de un mapa JSON.
  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      idProveedor: json['id_proveedor'] as int?,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      correo: json['correo'] as String?,
      direccion: json['direccion'] as String?,
      activo: (json['activo'] as int) == 1,
    );
  }

  /// Convierte el objeto Proveedor a un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_proveedor': idProveedor,
      'nombre': nombre,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'activo': activo ? 1 : 0,
    };
  }
}
