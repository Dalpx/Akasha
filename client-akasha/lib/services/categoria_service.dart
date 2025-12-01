import '../models/categoria.dart';

/// Servicio que maneja la obtención y gestión de categorías.
/// En esta versión, los datos se mantienen en memoria.
class CategoriaService {
  final List<Categoria> _categorias = <Categoria>[];

  CategoriaService() {
    // Datos de ejemplo para pruebas iniciales.
    _categorias.add(
      Categoria(
        idCategoria: 1,
        nombreCategoria: 'Herramientas',
      ),
    );
    _categorias.add(
      Categoria(
        idCategoria: 2,
        nombreCategoria: 'Construcción',
      ),
    );
    _categorias.add(
      Categoria(
        idCategoria: 3,
        nombreCategoria: 'Electricidad',
      ),
    );
  }

  /// Devuelve la lista completa de categorías.
  Future<List<Categoria>> obtenerCategorias() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _categorias;
  }

  /// Crea una nueva categoría y la agrega a la lista en memoria.
  Future<void> crearCategoria(Categoria categoria) async {
    await Future.delayed(const Duration(milliseconds: 200));

    int nuevoId = _categorias.length + 1;
    categoria.idCategoria = nuevoId;
    _categorias.add(categoria);
  }

  /// Actualiza los datos de una categoría existente.
  Future<void> actualizarCategoria(Categoria categoriaActualizada) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (int i = 0; i < _categorias.length; i++) {
      Categoria categoria = _categorias[i];
      if (categoria.idCategoria == categoriaActualizada.idCategoria) {
        _categorias[i] = categoriaActualizada;
      }
    }
  }

  /// Elimina una categoría de la lista (eliminación física en memoria).
  /// En una base de datos real, probablemente se haría eliminación lógica.
  Future<void> eliminarCategoria(int idCategoria) async {
    await Future.delayed(const Duration(milliseconds: 200));

    _categorias.removeWhere(
      (Categoria categoria) {
        return categoria.idCategoria == idCategoria;
      },
    );
  }
}
