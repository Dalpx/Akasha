import '../models/ubicacion.dart';

/// Servicio que gestiona el catálogo de ubicaciones del almacén.
/// Implementado como singleton para que toda la app comparta
/// la misma lista en memoria.
class UbicacionService {
  // Instancia única (singleton).
  static final UbicacionService _instancia = UbicacionService._internal();

  // Lista interna de ubicaciones.
  final List<Ubicacion> _ubicaciones = <Ubicacion>[];

  /// Constructor "factory" que siempre devuelve la misma instancia.
  factory UbicacionService() {
    return _instancia;
  }

  /// Constructor privado donde se inicializan los datos de ejemplo.
  UbicacionService._internal() {
    if (_ubicaciones.isEmpty) {
      _ubicaciones.add(
        Ubicacion(
          idUbicacion: 1,
          nombre: 'Depósito A - Estante 1',
          descripcion: 'Zona principal de almacenaje',
          activa: true,
        ),
      );
      _ubicaciones.add(
        Ubicacion(
          idUbicacion: 2,
          nombre: 'Depósito A - Estante 2',
          descripcion: 'Estante secundario',
          activa: true,
        ),
      );
    }
  }

  /// Obtiene todas las ubicaciones activas.
  Future<List<Ubicacion>> obtenerUbicacionesActivas() async {
    await Future.delayed(const Duration(milliseconds: 200));

    List<Ubicacion> activas = <Ubicacion>[];

    for (int i = 0; i < _ubicaciones.length; i++) {
      Ubicacion u = _ubicaciones[i];
      if (u.activa) {
        activas.add(u);
      }
    }

    return activas;
  }

  /// Crea una nueva ubicación.
  Future<Ubicacion> crearUbicacion(Ubicacion ubicacion) async {
    await Future.delayed(const Duration(milliseconds: 200));

    int nuevoId = _ubicaciones.length + 1;
    ubicacion.idUbicacion = nuevoId;
    _ubicaciones.add(ubicacion);
    return ubicacion;
  }

  /// Actualiza una ubicación existente.
  Future<void> actualizarUbicacion(Ubicacion ubicacionActualizada) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (int i = 0; i < _ubicaciones.length; i++) {
      Ubicacion u = _ubicaciones[i];
      if (u.idUbicacion == ubicacionActualizada.idUbicacion) {
        _ubicaciones[i] = ubicacionActualizada;
      }
    }
  }

  /// Elimina lógicamente una ubicación (la marca como inactiva).
  Future<void> eliminarUbicacion(int idUbicacion) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (int i = 0; i < _ubicaciones.length; i++) {
      Ubicacion u = _ubicaciones[i];
      if (u.idUbicacion == idUbicacion) {
        u.activa = false;
      }
    }
  }
}
