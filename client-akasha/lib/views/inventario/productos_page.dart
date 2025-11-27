import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/services/ubicacion_service.dart';
import 'package:akasha/views/inventario/ubicaciones_productos_page.dart';
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
  const ProductosPage({Key? key}) : super(key: key);

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
  final UbicacionService _ubicacionService = UbicacionService();

  // Future que se usa para construir la lista de productos con FutureBuilder.
  late Future<List<Producto>> _futureProductos;

  // Listas para los select boxes.
  List<Proveedor> _proveedores = <Proveedor>[];
  List<Categoria> _categorias = <Categoria>[];
  List<Ubicacion> _ubicaciones = <Ubicacion>[];

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
    List<Ubicacion> ubicaciones = await _ubicacionService
        .obtenerUbicacionesActivas();

    setState(() {
      _proveedores = proveedores;
      _categorias = categorias;
      _ubicaciones = ubicaciones;
      _cargandoCombos = false;
    });
  }

  /// Recarga los productos desde el servicio y reconstruye el FutureBuilder.
  void _recargarProductos() {
    setState(() {
      _futureProductos = _inventarioService.obtenerProductos();
    });
  }

  /// Muestra un diálogo con un formulario para crear un nuevo producto.
  /// Incluye select boxes para proveedor y categoría y campo de stock.
  Future<void> _abrirDialogoNuevoProducto() async {
    // Asegura que las listas de proveedores/categorías estén cargadas.
    if (_cargandoCombos) {
      await _cargarProveedoresYCategorias();
    }

    TextEditingController nombreController = TextEditingController();
    TextEditingController skuController = TextEditingController();
    TextEditingController descripcionController = TextEditingController();
    TextEditingController costoController = TextEditingController();
    TextEditingController ventaController = TextEditingController();
    // TextEditingController stockController = TextEditingController();

    // Variables locales para el select box.
    Proveedor? proveedorSeleccionado;
    Categoria? categoriaSeleccionada;
    Ubicacion? ubicacionSeleccionada;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // StatefulBuilder permite manejar estado local dentro del diálogo.
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setStateDialog,
              ) {
                return AlertDialog(
                  title: const Text('Nuevo producto'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                          ),
                        ),
                        TextField(
                          controller: skuController,
                          decoration: const InputDecoration(labelText: 'SKU'),
                        ),
                        TextField(
                          controller: descripcionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                          ),
                        ),
                        TextField(
                          controller: costoController,
                          decoration: const InputDecoration(
                            labelText: 'Precio costo',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: ventaController,
                          decoration: const InputDecoration(
                            labelText: 'Precio venta',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12.0),
                        // Select box para proveedor
                        DropdownButtonFormField<Proveedor>(
                          value: proveedorSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Proveedor',
                          ),
                          items: _proveedores.map((Proveedor proveedor) {
                            return DropdownMenuItem<Proveedor>(
                              value: proveedor,
                              child: Text(proveedor.nombre),
                            );
                          }).toList(),
                          onChanged: (Proveedor? nuevo) {
                            setStateDialog(() {
                              proveedorSeleccionado = nuevo;
                            });
                          },
                        ),
                        const SizedBox(height: 12.0),
                        // Select box para categoría
                        DropdownButtonFormField<Categoria>(
                          value: categoriaSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                          ),
                          items: _categorias.map((Categoria categoria) {
                            return DropdownMenuItem<Categoria>(
                              value: categoria,
                              child: Text(categoria.nombreCategoria),
                            );
                          }).toList(),
                          onChanged: (Categoria? nuevo) {
                            setStateDialog(() {
                              categoriaSeleccionada = nuevo;
                            });
                          },
                        ),
                        // Select box para ubicacion
                        DropdownButtonFormField<Ubicacion>(
                          value: ubicacionSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Ubicacion',
                          ),
                          items: _ubicaciones.map((Ubicacion ubicacion) {
                            return DropdownMenuItem<Ubicacion>(
                              value: ubicacion,
                              child: Text(ubicacion.nombre),
                            );
                          }).toList(),
                          onChanged: (Ubicacion? nuevo) {
                            setStateDialog(() {
                              ubicacionSeleccionada = nuevo;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        // Cierra el diálogo sin hacer nada.
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        int? idProveedorSeleccionado;
                        int? idCategoriaSeleccionada;
                        int? idUbicacionSeleccionada;

                        if (proveedorSeleccionado != null) {
                          idProveedorSeleccionado =
                              proveedorSeleccionado!.idProveedor;
                        }

                        if (categoriaSeleccionada != null) {
                          idCategoriaSeleccionada =
                              categoriaSeleccionada!.idCategoria;
                        }
                        if (ubicacionSeleccionada != null) {
                          idUbicacionSeleccionada =
                              ubicacionSeleccionada!.idUbicacion;
                        }

                        // Construye el nuevo producto con los valores del formulario.
                        Producto nuevo = Producto(
                          nombre: nombreController.text.trim(),
                          sku: skuController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          precioCosto:
                              double.tryParse(costoController.text) ?? 0.0,
                          precioVenta:
                              double.tryParse(ventaController.text) ?? 0.0,
                          idUbicacion: idUbicacionSeleccionada,
                          idProveedor: idProveedorSeleccionado,
                          idCategoria: idCategoriaSeleccionada,

                          activo: true,
                        );

                        // Llama al servicio para crear el producto.
                        await _inventarioService.crearProducto(nuevo);

                        if (!mounted) {
                          return;
                        }

                        // Cierra el diálogo y recarga la lista.
                        Navigator.of(context).pop();
                        _recargarProductos();
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                );
              },
        );
      },
    );
  }

  /// Muestra un diálogo para editar un producto existente.
  /// Incluye select boxes para proveedor y categoría y campo de stock.
  Future<void> _abrirDialogoEditarProducto(Producto producto) async {
    if (_cargandoCombos) {
      await _cargarProveedoresYCategorias();
    }

    TextEditingController nombreController = TextEditingController(
      text: producto.nombre,
    );
    TextEditingController skuController = TextEditingController(
      text: producto.sku,
    );
    TextEditingController descripcionController = TextEditingController(
      text: producto.descripcion,
    );
    TextEditingController costoController = TextEditingController(
      text: producto.precioCosto.toString(),
    );
    TextEditingController ventaController = TextEditingController(
      text: producto.precioVenta.toString(),
    );

    // Buscamos el proveedor y la categoría actualmente asociados al producto.
    Proveedor? proveedorInicial;
    for (int i = 0; i < _proveedores.length; i++) {
      Proveedor proveedor = _proveedores[i];
      if (producto.idProveedor != null &&
          proveedor.idProveedor == producto.idProveedor) {
        proveedorInicial = proveedor;
      }
    }

    Categoria? categoriaInicial;
    for (int i = 0; i < _categorias.length; i++) {
      Categoria categoria = _categorias[i];
      if (producto.idCategoria != null &&
          categoria.idCategoria == producto.idCategoria) {
        categoriaInicial = categoria;
      }
    }

    // Variables locales que controlan los select boxes.
    Proveedor? proveedorSeleccionado = proveedorInicial;
    Categoria? categoriaSeleccionada = categoriaInicial;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setStateDialog,
              ) {
                return AlertDialog(
                  title: const Text('Editar producto'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                          ),
                        ),
                        TextField(
                          controller: skuController,
                          decoration: const InputDecoration(labelText: 'SKU'),
                        ),
                        TextField(
                          controller: descripcionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                          ),
                        ),
                        TextField(
                          controller: costoController,
                          decoration: const InputDecoration(
                            labelText: 'Precio costo',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: ventaController,
                          decoration: const InputDecoration(
                            labelText: 'Precio venta',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12.0),
                        DropdownButtonFormField<Proveedor>(
                          value: proveedorSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Proveedor',
                          ),
                          items: _proveedores.map((Proveedor proveedor) {
                            return DropdownMenuItem<Proveedor>(
                              value: proveedor,
                              child: Text(proveedor.nombre),
                            );
                          }).toList(),
                          onChanged: (Proveedor? nuevo) {
                            setStateDialog(() {
                              proveedorSeleccionado = nuevo;
                            });
                          },
                        ),
                        const SizedBox(height: 12.0),
                        DropdownButtonFormField<Categoria>(
                          value: categoriaSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                          ),
                          items: _categorias.map((Categoria categoria) {
                            return DropdownMenuItem<Categoria>(
                              value: categoria,
                              child: Text(categoria.nombreCategoria),
                            );
                          }).toList(),
                          onChanged: (Categoria? nuevo) {
                            setStateDialog(() {
                              categoriaSeleccionada = nuevo;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        // Cierra el diálogo sin aplicar cambios.
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        int? idProveedorSeleccionado;
                        int? idCategoriaSeleccionada;

                        if (proveedorSeleccionado != null) {
                          idProveedorSeleccionado =
                              proveedorSeleccionado!.idProveedor;
                        }

                        if (categoriaSeleccionada != null) {
                          idCategoriaSeleccionada =
                              categoriaSeleccionada!.idCategoria;
                        }

                        // int stock = int.tryParse(stockController.text) ?? 0;

                        // Actualiza los campos del producto con los nuevos valores.
                        producto.nombre = nombreController.text.trim();
                        producto.sku = skuController.text.trim();
                        producto.descripcion = descripcionController.text
                            .trim();
                        producto.precioCosto =
                            double.tryParse(costoController.text) ?? 0.0;
                        producto.precioVenta =
                            double.tryParse(ventaController.text) ?? 0.0;
                        // producto.stock = stock;
                        producto.idProveedor = idProveedorSeleccionado;
                        producto.idCategoria = idCategoriaSeleccionada;

                        // Llama al servicio para guardar los cambios.
                        await _inventarioService.actualizarProducto(producto);

                        if (!mounted) {
                          return;
                        }

                        // Cierra el diálogo y recarga la lista.
                        Navigator.of(context).pop();
                        _recargarProductos();
                      },
                      child: const Text('Guardar cambios'),
                    ),
                  ],
                );
              },
        );
      },
    );
  }

  /// Muestra un modal para confirmar si realmente se desea eliminar el producto.
  /// Solo si el usuario confirma se llama al método que elimina.
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
  /// y luego recarga la lista.
  Future<void> _eliminarProducto(int idProducto) async {
    await _inventarioService.eliminarProducto(idProducto);
    _recargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // En modo web, el AppShell ya maneja AppBar/SideBar; aquí solo va el contenido.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Inventario de productos',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Botón para ir a la pantalla de gestión de proveedores y categorías
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.rutaGestionMaestros);
                    await _cargarProveedoresYCategorias();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Configuración'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.rutaGestionUbicaciones);
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Gestionar ubicaciones'),
                ),

                const SizedBox(width: 8.0),
                // Botón para crear un nuevo producto
                ElevatedButton.icon(
                  onPressed: () {
                    _abrirDialogoNuevoProducto();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Producto>>(
                future: _futureProductos,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<Producto>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                          if (productos[index].activo) {}
                          Producto producto = productos[index];

                          return Card(
                            child: ListTile(
                              title: Text(producto.nombre),
                              subtitle: Text(
                                'SKU: ${producto.sku}\n'
                                'Precio venta: ${producto.precioVenta}\n'
                                'Stock: ${0}',
                              ),
                              // Trailing con botones de editar y eliminar.
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: const Icon(Icons.location_on),
                                    tooltip: 'Ubicaciones',
                                    onPressed: () {
                                      if (producto.idProducto != null) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (BuildContext context) {
                                              return UbicacionesProductoPage(
                                                producto: producto,
                                              );
                                            },
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      _abrirDialogoEditarProducto(producto);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Eliminar',
                                    onPressed: () {
                                      _confirmarEliminarProducto(producto);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
