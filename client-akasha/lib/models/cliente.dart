/// Representa un cliente de la empresa.
class Cliente {
  int? idCliente;
  String nombre;
  String telefono;
  String? email;
  String? direccion;
  bool activo;

  Cliente({
    this.idCliente,
    required this.nombre,
    required this.telefono,
    this.email,
    this.direccion,
    required this.activo,
  });

  /// Crea una instancia de Cliente a partir de un mapa JSON.
  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      idCliente: json['id_cliente'] as int?,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String,
      email: json['email'] as String?,
      direccion: json['direccion'] as String?,
      activo: (json['activo'] as int) == 1,
    );
  }

  /// Convierte el objeto Cliente a un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_cliente': idCliente,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'activo': activo ? 1 : 0,
    };
  }
}
