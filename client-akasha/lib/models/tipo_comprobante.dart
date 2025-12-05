class TipoComprobante {
  final int idTipoComprobante;
  final String nombre;

  const TipoComprobante({
    required this.idTipoComprobante,
    required this.nombre,
  });

  factory TipoComprobante.fromJson(Map<String, dynamic> json) {
    return TipoComprobante(
      idTipoComprobante: int.tryParse(
            (json['id_tipo_comprobante'] ?? json['id'] ?? '0').toString(),
          ) ??
          0,
      nombre: (json['nombre'] ?? '').toString(),
    );
  }
}
