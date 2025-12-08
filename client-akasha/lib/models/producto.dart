import 'package:akasha/models/ubicacion.dart';

/// Representa un registro de la tabla `producto` de la base de datos.
/// En este ejemplo incluimos un campo `stock` para manejar las existencias
/// directamente desde el modelo.
class Producto {
  int? idProducto;
  String nombre;
  String sku;
  String descripcion;
  double precioCosto;
  double precioVenta;

  String? idProveedor;
  String? idCategoria;

  bool activo;

  Producto({
    this.idProducto,
    required this.nombre,
    required this.sku,
    required this.descripcion,
    required this.precioCosto,
    required this.precioVenta,

    this.idProveedor,
    this.idCategoria,
    required this.activo,
  });

  /// Crea una instancia de Producto desde un mapa JSON.
  /// En un sistema real, `stock` podría venir de otra tabla (stock),
  /// pero aquí lo simplificamos como un campo más.
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idProducto: json['id_producto'] as int?,
      nombre: json['nombre'] as String,
      sku: json['sku'] as String,
      descripcion: json['descripcion'] as String,
      precioCosto: json['precio_costo'] as double,
      precioVenta: json['precio_venta'] as double,
      idProveedor: json['nombre_proveedor'] as String?,
      idCategoria: json['categoria'] as String?,
      activo: (json['activo'] as int) == 1,
    );
  }

  /// Convierte el objeto Producto a mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id_producto': idProducto,
      'nombre': nombre,
      'sku': sku,
      'descripcion': descripcion,
      'precio_costo': precioCosto,
      'precio_venta': precioVenta,
      'id_proveedor': idProveedor,
      'id_categoria': idCategoria,
      'activo': activo ? 1 : 0,
    };
  }
}
