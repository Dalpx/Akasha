/// Representa un registro de la tabla `usuario`.
class Usuario {
  int? idUsuario;
  String nombreUsuario;
  String? claveHash;
  String? nombreCompleto;
  String? email;
  String? tipoUsuario;
  bool? activo;

  Usuario({
    this.idUsuario,
    required this.nombreUsuario,
    this.claveHash,
    this.nombreCompleto,
    this.email,
    this.tipoUsuario,
    this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] as int?,
      nombreUsuario: json['nombre_usuario'] as String,
      nombreCompleto: json['nombre_completo'] as String?,
      email: json['email'] as String?,
      tipoUsuario: json['permiso'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_usuario': idUsuario,
      'usuario': nombreUsuario,
      'clave_hash': claveHash,
      'nombre_completo': nombreCompleto,
      'email': email,
      'id_tipo_usuario': tipoUsuario,
      'activo': activo == null ? null : (activo! ? 1 : 0),
    };
  }
}
