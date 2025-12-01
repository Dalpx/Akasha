import 'package:flutter/material.dart';
import '../../models/ubicacion.dart';
import '../../services/ubicacion_service.dart';

/// Pantalla general de gestión de ubicaciones del almacén.
/// Desde aquí se pueden crear, editar y eliminar ubicaciones.
class GestionUbicacionesPage extends StatefulWidget {
  const GestionUbicacionesPage({Key? key}) : super(key: key);

  @override
  State<GestionUbicacionesPage> createState() {
    return _GestionUbicacionesPageState();
  }
}

class _GestionUbicacionesPageState extends State<GestionUbicacionesPage> {
  final UbicacionService _ubicacionService = UbicacionService();

  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarUbicaciones();
  }

  /// Carga las ubicaciones activas desde el servicio.
  Future<void> _cargarUbicaciones() async {
    List<Ubicacion> lista = await _ubicacionService.obtenerUbicacionesActivas();

    setState(() {
      _ubicaciones = lista;
      _cargando = false;
    });
  }

  /// Recarga las ubicaciones (útil después de crear/editar/eliminar).
  void _recargarUbicaciones() {
    setState(() {
      _cargando = true;
    });
    _cargarUbicaciones();
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
          builder: (
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
                    const SizedBox(height: 8.0),
                    Row(
                      children: <Widget>[
                        const Text('Activa'),
                        Switch(
                          value: activa,
                          onChanged: (bool valor) {
                            setStateDialog(
                              () {
                                activa = valor;
                              },
                            );
                          },
                        ),
                      ],
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
                      nombre: nombreController.text.trim(),
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
      text: ubicacion.nombre,
    );
    TextEditingController descripcionController = TextEditingController(
      text: ubicacion.descripcion ?? '',
    );

    bool activa = ubicacion.activa;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (
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
                    const SizedBox(height: 8.0),
                    Row(
                      children: <Widget>[
                        const Text('Activa'),
                        Switch(
                          value: activa,
                          onChanged: (bool valor) {
                            setStateDialog(
                              () {
                                activa = valor;
                              },
                            );
                          },
                        ),
                      ],
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

                    ubicacion.nombre = nombreController.text.trim();
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
            '¿Seguro que deseas eliminar la ubicación "${ubicacion.nombre}"?',
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
    if (_cargando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de ubicaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Vuelve a la pantalla anterior.
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Ubicaciones del almacén',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _abrirDialogoNuevaUbicacion();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva ubicación'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: _ubicaciones.isEmpty
                  ? const Center(
                      child: Text('No hay ubicaciones registradas.'),
                    )
                  : ListView.builder(
                      itemCount: _ubicaciones.length,
                      itemBuilder: (BuildContext context, int index) {
                        Ubicacion ubicacion = _ubicaciones[index];

                        return Card(
                          child: ListTile(
                            onTap: () {
                              _abrirDialogoEditarUbicacion(ubicacion);
                            },
                            title: Text(ubicacion.nombre),
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
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
