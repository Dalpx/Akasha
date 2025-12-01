/// Representa la cabecera de una compra a un proveedor.
class Compra {
  int? idCompra;
  int idProveedor;
  DateTime fecha;
  double total;
  String numeroDocumento;

  Compra({
    this.idCompra,
    required this.idProveedor,
    required this.fecha,
    required this.total,
    required this.numeroDocumento,
  });

  /// Crea una instancia de Compra desde un mapa JSON.
  factory Compra.fromJson(Map<String, dynamic> json) {
    return Compra(
      idCompra: json['id_compra'] as int?,
      idProveedor: json['id_proveedor'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      total: (json['total'] as num).toDouble(),
      numeroDocumento: json['numero_documento'] as String,
    );
  }

  /// Convierte el objeto Compra a un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_compra': idCompra,
      'id_proveedor': idProveedor,
      'fecha': fecha.toIso8601String(),
      'total': total,
      'numero_documento': numeroDocumento,
    };
  }
}
