// ignore_for_file: public_member_api_docs, sort_constructors_first
class Producto {
  int idProducto;
  String nombre;
  String sku;
  String descripcion;
  double precioCosto;
  double precioVenta;
  int idProveedor;
  int activo;

  Producto({
    required this.idProducto,
    required this.nombre,
    required this.sku,
    required this.descripcion,
    required this.precioCosto,
    required this.precioVenta,
    required this.idProveedor,
    required this.activo,
  });

  //Metodos
  // Factory constructor para crear un objeto Producto a partir de un Map (JSON)
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idProducto: json['id_producto'],
      nombre: json['nombre'],
      sku: json['sku'] as String,
      descripcion: json['descripcion'] as String,
      precioCosto: json['precio_costo'] as double,
      precioVenta: json['precio_venta'] as double,
      idProveedor: json['id_prov'],
      activo: json['activo']
    );
  }

  // **MÉTODO toJson()**
  Map<String, dynamic> toJson(int caso) {
    //AGREGAR
    if (caso == 0) {
      return {
        'nom_prod': nombre,
        'sku_prod': sku,
        'desc_prod': descripcion,
        // Asegúrate de que las claves coincidan exactamente con lo que espera tu API
        'pre_cost': precioCosto,
        'pre_vent': precioVenta,
        'id_prov': idProveedor,
      };
    }
    //EDITAR
    if (caso == 1) {
      return {
        'nom_prod': nombre,
        'sku_prod': sku,
        'desc_prod': descripcion,
        // Asegúrate de que las claves coincidan exactamente con lo que espera tu API
        'pre_cost': precioCosto,
        'pre_vent': precioVenta,
        'id_prod': idProducto,
      };
    } else {
      return {
        'id_prod': idProducto,
      };
    }
  }



  @override
  String toString() {
    return 'Producto(idProducto: $idProducto, nombre: $nombre, sku: $sku, descripcion: $descripcion, precioCosto: $precioCosto, precioVenta: $precioVenta, idProveedor: $idProveedor, activo: $activo)';
  }
}
