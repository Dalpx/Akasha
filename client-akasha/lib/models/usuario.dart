/// Representa un registro de la tabla `usuario`.
class Usuario {
  int? idUsuario;
  String nombreUsuario;
  String? claveHash;
  String? nombreCompleto;
  String? email;
  String? tipoUsuario;
  bool activo;

  Usuario({
    this.idUsuario,
    required this.nombreUsuario,
    this.claveHash,
    this.nombreCompleto,
    this.email,
    this.tipoUsuario,
    required this.activo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] as int?,
      nombreUsuario: json['nombre_usuario'] as String,
      nombreCompleto: json['nombre_completo'] as String?,
      email: json['email'] as String?,
      tipoUsuario: json['permiso'] as String?,
      activo: (json['activo'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_usuario': idUsuario,
      'usuario': nombreUsuario,
      'clave_hash': claveHash,
      'nombre_completo': nombreCompleto,
      'email': email,
      'id_tipo_usuario': int.parse(tipoUsuario!),
      'activo': activo ? 1 : 0,
    };
  }

  // Implementación del método toString()
  @override
  String toString() {
    return 'Usuario(\n'
        '  idUsuario: $idUsuario,\n'
        '  nombreUsuario: $nombreUsuario,\n'
        '  nombreCompleto: $nombreCompleto,\n'
        '  email: $email,\n'
        '  tipoUsuario: $tipoUsuario,\n'
        '  activo: $activo\n'
        ')';
  }
}
