import 'package:flutter/material.dart';
import '../../../../../models/ubicacion.dart';
import '../../../../../services/ubicacion_service.dart';

class UbicacionFormDialog extends StatefulWidget {
  final UbicacionService service;
  final Ubicacion? initial;

  const UbicacionFormDialog({
    super.key,
    required this.service,
    this.initial,
  });

  @override
  State<UbicacionFormDialog> createState() => _UbicacionFormDialogState();
}

class _UbicacionFormDialogState extends State<UbicacionFormDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _descripcionController;

  bool _activa = true;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final u = widget.initial;

    _nombreController = TextEditingController(text: u?.nombreAlmacen ?? '');
    _descripcionController = TextEditingController(text: u?.descripcion ?? '');
    _activa = u?.activa ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String _norm(String v) =>
      v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<List<Ubicacion>> _fetchUbicaciones() async {
    final svc = widget.service as dynamic;

    try {
      final res = await svc.obtenerUbicaciones();
      return (res as List).cast<Ubicacion>();
    } catch (_) {}

    try {
      final res = await svc.obtenerUbicacionesActivas();
      return (res as List).cast<Ubicacion>();
    } catch (_) {}

    try {
      final res = await svc.listarUbicaciones();
      return (res as List).cast<Ubicacion>();
    } catch (_) {}

    throw Exception('No se pudo cargar ubicaciones para validar duplicados.');
  }

  Future<bool> _nombreUbicacionDuplicado(String nombre) async {
    final objetivo = _norm(nombre);
    final actual = _norm(widget.initial?.nombreAlmacen ?? '');
    if (_isEdit && objetivo == actual) return false;

    final ubicaciones = await _fetchUbicaciones();
    return ubicaciones.any((u) => _norm(u.nombreAlmacen) == objetivo);
  }

  Future<void> _save() async {
    if (_saving) return;

    final nombre = _nombreController.text.trim();
    final descripcion = _descripcionController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la ubicación es obligatorio.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final duplicado = await _nombreUbicacionDuplicado(nombre);
      if (duplicado) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe una ubicación con ese nombre.')),
        );
        return;
      }

      if (_isEdit) {
        final ubicacion = widget.initial!;
        ubicacion.nombreAlmacen = nombre;
        ubicacion.descripcion = descripcion.isEmpty ? null : descripcion;
        ubicacion.activa = _activa;

        await widget.service.actualizarUbicacion(ubicacion);
      } else {
        final nueva = Ubicacion(
          nombreAlmacen: nombre,
          descripcion: descripcion.isEmpty ? null : descripcion,
          activa: _activa,
        );

        await widget.service.crearUbicacion(nueva);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar ubicación: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar ubicación' : 'Nueva ubicación'),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_isEdit ? 'Guardar cambios' : 'Guardar'),
        ),
      ],
    );
  }
}

Future<bool> showUbicacionFormDialog(
  BuildContext context, {
  required UbicacionService service,
  Ubicacion? initial,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => UbicacionFormDialog(
      service: service,
      initial: initial,
    ),
  );

  return result ?? false;
}
