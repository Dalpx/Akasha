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
// Aseguramos la importación de la vista detallada
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

  // --- REPORTE VALORACIÓN ---
  Future<void> _abrirReporteInventario() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final inventario = await _inventarioService.obtenerReporteValorado();

      if (!mounted) return;
      Navigator.of(context).pop();

      final listaMapeada = inventario.map((item) => {
        'ref': item['sku'],
        'fecha': item['nombre'], 
        'entidad': "${item['cantidad']} unds.",
        'total': item['valor_total'],
        'timestamp': null, // Agregado para compatibilidad
        'esValorMonetario': true,
      }).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VistaReporteDetallado(
            titulo: 'Inventario Valorado',
            datosIniciales: listaMapeada,
            permiteFiltrarFecha: false,  // Inventario es foto actual
            esValorMonetario: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar reporte: $e')),
      );
    }
  }

  // --- REPORTE SIN STOCK ---
  Future<void> _abrirReporteSinStock() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final inventarioSinStock = await _inventarioService.obtenerReporteSinStock();

      if (!mounted) return;
      Navigator.of(context).pop();

      final listaMapeada = inventarioSinStock.map((item) => {
        'ref': item['sku'],
        'fecha': item['nombre'], 
        'entidad': "${item['cantidad']} unds.",
        'total': 0.0,
        'timestamp': null, // Agregado para compatibilidad
        'esValorMonetario': false,
      }).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VistaReporteDetallado(
            titulo: 'Productos Sin Stock',
            datosIniciales: listaMapeada,
            permiteFiltrarFecha: false,
            esValorMonetario: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar reporte: $e')),
      );
    }
  }

  // ====================================================================
  // NUEVA FUNCIÓN: ABRIR REPORTE DE STOCK POR UBICACIÓN
  // ====================================================================
  Future<void> _abrirReporteStockPorUbicacion() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Obtener la data del servicio
      final stockUbicacion = await _inventarioService.obtenerReporteStockPorUbicacion();

      if (!mounted) return;
      Navigator.of(context).pop();
      
      // 2. Mapear los datos (usando la misma lógica corregida de ReportesPage)
      final listaMapeada = stockUbicacion.map((item) {
        // Usamos las claves reales que devuelve la API y las mapeamos a la vista
        final cantidad = (item['stock'] as num? ?? 0.0).toDouble();
        final nombreProducto = item['nombre'] ?? 'Producto Desconocido';

        return {
          // Mapeamos el nombre del producto al campo 'ref' y 'fecha'
          'ref': nombreProducto, 
          'fecha': nombreProducto, 
          // Mapeamos el nombre del almacén a 'entidad' (la columna principal del reporte)
          'entidad': item['nombre_almacen'] ?? 'Ubicación General', 
          'total': cantidad,
          'timestamp': null,
          'producto_nombre': nombreProducto, // Para filtros
        };
      }).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VistaReporteDetallado(
            titulo: 'Stock por Ubicación',
            labelEntidad: 'Ubicación',
            datosIniciales: listaMapeada, 
            permiteFiltrarFecha: false, // Es un reporte de estado actual
            esValorMonetario: false, // Es en CANTIDADES
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Stock por Ubicación: $e')),
      );
    }
  }


  // ====================================================================
  // FUNCIÓN EXISTENTE: ABRIR REPORTE DE HISTORIAL DE MOVIMIENTO (KARDEX)
  // ====================================================================
  Future<void> _abrirHistorialMovimiento() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Obtener todos los movimientos (Kardex global)
      final historial = await _inventarioService.obtenerHistorialMovimientos();

      if (!mounted) return;
      Navigator.of(context).pop();
      
      // 2. Mapear los datos de historial (usando la lógica de mapeo del ReportesPage)
      final listaMapeada = historial.map((m) {
        DateTime? fechaObj = (m['fecha'] != null) ? DateTime.tryParse(m['fecha'].toString()) : null;

        String nombreProd = m['producto'] ?? m['nombre_producto'] ?? 'Producto';
        String tipo = m['tipo_movimiento'] ?? m['tipo'] ?? 'Mov'; 
        String ubicacion = m['ubicacion'] ?? 'General';
        
        double cantidadAbsoluta = double.tryParse(m['cantidad'].toString()) ?? 0.0;
        
        bool esSalida = tipo.toLowerCase().contains('salida') || 
                        tipo.toLowerCase().contains('venta') ||
                        tipo.toLowerCase().contains('consumo') ||
                        tipo.toLowerCase().contains('out');

        double cantidadReal = esSalida ? (cantidadAbsoluta * -1) : cantidadAbsoluta;

        return {
          // Datos para la Vista (App)
          'ref': m['referencia'] ?? m['id_movimiento'] ?? '-',
          'fecha': m['fecha'] ?? '-',
          'entidad': nombreProd, 
          'total': cantidadReal, 
          'timestamp': fechaObj,
          
          // DATOS CRUDOS PARA EL PDF
          'tipo_movimiento': tipo,  
          'ubicacion': ubicacion,   
          'cantidad': cantidadReal,  
          'producto_nombre': nombreProd, 
        };
      }).toList();


      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VistaReporteDetallado(
            titulo: 'Historial de Movimientos (Kardex)',
            labelEntidad: 'Producto',
            datosIniciales: listaMapeada, 
            permiteFiltrarFecha: true,
            esValorMonetario: false, // Es en CANTIDADES
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Kardex: $e')),
      );
    }
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