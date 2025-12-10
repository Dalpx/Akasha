import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/services/ubicacion_service.dart';
import 'package:akasha/widgets/custom_tile.dart';
import 'package:flutter/material.dart';
import '../../models/proveedor.dart';
import '../../models/categoria.dart';
import '../../services/proveedor_service.dart';
import '../../services/categoria_service.dart';

/// Pantalla que se encarga de la gestión de proveedores y categorías.
/// Usa un TabBar para alternar entre Proveedores y Categorías.
class GestionProveedoresCategoriasPage extends StatefulWidget {
  const GestionProveedoresCategoriasPage({super.key});

  @override
  State<GestionProveedoresCategoriasPage> createState() {
    return _GestionProveedoresCategoriasPageState();
  }
}

class _GestionProveedoresCategoriasPageState
    extends State<GestionProveedoresCategoriasPage> {
  final ProveedorService _proveedorService = ProveedorService();
  final CategoriaService _categoriaService = CategoriaService();
  final UbicacionService _ubicacionService = UbicacionService();

  late Future<List<Proveedor>> _futureProveedores;
  late Future<List<Categoria>> _futureCategorias;
  late Future<List<Ubicacion>> _futureUbicaciones;

  @override
  void initState() {
    super.initState();
    _futureProveedores = _proveedorService.obtenerProveedoresActivos();
    _futureCategorias = _categoriaService.obtenerCategorias();
    _futureUbicaciones = _ubicacionService.obtenerUbicacionesActivas();
  }

  /// Recarga la lista de proveedores.
  void _recargarProveedores() {
    setState(() {
      _futureProveedores = _proveedorService.obtenerProveedoresActivos();
    });
  }

  /// Recarga la lista de categorías.
  void _recargarCategorias() {
    setState(() {
      _futureCategorias = _categoriaService.obtenerCategorias();
    });
  }

  /// Recarga la lista de categorías.
  void _recargarUbicaciones() {
    setState(() {
      _futureUbicaciones = _ubicacionService.obtenerUbicacionesActivas();
    });
  }

  /// Muestra un diálogo para crear un nuevo proveedor.
  void _abrirDialogoNuevoProveedor() {
    TextEditingController nombreController = TextEditingController();
    TextEditingController telefonoController = TextEditingController();
    TextEditingController correoController = TextEditingController();
    TextEditingController direccionController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nuevo proveedor'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                TextField(
                  controller: correoController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                TextField(
                  controller: direccionController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Cierra el diálogo sin crear proveedor.
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Proveedor nuevo = Proveedor(
                  nombre: nombreController.text.trim(),
                  telefono: telefonoController.text.trim(),
                  correo: correoController.text.trim().isEmpty
                      ? null
                      : correoController.text.trim(),
                  direccion: direccionController.text.trim().isEmpty
                      ? null
                      : direccionController.text.trim(),
                  activo: true,
                );

                await _proveedorService.crearProveedor(nuevo);

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
                _recargarProveedores();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para editar un proveedor existente.
  void _abrirDialogoEditarProveedor(Proveedor proveedor) {
    TextEditingController nombreController = TextEditingController(
      text: proveedor.nombre,
    );
    TextEditingController telefonoController = TextEditingController(
      text: proveedor.telefono,
    );
    TextEditingController correoController = TextEditingController(
      text: proveedor.correo ?? '',
    );
    TextEditingController direccionController = TextEditingController(
      text: proveedor.direccion ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar proveedor'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: telefonoController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                ),
                TextField(
                  controller: correoController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
                TextField(
                  controller: direccionController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
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
                proveedor.nombre = nombreController.text.trim();
                proveedor.telefono = telefonoController.text.trim();
                proveedor.correo = correoController.text.trim().isEmpty
                    ? null
                    : correoController.text.trim();
                proveedor.direccion = direccionController.text.trim().isEmpty
                    ? null
                    : direccionController.text.trim();

                await _proveedorService.actualizarProveedor(proveedor);

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
                _recargarProveedores();
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo de confirmación antes de eliminar un proveedor.
  void _confirmarEliminarProveedor(Proveedor proveedor) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Seguro que deseas eliminar al proveedor "${proveedor.nombre}"?',
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
                if (proveedor.idProveedor != null) {
                  await _proveedorService.eliminarProveedor(
                    proveedor.idProveedor!,
                  );
                }

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
                _recargarProveedores();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para crear una nueva categoría.
  void _abrirDialogoNuevaCategoria() {
    TextEditingController nombreController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nueva categoría'),
          content: TextField(
            controller: nombreController,
            decoration: const InputDecoration(labelText: 'Nombre categoría'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Cierra el diálogo sin crear categoría.
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Categoria nueva = Categoria(
                  nombreCategoria: nombreController.text.trim(),
                  activo: true,
                );

                await _categoriaService.crearCategoria(nueva);

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
                _recargarCategorias();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para editar una categoría existente.
  void _abrirDialogoEditarCategoria(Categoria categoria) {
    TextEditingController nombreController = TextEditingController(
      text: categoria.nombreCategoria,
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar categoría'),
          content: TextField(
            controller: nombreController,
            decoration: const InputDecoration(labelText: 'Nombre categoría'),
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
                categoria.nombreCategoria = nombreController.text.trim();

                await _categoriaService.actualizarCategoria(categoria);

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
                _recargarCategorias();
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo de confirmación antes de eliminar una categoría.
  void _confirmarEliminarCategoria(Categoria categoria) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Seguro que deseas eliminar la categoría "${categoria.nombreCategoria}"?',
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
                if (categoria.idCategoria != null) {
                  await _categoriaService.eliminarCategoria(
                    categoria.idCategoria!,
                  );
                }

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
                _recargarCategorias();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  /// Muestra un diálogo para crear una nueva ubicación.
  void _abrirDialogoNuevaUbicacion() {
    TextEditingController nombreController = TextEditingController();
    TextEditingController descripcionController = TextEditingController();

    bool activa = true;

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
                  title: const Text('Nueva ubicación'),
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
                          controller: descripcionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        // Cierra el diálogo sin crear ubicación.
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (nombreController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'El nombre de la ubicación es obligatorio.',
                              ),
                            ),
                          );
                          return;
                        }

                        Ubicacion nueva = Ubicacion(
                          nombreAlmacen: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim().isEmpty
                              ? null
                              : descripcionController.text.trim(),
                          activa: activa,
                        );

                        await _ubicacionService.crearUbicacion(nueva);

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
                        _recargarUbicaciones();
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

  /// Muestra un diálogo para editar una ubicación existente.
  void _abrirDialogoEditarUbicacion(Ubicacion ubicacion) {
    TextEditingController nombreController = TextEditingController(
      text: ubicacion.nombreAlmacen,
    );
    TextEditingController descripcionController = TextEditingController(
      text: ubicacion.descripcion ?? '',
    );

    bool activa = ubicacion.activa;

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
                  title: const Text('Editar ubicación'),
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
                          controller: descripcionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (opcional)',
                          ),
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
                        if (nombreController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'El nombre de la ubicación es obligatorio.',
                              ),
                            ),
                          );
                          return;
                        }

                        ubicacion.nombreAlmacen = nombreController.text.trim();
                        ubicacion.descripcion =
                            descripcionController.text.trim().isEmpty
                            ? null
                            : descripcionController.text.trim();
                        ubicacion.activa = activa;

                        await _ubicacionService.actualizarUbicacion(ubicacion);

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
                        _recargarUbicaciones();
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

  /// Muestra un diálogo de confirmación antes de eliminar lógicamente una ubicación.
  void _confirmarEliminarUbicacion(Ubicacion ubicacion) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Seguro que deseas eliminar la ubicación "${ubicacion.nombreAlmacen}"?',
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
                if (ubicacion.idUbicacion != null) {
                  await _ubicacionService.eliminarUbicacion(
                    ubicacion.idUbicacion!,
                  );
                }

                if (!mounted) {
                  return;
                }

                Navigator.of(context).pop();
                _recargarUbicaciones();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Vuelve a la ruta anterior en el Navigator
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Gestión'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              const TabBar(
                tabs: <Tab>[
                  Tab(text: 'Proveedores'),
                  Tab(text: 'Categorías'),
                  Tab(text: "Ubicaciones"),
                ],
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _buildTabProveedores(),
                    _buildTabCategorias(),
                    _buildTabUbicaciones(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el contenido de la pestaña de proveedores.
  Widget _buildTabProveedores() {
    return Column(
      children: <Widget>[
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              _abrirDialogoNuevoProveedor();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nuevo proveedor'),
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: FutureBuilder<List<Proveedor>>(
                future: _futureProveedores,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<Proveedor>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar proveedores: ${snapshot.error}',
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No hay proveedores registrados.'),
                        );
                      }

                      List<Proveedor> proveedores = snapshot.data!
                          .where((proovedor) => proovedor.activo)
                          .toList();

                      return ListView.builder(
                        itemCount: proveedores.length,
                        itemBuilder: (BuildContext context, int index) {
                          Proveedor proveedor = proveedores[index];

                          return CustomTile(
                            listTile: ListTile(
                              onTap: () {
                                _abrirDialogoEditarProveedor(proveedor);
                              },
                              title: Text(proveedor.nombre),
                              subtitle: Text(
                                'Teléfono: ${proveedor.telefono}\nCorreo: ${proveedor.correo ?? '-'} \n${proveedor.direccion}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      _abrirDialogoEditarProveedor(proveedor);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Eliminar',
                                    onPressed: () {
                                      _confirmarEliminarProveedor(proveedor);
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
          ),
        ),
      ],
    );
  }

  /// Construye el contenido de la pestaña de categorías.
  Widget _buildTabCategorias() {
    return Column(
      children: <Widget>[
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              _abrirDialogoNuevaCategoria();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva categoría'),
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: FutureBuilder<List<Categoria>>(
                future: _futureCategorias,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<Categoria>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar categorías: ${snapshot.error}',
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No hay categorías registradas.'),
                        );
                      }

                      List<Categoria> categorias = snapshot.data!
                          .where((categoria) => categoria.activo)
                          .toList();

                      return ListView.builder(
                        itemCount: categorias.length,
                        itemBuilder: (BuildContext context, int index) {
                          Categoria categoria = categorias[index];

                          return CustomTile(
                            listTile: ListTile(
                              onTap: () {
                                _abrirDialogoEditarCategoria(categoria);
                              },
                              title: Text(categoria.nombreCategoria),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      _abrirDialogoEditarCategoria(categoria);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Eliminar',
                                    onPressed: () {
                                      _confirmarEliminarCategoria(categoria);
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
          ),
        ),
      ],
    );
  }

  /// Construye el contenido de la pestaña de categorías.
  Widget _buildTabUbicaciones() {
    return Column(
      children: <Widget>[
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              _abrirDialogoNuevaUbicacion();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva Ubicacion'),
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: FutureBuilder<List<Ubicacion>>(
                future: _futureUbicaciones,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<Ubicacion>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar categorías: ${snapshot.error}',
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No hay categorías registradas.'),
                        );
                      }

                      List<Ubicacion> ubicaciones = snapshot.data!
                          .where((ubicacion) => ubicacion.activa)
                          .toList();

                      return ListView.builder(
                        itemCount: ubicaciones.length,
                        itemBuilder: (BuildContext context, int index) {
                          Ubicacion ubicacion = ubicaciones[index];

                          return CustomTile(
                            listTile: ListTile(
                              onTap: () {
                                _abrirDialogoEditarUbicacion(ubicacion);
                              },
                              title: Text(ubicacion.nombreAlmacen),
                              subtitle: Text(
                                'Descripción: ${ubicacion.descripcion ?? '-'}\n'
                                'Estado: ${ubicacion.activa ? 'Activa' : 'Inactiva'}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      _abrirDialogoEditarUbicacion(ubicacion);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Eliminar',
                                    onPressed: () {
                                      _confirmarEliminarUbicacion(ubicacion);
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
          ),
        ),
      ],
    );
  }
}
