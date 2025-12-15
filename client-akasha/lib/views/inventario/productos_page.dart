import 'package:akasha/common/custom_card.dart';
import 'package:akasha/views/inventario/ubicaciones_productos_page.dart';
import 'package:akasha/views/inventario/widgets/producto_detalles.dart';
import 'package:akasha/views/inventario/widgets/producto_form_dialog.dart';
import 'package:akasha/views/inventario/widgets/producto_list_item.dart';
import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../models/proveedor.dart';
import '../../models/categoria.dart';
import '../../services/inventario_service.dart';
import '../../services/proveedor_service.dart';
import '../../services/categoria_service.dart';
import '../../core/app_routes.dart';
import 'package:akasha/views/reportes/widgets/vista_reporte_detallado.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage>
    with AutomaticKeepAliveClientMixin {
  final InventarioService _inventarioService = InventarioService();
  final ProveedorService _proveedorService = ProveedorService();
  final CategoriaService _categoriaService = CategoriaService();

  late Future<List<Producto>> _futureProductos;

  List<Proveedor> _proveedores = <Proveedor>[];
  List<Categoria> _categorias = <Categoria>[];

  bool _cargandoCombos = true;
  List<Producto>? _cacheProductos;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  bool _soloActivos = true;
  String? _filtroProveedor;
  String? _filtroCategoria;
  double? _minPrecioVenta;
  double? _maxPrecioVenta;

  int _conteoFiltrado = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futureProductos = _cargarProductosConCache();
    _cargarProveedoresYCategorias();
    InventarioService.productosRevision.addListener(_onProductosChanged);
  }

  @override
  void dispose() {
    InventarioService.productosRevision.removeListener(_onProductosChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onProductosChanged() {
    if (!mounted) return;
    _cacheProductos = null;
    _recargarProductos();
  }

  Future<List<Producto>> _cargarProductosConCache() async {
    if (_cacheProductos != null) return _cacheProductos!;
    final productos = await _inventarioService.obtenerProductos();
    _cacheProductos = productos;
    return productos;
  }

  Future<void> _cargarProveedoresYCategorias() async {
    try {
      final proveedoresFuture = _proveedorService.obtenerProveedoresActivos();
      final categoriasFuture = _categoriaService.obtenerCategorias();
      final results = await Future.wait([proveedoresFuture, categoriasFuture]);

      if (!mounted) return;

      setState(() {
        _proveedores = results[0] as List<Proveedor>;
        _categorias = results[1] as List<Categoria>;
        _cargandoCombos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoCombos = false);
    }
  }

  void _recargarProductos() {
    if (!mounted) return;
    setState(() {
      _futureProductos = _cargarProductosConCache();
    });
  }

  Future<void> refreshFromExternalChange() async {
    _cacheProductos = null;
    await _cargarProveedoresYCategorias();
    _recargarProductos();
  }

  Future<void> _abrirFormularioProducto({Producto? productoEditar}) async {
    if (_cargandoCombos) {
      await _cargarProveedoresYCategorias();
    }

    final productosActuales = await _inventarioService.obtenerProductos();

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
              onPressed: () => Navigator.of(context).pop(),
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

  void _syncConteo(int value) {
    if (_conteoFiltrado == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _conteoFiltrado = value);
    });
  }

  bool _hasActiveFilters() {
    if ((_filtroProveedor ?? '').trim().isNotEmpty) return true;
    if ((_filtroCategoria ?? '').trim().isNotEmpty) return true;
    if (_minPrecioVenta != null) return true;
    if (_maxPrecioVenta != null) return true;
    return false;
  }

  List<String> _valoresUnicosProveedor(List<Producto> productos) {
    final set = <String>{};
    for (final p in productos) {
      final v = (p.idProveedor ?? '').trim();
      if (v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> _valoresUnicosCategoria(List<Producto> productos) {
    final set = <String>{};
    for (final p in productos) {
      final v = (p.idCategoria ?? '').trim();
      if (v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Producto> _filtrarProductos(List<Producto> productos) {
    Iterable<Producto> res = productos;

    if (_soloActivos) {
      res = res.where((p) => p.activo);
    }

    if ((_filtroProveedor ?? '').trim().isNotEmpty) {
      final fp = _filtroProveedor!.trim();
      res = res.where((p) => (p.idProveedor ?? '').trim() == fp);
    }

    if ((_filtroCategoria ?? '').trim().isNotEmpty) {
      final fc = _filtroCategoria!.trim();
      res = res.where((p) => (p.idCategoria ?? '').trim() == fc);
    }

    if (_minPrecioVenta != null) {
      final min = _minPrecioVenta!;
      res = res.where((p) => p.precioVenta >= min);
    }

    if (_maxPrecioVenta != null) {
      final max = _maxPrecioVenta!;
      res = res.where((p) => p.precioVenta <= max);
    }

    final q = _searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.descripcion.toLowerCase().contains(q);
      });
    }

    return res.toList();
  }

  Future<void> _abrirFiltros() async {
    final productos = _cacheProductos ?? await _cargarProductosConCache();
    if (!mounted) return;

    final proveedores = _valoresUnicosProveedor(productos);
    final categorias = _valoresUnicosCategoria(productos);

    bool soloActivosLocal = _soloActivos;
    String? proveedorLocal = _filtroProveedor;
    String? categoriaLocal = _filtroCategoria;

    final minCtrl = TextEditingController(
      text: _minPrecioVenta?.toString() ?? '',
    );
    final maxCtrl = TextEditingController(
      text: _maxPrecioVenta?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filtros'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value:
                          (proveedorLocal != null &&
                              proveedores.contains(proveedorLocal))
                          ? proveedorLocal
                          : null,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los proveedores'),
                        ),
                        ...proveedores.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p,
                            child: Text(p),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => proveedorLocal = v),
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value:
                          (categoriaLocal != null &&
                              categorias.contains(categoriaLocal))
                          ? categoriaLocal
                          : null,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        ...categorias.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c,
                            child: Text(c),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => categoriaLocal = v),
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Precio venta mín.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Precio venta máx.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    setDialogState(() {
                      soloActivosLocal = true;
                      proveedorLocal = null;
                      categoriaLocal = null;
                      minCtrl.text = '';
                      maxCtrl.text = '';
                    });
                  },
                  child: const Text('Limpiar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final min = double.tryParse(minCtrl.text.trim());
                    final max = double.tryParse(maxCtrl.text.trim());

                    setState(() {
                      _soloActivos = soloActivosLocal;
                      _filtroProveedor = proveedorLocal;
                      _filtroCategoria = categoriaLocal;
                      _minPrecioVenta = min;
                      _maxPrecioVenta = max;
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    minCtrl.dispose();
    maxCtrl.dispose();
  }

  void _limpiarBusqueda() {
    _searchCtrl.clear();
    setState(() => _searchText = '');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                
                // --- BOTÓN ROJO: SIN STOCK ---
                ElevatedButton.icon(
                  onPressed: _abrirReporteSinStock,
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Productos Sin Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8.0),

                // --- BOTÓN TEAL: VALORACIÓN ---
                ElevatedButton.icon(
                  onPressed: _abrirReporteInventario,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Valoración'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8.0),

                // --- BOTÓN AMARILLO: STOCK POR UBICACIÓN (NUEVO) ---
                ElevatedButton.icon(
                  onPressed: _abrirReporteStockPorUbicacion, // <-- NUEVA FUNCIÓN
                  icon: const Icon(Icons.location_on),
                  label: const Text('Ubicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8.0),

                // --- BOTÓN AZUL: HISTORIAL (KARDEX) ---
                ElevatedButton.icon(
                  onPressed: _abrirHistorialMovimiento, // <-- FUNCIÓN EXISTENTE
                  icon: const Icon(Icons.history_toggle_off),
                  label: const Text('Kardex'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8.0),

                // --- BOTONES RESTANTES ---
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context)
                        .pushNamed(AppRoutes.rutaGestionMaestros);

                    await _cargarProveedoresYCategorias();
                    _cacheProductos = null;
                    _recargarProductos();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Configuración'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton.icon(
                  onPressed: () => _abrirFormularioProducto(),
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
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          (snapshot.data == null || snapshot.data!.isEmpty)) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar productos: ${snapshot.error}',
                          ),
                        );
                      }

                      final data = snapshot.data ?? <Producto>[];
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
    } catch (_) {
      return null;
    }
  }
}
