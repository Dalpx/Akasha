// lib/models/proveedor.dart

class Proveedor {
  final int idProveedor;
  final String nombre;
  final String canal;
  final String contacto;
  final String direccion;
  final int activo;

  Proveedor({
    required this.idProveedor,
    required this.nombre,
    required this.canal,
    required this.contacto,
    required this.direccion,
    required this.activo,
  });

  // Constructor desde JSON (respuesta del backend)
  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      idProveedor: json['id_proveedor'],
      nombre: json['nombre'],
      canal: json['canal'],
      contacto: json['contacto'],
      direccion: json['direccion'],
      activo: json['activo'],
    );
  }

  // Conversión a JSON (para enviar al backend)
  Map<String, dynamic> toJson(int caso) {

    //LEER
    if (caso == 0) {
      return {
        'id_prov': idProveedor,
        'nombre': nombre,
        'canal': canal,
        'contacto': contacto,
        'direccion': direccion,
        'activo': activo,
      };
    }
    //AGREGAR
    if (caso == 1) {
      return {
        'nom_prov': nombre,
        'canal': canal,
        'cont': contacto,
        'dir': direccion,
      };
    }
    //Editar
    if (caso == 2) {
      return {
        'nom_prov': nombre,
        'canal': canal,
        'cont': contacto,
        'dir': direccion,
        'id_prov': idProveedor
      };
    }

    return {
      'id_prov': idProveedor,
      'nombre': nombre,
      'canal': canal,
      'contacto': contacto,
      'direccion': direccion,
      'activo': activo,
    };
  }
}
