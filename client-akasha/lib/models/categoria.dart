/// Representa un registro de la tabla `categoria` de la base de datos.
class Categoria {
  int? idCategoria;
  String nombreCategoria;
  bool activo;

  Categoria({
    this.idCategoria,
    required this.nombreCategoria,
    required this.activo,
  });

  /// Crea una instancia de Categoria a partir de un mapa JSON.
  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      idCategoria: json['id_categoria'] as int?,
      nombreCategoria: json['nombre_categoria'] as String,
      activo: (json['activo'] as int) == 1
    );
  }

  /// Convierte el objeto Categoria a un mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_categoria': idCategoria,
      'nombre_categoria': nombreCategoria,
      'activo': activo ? 1 : 0
    };
  }
}
