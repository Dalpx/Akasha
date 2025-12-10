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

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() {
    return _ProductosPageState();
  }
}

class _ProductosPageState extends State<ProductosPage> {
  final InventarioService _inventarioService = InventarioService();
  final ProveedorService _proveedorService = ProveedorService();
  final CategoriaService _categoriaService = CategoriaService();

  late Future<List<Producto>> _futureProductos;

  List<Proveedor> _proveedores = <Proveedor>[];
  List<Categoria> _categorias = <Categoria>[];

  List<Producto>? _cacheProductos;
  List<Proveedor>? _cacheProveedores;
  List<Categoria>? _cacheCategorias;

  bool _cargandoCombos = true;

  @override
  void initState() {
    super.initState();
    _futureProductos = _loadProductos();
    _cargarProveedoresYCategorias();
  }

  Future<List<Producto>> _loadProductos({bool force = false}) async {
    if (!force && _cacheProductos != null) {
      return _cacheProductos!;
    }

    final list = await _inventarioService.obtenerProductos();
    _cacheProductos = list;
    return list;
  }

  Future<List<Proveedor>> _loadProveedores({bool force = false}) async {
    if (!force && _cacheProveedores != null) {
      return _cacheProveedores!;
    }

    final list = await _proveedorService.obtenerProveedoresActivos();
    _cacheProveedores = list;
    return list;
  }

  Future<List<Categoria>> _loadCategorias({bool force = false}) async {
    if (!force && _cacheCategorias != null) {
      return _cacheCategorias!;
    }

    final list = await _categoriaService.obtenerCategorias();
    _cacheCategorias = list;
    return list;
  }

  Future<void> _cargarProveedoresYCategorias({bool force = false}) async {
    _cargandoCombos = true;

    final proveedores = await _loadProveedores(force: force);
    final categorias = await _loadCategorias(force: force);

    if (!mounted) return;

    setState(() {
      _proveedores = proveedores;
      _categorias = categorias;
      _cargandoCombos = false;
    });
  }

  void _recargarProductos() {
    if (!mounted) return;
    setState(() {
      _futureProductos = _loadProductos(force: true);
    });
  }

  Future<void> _abrirFormularioProducto({Producto? productoEditar}) async {
    if (_cargandoCombos) {
      await _cargarProveedoresYCategorias();
    }

    final productosActuales = await _loadProductos();

    if (!mounted) return;

    final Producto? productoResultado = await showDialog<Producto>(
      context: context,
      builder: (context) => ProductoFormDialog(
        producto: productoEditar,
        proveedores: _proveedores,
        categorias: _categorias,
        productosExistentes: productosActuales,
      ),
    );

    if (productoResultado != null) {
      if (productoEditar == null) {
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

      _cacheProductos = null;
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
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (producto.idProducto != null) {
                  await _eliminarProducto(producto.idProducto!);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Producto "${producto.nombre}" eliminado (desactivado).',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }

                if (!mounted) return;

                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarProducto(int idProducto) async {
    await _inventarioService.eliminarProducto(idProducto);
    _cacheProductos = null;
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
                      const Text("Gestión de productos"),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context)
                        .pushNamed(AppRoutes.rutaGestionMaestros);

                    await _cargarProveedoresYCategorias(force: true);
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Configuración'),
                ),
                const SizedBox(width: 8.0),
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
                    initialData: _cacheProductos,
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<Producto>> snapshot,
                    ) {
                      final data = snapshot.data ?? const <Producto>[];

                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          data.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError && data.isEmpty) {
                        return Center(
                          child: Text(
                            'Error al cargar productos: ${snapshot.error}',
                          ),
                        );
                      }

                      final productos = data
                          .where((producto) => producto.activo)
                          .toList();

                      if (productos.isEmpty) {
                        return const Center(
                          child: Text('No hay productos registrados.'),
                        );
                      }

                      return ListView.builder(
                        key: const PageStorageKey('productos_list'),
                        itemCount: productos.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Producto producto = productos[index];

                          return ProductoListItem(
                            producto: producto,
                            inventarioService: _inventarioService,
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
                            onEditar: () {
                              _abrirFormularioProducto(
                                productoEditar: producto,
                              );
                            },
                            onEliminar: () {
                              _confirmarEliminarProducto(producto);
                            },
                            onVerDetalle: () {
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

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
