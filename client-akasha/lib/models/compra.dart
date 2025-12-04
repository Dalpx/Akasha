class Compra {
  int? idCompra;
  String fecha;                // viene como 'fecha' o 'fecha_hora'
  String numeroComprobante;
  int idTipoComprobante;
  int idProveedor;
  int idUsuario;
  String subtotal;
  String impuesto;
  String total;
  int estado;

  // Campos extra que suelen venir del JOIN (opcionales)
  String? nombreProveedor;
  String? registradoPor;
  String? emailUsuario;
  String? nombreTipoUsuario;

  Compra({
    this.idCompra,
    required this.fecha,
    required this.numeroComprobante,
    required this.idTipoComprobante,
    required this.idProveedor,
    required this.idUsuario,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.estado,
    this.nombreProveedor,
    this.registradoPor,
    this.emailUsuario,
    this.nombreTipoUsuario,
  });

  /// Para leer lo que devuelve el backend (SELECT con alias)
  factory Compra.fromJson(Map<String, dynamic> json) {
    return Compra(
      idCompra: json['id_compra'] as int?,
      fecha: (json['fecha'] ?? json['fecha_hora'] ?? '') as String,
      numeroComprobante:
          (json['numero_comprobante'] ?? json['nro_comprobante'] ?? '') as String,
      idTipoComprobante:
          int.tryParse(json['id_tipo_comprobante'].toString()) ?? 0,
      idProveedor: int.tryParse(json['id_proveedor'].toString()) ?? 0,
      idUsuario: int.tryParse(json['id_usuario'].toString()) ?? 0,
      subtotal: json['subtotal'].toString(),
      impuesto: json['impuesto'].toString(),
      total: json['total'].toString(),
      estado: json['estado'] != null
          ? int.tryParse(json['estado'].toString()) ?? 0
          : 0,

      // Opcionales (dependen de tu SELECT)
      nombreProveedor: json['nombre_proveedor'],
      registradoPor: json['registrado_por'],
      emailUsuario: json['email'],
      nombreTipoUsuario: json['nombre_tipo_usuario'],
    );
  }

  /// Para mandar una compra al front / guardar en cache (forma “completa”)
  Map<String, dynamic> toJson() {
    return {
      'id_compra': idCompra,
      'fecha': fecha,
      'numero_comprobante': numeroComprobante,
      'id_cliente': 1,
      'id_tipo_comprobante': idTipoComprobante,
      'id_proveedor': idProveedor,
      'id_usuario': idUsuario,
      'subtotal': subtotal,
      'impuesto': impuesto,
      'total': total,
      'estado': estado,
      if (nombreProveedor != null) 'nombre_proveedor': nombreProveedor,
      if (registradoPor != null) 'registrado_por': registradoPor,
      if (emailUsuario != null) 'email': emailUsuario,
      if (nombreTipoUsuario != null)
        'nombre_tipo_usuario': nombreTipoUsuario,
    };
  }

  /// Para registrar compra en el backend (INSERT), sin id_compra ni fecha
  Map<String, dynamic> toJsonRegistro() {
    return {
      'nro_comprobante': numeroComprobante,
      'id_tipo_comprobante': 1,
      'id_proveedor': idProveedor,
      'id_usuario': idUsuario,
      'subtotal': subtotal,
      'impuesto': impuesto,
      'total': total,
      'estado': estado,
    };
  }
}
