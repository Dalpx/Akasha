
import 'package:akasha/services/ubicacion_service.dart';
import 'package:akasha/views/inventario/ubicaciones_productos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NECESARIO para FilteringTextInputFormatter

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
  final UbicacionService _ubicacionService = UbicacionService();

  // Constantes de validación para el SKU
  static const int _minSKULength = 8;
  static const int _maxSKULength = 12;

  // Future que se usa para construir la lista de productos con FutureBuilder.
  late Future<List<Producto>> _futureProductos;

  // Listas para los select boxes.
  List<Proveedor> _proveedores = <Proveedor>[];
  List<Categoria> _categorias = <Categoria>[];

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
    List<Proveedor> proveedores =
        await _proveedorService.obtenerProveedoresActivos();
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

  /// Muestra un diálogo con un formulario para crear un nuevo producto.
  /// Incluye select boxes para proveedor y categoría y campo de stock.
  Future<void> _abrirDialogoNuevoProducto() async {
    // Asegura que las listas de proveedores/categorías estén cargadas.
    if (_cargandoCombos) {
      await _cargarProveedoresYCategorias();
    }

    // 1. CLAVE DEL FORMULARIO
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    TextEditingController nombreController = TextEditingController();
    TextEditingController skuController = TextEditingController();
    TextEditingController descripcionController = TextEditingController();
    TextEditingController costoController = TextEditingController();
    TextEditingController ventaController = TextEditingController();

    // Variables locales para el select box.
    Proveedor? proveedorSeleccionado;
    Categoria? categoriaSeleccionada;

    // Obtener la lista de productos actuales para validar unicidad (ej. SKU)
    final List<Producto> productosExistentes =
        await _inventarioService.obtenerProductos();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        // StatefulBuilder permite manejar estado local dentro del diálogo.
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setStateDialog,
          ) {
            return AlertDialog(
              title: const Text('Nuevo producto'),
              // 2. ENVOLVER EN SINGLECHILDSCROLLVIEW Y FORM
              content: SingleChildScrollView(
                child: Form(
                  key: formKey, // Asignar la clave
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // 1. Nombre (Obligatorio)
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre del producto es obligatorio.';
                          }
                          return null;
                        },
                      ),
                      // 2. SKU (Obligatorio + Unicidad + Longitud)
                      TextFormField(
                        controller: skuController,
                        decoration:
                            const InputDecoration(labelText: 'SKU *'),
                        validator: (value) {
                          final sku = value?.trim() ?? '';
                          if (sku.isEmpty) {
                            return 'El SKU es obligatorio.';
                          }
                          // VALIDACIÓN DE LONGITUD DE SKU
                          if (sku.length < _minSKULength ||
                              sku.length > _maxSKULength) {
                            return 'La longitud del SKU debe estar entre $_minSKULength y $_maxSKULength caracteres.';
                          }
                          // Validación de unicidad
                          bool existe = productosExistentes.any(
                            (p) => p.sku.toLowerCase() == sku.toLowerCase(),
                          );
                          if (existe) {
                            return 'El SKU ya está registrado.';
                          }
                          return null;
                        },
                      ),
                      // 3. Descripción (Opcional)
                      TextFormField(
                        controller: descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                        // Ya no tiene validador, es opcional
                      ),
                      // 4. Precio costo (Obligatorio + Numérico)
                      TextFormField(
                        controller: costoController,
                        decoration: const InputDecoration(
                          labelText: 'Precio costo *',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          // Permite números y el punto decimal (hasta 2 decimales)
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'El precio de costo es obligatorio.';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Debe ser un número válido.';
                          }
                          return null;
                        },
                      ),
                      // 5. Precio venta (Obligatorio + Numérico)
                      TextFormField(
                        controller: ventaController,
                        decoration: const InputDecoration(
                          labelText: 'Precio venta *',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          // Permite números y el punto decimal (hasta 2 decimales)
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'El precio de venta es obligatorio.';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Debe ser un número válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),
                      // 6. Select box para proveedor (Obligatorio)
                      DropdownButtonFormField<Proveedor>(
                        initialValue: proveedorSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Proveedor *',
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
                        validator: (Proveedor? value) {
                          if (value == null) {
                            return 'El proveedor es obligatorio.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),
                      // 7. Select box para categoría (Obligatorio)
                      DropdownButtonFormField<Categoria>(
                        initialValue: categoriaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Categoría *',
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
                        validator: (Categoria? value) {
                          if (value == null) {
                            return 'La categoría es obligatoria.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
                    // LLAMADA A VALIDACIÓN DEL FORMULARIO
                    if (formKey.currentState!.validate()) {
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

                      // Construye el nuevo producto con los valores validados.
                      Producto nuevo = Producto(
                        nombre: nombreController.text.trim(),
                        sku: skuController.text.trim(),
                        // La descripción es opcional
                        descripcion: descripcionController.text.trim(),
                        // Parseamos los valores que ya sabemos que son válidos
                        precioCosto:
                            double.tryParse(costoController.text) ?? 0.0,
                        precioVenta:
                            double.tryParse(ventaController.text) ?? 0.0,
                        idProveedor: idProveedorSeleccionado.toString(),
                        idCategoria: idCategoriaSeleccionada.toString(),
                        activo: true,
                      );

                      // Llama al servicio para crear el producto.
                      await _inventarioService.crearProducto(nuevo);

                      if (!mounted) {
                        return;
                      }

                      // Muestra SnackBar de éxito (sin emoji)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Producto creado exitosamente.'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Cierra el diálogo y recarga la lista.
                      Navigator.of(context).pop();
                      _recargarProductos();
                    }
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
  Future<void> _abrirDialogoEditarProducto(Producto producto) async {
    if (_cargandoCombos) {
      await _cargarProveedoresYCategorias();
    }

    // 1. CLAVE DEL FORMULARIO
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
    Proveedor? proveedorInicial = _proveedores.firstWhereOrNull(
      (p) => p.idProveedor == producto.idProveedor,
    );
    Categoria? categoriaInicial = _categorias.firstWhereOrNull(
      (c) => c.idCategoria == producto.idCategoria,
    );

    // Variables locales que controlan los select boxes.
    Proveedor? proveedorSeleccionado = proveedorInicial;
    Categoria? categoriaSeleccionada = categoriaInicial;

    // Obtener la lista de productos actuales para validar unicidad (ej. SKU)
    final List<Producto> productosExistentes =
        await _inventarioService.obtenerProductos();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setStateDialog,
          ) {
            return AlertDialog(
              title: const Text('Editar producto'),
              // 2. ENVOLVER EN SINGLECHILDSCROLLVIEW Y FORM
              content: SingleChildScrollView(
                child: Form(
                  key: formKey, // Asignar la clave
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // 1. Nombre (Obligatorio)
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre del producto es obligatorio.';
                          }
                          return null;
                        },
                      ),
                      // 2. SKU (Obligatorio + Unicidad, excluyendo el actual + Longitud)
                      TextFormField(
                        controller: skuController,
                        decoration:
                            const InputDecoration(labelText: 'SKU *'),
                        validator: (value) {
                          final sku = value?.trim() ?? '';
                          if (sku.isEmpty) {
                            return 'El SKU es obligatorio.';
                          }
                          // VALIDACIÓN DE LONGITUD DE SKU
                          if (sku.length < _minSKULength ||
                              sku.length > _maxSKULength) {
                            return 'La longitud del SKU debe estar entre $_minSKULength y $_maxSKULength caracteres.';
                          }
                          // Validación de unicidad (ignorando el producto actual)
                          bool existe = productosExistentes.any(
                            (p) =>
                                p.sku.toLowerCase() == sku.toLowerCase() &&
                                p.idProducto != producto.idProducto,
                          );
                          if (existe) {
                            return 'El SKU ya está registrado para otro producto.';
                          }
                          return null;
                        },
                      ),
                      // 3. Descripción (Opcional)
                      TextFormField(
                        controller: descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                        // Ya no tiene validador, es opcional
                      ),
                      // 4. Precio costo (Obligatorio + Numérico)
                      TextFormField(
                        controller: costoController,
                        decoration: const InputDecoration(
                          labelText: 'Precio costo *',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          // Permite números y el punto decimal (hasta 2 decimales)
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'El precio de costo es obligatorio.';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Debe ser un número válido.';
                          }
                          return null;
                        },
                      ),
                      // 5. Precio venta (Obligatorio + Numérico)
                      TextFormField(
                        controller: ventaController,
                        decoration: const InputDecoration(
                          labelText: 'Precio venta *',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          // Permite números y el punto decimal (hasta 2 decimales)
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty) {
                            return 'El precio de venta es obligatorio.';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Debe ser un número válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),
                      // 6. Select box para proveedor (Obligatorio)
                      DropdownButtonFormField<Proveedor>(
                        initialValue: proveedorSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Proveedor *',
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
                        validator: (Proveedor? value) {
                          if (value == null) {
                            return 'El proveedor es obligatorio.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),
                      // 7. Select box para categoría (Obligatorio)
                      DropdownButtonFormField<Categoria>(
                        initialValue: categoriaSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Categoría *',
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
                        validator: (Categoria? value) {
                          if (value == null) {
                            return 'La categoría es obligatoria.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
                    // LLAMADA A VALIDACIÓN DEL FORMULARIO
                    if (formKey.currentState!.validate()) {
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

                      // Actualiza los campos del producto con los nuevos valores.
                      producto.nombre = nombreController.text.trim();
                      producto.sku = skuController.text.trim();
                      producto.descripcion = descripcionController.text.trim(); // La descripción es opcional
                      // Actualiza los valores parseados y validados
                      producto.precioCosto =
                          double.tryParse(costoController.text) ?? 0.0;
                      producto.precioVenta =
                          double.tryParse(ventaController.text) ?? 0.0;
                      producto.idProveedor = idProveedorSeleccionado.toString();
                      producto.idCategoria = idCategoriaSeleccionada.toString();

                      // Llama al servicio para guardar los cambios.
                      await _inventarioService.actualizarProducto(producto);

                      if (!mounted) {
                        return;
                      }
                      
                      // Muestra SnackBar de éxito (sin emoji)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Producto actualizado exitosamente.'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Cierra el diálogo y recarga la lista.
                      Navigator.of(context).pop();
                      _recargarProductos();
                    }
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
                      content: Text('Producto "${producto.nombre}" eliminado (desactivado).'),
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
                builder: (
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
                      Producto producto = productos[index];

                      return Card(
                        child: ListTile(
                          title: Text(producto.nombre),
                          subtitle: Text(
                            'SKU: ${producto.sku}\n'
                            'Precio venta: \$${producto.precioVenta.toStringAsFixed(2)}\n' // Formateo de precio
                            'Proveedor: ${producto.idProveedor}\n' // Mostrar nombre
                            'Categoría: ${producto.idCategoria}' // Mostrar nombre
                          ),
                          // Trailing con botones de editar y eliminar.
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              // Botón de Ubicaciones
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
                              // Botón de Editar
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar',
                                onPressed: () {
                                  _abrirDialogoEditarProducto(producto);
                                },
                              ),
                              // Botón de Eliminar
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Eliminar (Desactivar)',
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