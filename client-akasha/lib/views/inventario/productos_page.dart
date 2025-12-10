import 'package:akasha/views/inventario/ubicaciones_productos_page.dart';
import 'package:akasha/widgets/producto/producto_detalles.dart';
import 'package:akasha/widgets/producto/producto_form_dialog.dart';
import 'package:akasha/widgets/producto/producto_list_item.dart';
import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../models/proveedor.dart';
import '../../models/categoria.dart';
import '../../services/inventario_service.dart';
import '../../services/proveedor_service.dart';
import '../../services/categoria_service.dart';
import '../../core/app_routes.dart';

/// Pantalla que muestra la lista de productos del inventario.
/// Desde aquí se pueden crear, editar y eliminar productos.
class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() {
    return _ProductosPageState();
  }
}

class _ProductosPageState extends State<ProductosPage> {
  // Servicio que maneja la lógica de inventario (lista de productos en memoria).
  final InventarioService _inventarioService = InventarioService();

  // Servicios para proveedores y categorías.
  final ProveedorService _proveedorService = ProveedorService();
  final CategoriaService _categoriaService = CategoriaService();

  // Future que se usa para construir la lista de productos con FutureBuilder.
  late Future<List<Producto>> _futureProductos;

  // Listas para los select boxes.
  List<Proveedor> _proveedores = <Proveedor>[];
  List<Categoria> _categorias = <Categoria>[];
  // List<Ubicacion> _ubicaciones = <Ubicacion>[];

  // Indica si todavía se están cargando proveedores y categorías.
  bool _cargandoCombos = true;

  @override
  void initState() {
    super.initState();
    _futureProductos = _inventarioService.obtenerProductos();
    _cargarProveedoresYCategorias();
  }

  /// Carga las listas de proveedores y categorías desde sus servicios.
  Future<void> _cargarProveedoresYCategorias() async {
    List<Proveedor> proveedores = await _proveedorService
        .obtenerProveedoresActivos();
    List<Categoria> categorias = await _categoriaService.obtenerCategorias();

    setState(() {
      _proveedores = proveedores;
      _categorias = categorias;
      _cargandoCombos = false;
    });
  }

  /// Recarga los productos desde el servicio y reconstruye el FutureBuilder.
  void _recargarProductos() {
    setState(() {
      _futureProductos = _inventarioService.obtenerProductos();
    });
  }

  /// Método unificado para crear o editar
  Future<void> _abrirFormularioProducto({Producto? productoEditar}) async {
    // 1. Asegurar que tenemos los combos cargados
    if (_cargandoCombos) {
      await _cargarProveedoresYCategorias();
    }

    // 2. Obtener lista actual para validación de SKU
    final productosActuales = await _inventarioService.obtenerProductos();

    if (!mounted) return;

    // 3. Mostrar el diálogo extraído
    final Producto? productoResultado = await showDialog<Producto>(
      context: context,
      builder: (context) => ProductoFormDialog(
        producto: productoEditar, // Si es null, el diálogo sabe que es "Nuevo"
        proveedores: _proveedores,
        categorias: _categorias,
        productosExistentes: productosActuales,
      ),
    );

    // 4. Si el usuario guardó (no es null), llamar al servicio
    if (productoResultado != null) {
      if (productoEditar == null) {
        // Lógica de CREAR
        await _inventarioService.crearProducto(productoResultado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto creado exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Lógica de EDITAR
        await _inventarioService.actualizarProducto(productoResultado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // 5. Recargar la lista
      _recargarProductos();
    }
  }

  void _mostrarDetallesDeProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return productoDetalles(producto: producto);
      },
    );
  }

  /// Muestra un modal para confirmar si realmente se desea eliminar el producto.
  void _confirmarEliminarProducto(Producto producto) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Seguro que deseas eliminar el producto "${producto.nombre}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Cierra el diálogo sin eliminar.
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (producto.idProducto != null) {
                  await _eliminarProducto(producto.idProducto!);
                  if (!mounted) {
                    return;
                  }

                  // Muestra un SnackBar de éxito (sin emoji)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Producto "${producto.nombre}" eliminado (desactivado).',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }

                if (!mounted) {
                  return;
                }

                // Cierra el diálogo después de eliminar.
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  /// Elimina (lógicamente) un producto llamando al servicio
  Future<void> _eliminarProducto(int idProducto) async {
    await _inventarioService.eliminarProducto(idProducto);
    _recargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Productos',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text("Gestión de productos"),
                    ],
                  ),
                ),
                // Botón para ir a la pantalla de gestión de proveedores y categorías
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.rutaGestionMaestros);
                    // Recargar combos por si se crearon nuevos proveedores/categorías
                    await _cargarProveedoresYCategorias();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Configuración'),
                ),
                const SizedBox(width: 8.0),
                // Botón para crear un nuevo producto
                ElevatedButton.icon(
                  onPressed: () {
                    _abrirFormularioProducto();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: FutureBuilder<List<Producto>>(
                    future: _futureProductos,
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<List<Producto>> snapshot,
                        ) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error al cargar productos: ${snapshot.error}',
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('No hay productos registrados.'),
                            );
                          }

                          List<Producto> productos = snapshot.data!
                              .where((producto) => producto.activo)
                              .toList();
                          return ListView.builder(
                            itemCount: productos.length,
                            itemBuilder: (BuildContext context, int index) {
                              final Producto producto = productos[index];

                              return ProductoListItem(
                                producto: producto,
                                inventarioService: _inventarioService,

                                // Acción 1: Ver Ubicaciones
                                onVerUbicaciones: () {
                                  if (producto.idProducto != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            UbicacionesProductoPage(
                                              producto: producto,
                                            ),
                                      ),
                                    );
                                  }
                                },

                                // Acción 2: Editar (Usando el método optimizado que creamos en el paso anterior)
                                onEditar: () {
                                  _abrirFormularioProducto(
                                    productoEditar: producto,
                                  );
                                },

                                // Acción 3: Eliminar
                                onEliminar: () {
                                  _confirmarEliminarProducto(producto);
                                },

                                // Acción 4: Ver Detalle (Opcional, si tienes una lógica para el "ojito")
                                onVerDetalle: () {
                                  // Aquí puedes poner un showDialog con detalles rápidos o navegar a detalle
                                  _mostrarDetallesDeProducto(producto);
                                },
                              );
                            },
                          );
                        },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extensión para simplificar la búsqueda de elementos iniciales en listas
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
