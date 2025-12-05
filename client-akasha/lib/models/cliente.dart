/// Representa un cliente de la empresa.
class Cliente {
  int? idCliente;
  String nombre;
  String apellido;
  String tipoDocumento;
  String nroDocumento;
  String telefono;
  String? email;
  String? direccion;
  bool activo;

  Cliente({
    this.idCliente,
    required this.nombre,
    required this.apellido,
    required this.tipoDocumento,
    required this.nroDocumento,
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
      apellido: json['apellido'] as String,
      tipoDocumento: json['tipo_documento'] as String,
      nroDocumento: json['nro_documento'] as String,
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
      'apellido': apellido,
      "tipo_documento": tipoDocumento,
      "nro_documento": nroDocumento,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'activo': activo ? 1 : 0,
    };
  }
}
