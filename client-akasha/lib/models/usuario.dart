// ignore_for_file: public_member_api_docs, sort_constructors_first
class Usuario {
  final int? idUsuario;
  final String username;
  final String nombreCompleto;
  final String email;
  final String permiso; // super, admin, almacen
  final int activo;
  final String? password; // Solo se usa al crear/editar

  Usuario({
    this.idUsuario,
    required this.username,
    required this.nombreCompleto,
    required this.email,
    required this.permiso,
    this.activo = 1,
    this.password,
  });

  // Desde la respuesta de la API
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'] as int?,
      username: (json['nombre_usuario'] ?? '') as String,
      nombreCompleto: (json['nombre_completo'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      permiso: (json['permiso'] ?? '') as String,
      activo: json['activo'] is int
          ? json['activo'] as int
          : int.tryParse('${json['activo'] ?? 1}') ?? 1,
    );
  }

  // Mapeo del texto de rol al id_tipo_usuario (tabla tipo_usuario)
  int get tipoUsuarioId {
    switch (permiso.toLowerCase()) {
      case 'super':
        return 1;
      case 'admin':
        return 2;
      case 'almacen':
        return 3;
      default:
        return 3;
    }
  }

  /// caso:
  /// 0 -> crear
  /// 1 -> editar
  /// 2 -> eliminar (baja lógica)
  Map<String, dynamic> toJson(int caso) {
    switch (caso) {
      // CREATE
      case 0:
        return {
          'user': username,
          'pass': password ?? '',
          'nom_c': nombreCompleto,
          'email': email,
          'tu': tipoUsuarioId,
        };

      // UPDATE
      case 1:
        return {
          'id_user': idUsuario,
          'user': username,
          'pass': password ?? '',
          'nom_c': nombreCompleto,
          'email': email,
        };

      // DELETE (baja lógica)
      case 2:
        return {
          'id_user': idUsuario,
        };

      default:
        return {};
    }
  }

  @override
  String toString() {
    return 'Usuario(idUsuario: $idUsuario, username: $username, nombreCompleto: $nombreCompleto, email: $email, permiso: $permiso, activo: $activo, password: $password)';
  }
}
