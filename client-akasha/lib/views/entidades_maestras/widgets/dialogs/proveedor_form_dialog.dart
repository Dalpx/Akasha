import 'package:flutter/material.dart';
import '../../../../../models/proveedor.dart';
import '../../../../../services/proveedor_service.dart';

class ProveedorFormDialog extends StatefulWidget {
  final ProveedorService service;
  final Proveedor? initial;

  const ProveedorFormDialog({
    super.key,
    required this.service,
    this.initial,
  });

  @override
  State<ProveedorFormDialog> createState() => _ProveedorFormDialogState();
}

class _ProveedorFormDialogState extends State<ProveedorFormDialog> {
  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _correoController;
  late final TextEditingController _direccionController;

  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;

    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _telefonoController = TextEditingController(text: p?.telefono ?? '');
    _correoController = TextEditingController(text: p?.correo ?? '');
    _direccionController = TextEditingController(text: p?.direccion ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  String _norm(String v) =>
      v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<List<Proveedor>> _fetchProveedores() async {
    final svc = widget.service as dynamic;

    try {
      final res = await svc.obtenerProveedores();
      return (res as List).cast<Proveedor>();
    } catch (_) {}

    try {
      final res = await svc.listarProveedores();
      return (res as List).cast<Proveedor>();
    } catch (_) {}

    throw Exception('No se pudo cargar proveedores para validar duplicados.');
  }

  Future<bool> _nombreProveedorDuplicado(String nombre) async {
    final objetivo = _norm(nombre);
    final actual = _norm(widget.initial?.nombre ?? '');
    if (_isEdit && objetivo == actual) return false;

    final proveedores = await _fetchProveedores();
    return proveedores.any((p) => _norm(p.nombre) == objetivo);
  }

  Future<void> _save() async {
    if (_saving) return;

    final nombre = _nombreController.text.trim();
    final telefono = _telefonoController.text.trim();
    final correo = _correoController.text.trim();
    final direccion = _direccionController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final duplicado = await _nombreProveedorDuplicado(nombre);
      if (duplicado) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe un proveedor con ese nombre.')),
        );
        return;
      }

      if (_isEdit) {
        final proveedor = widget.initial!;
        proveedor.nombre = nombre;
        proveedor.telefono = telefono;
        proveedor.correo = correo.isEmpty ? null : correo;
        proveedor.direccion = direccion.isEmpty ? null : direccion;

        await widget.service.actualizarProveedor(proveedor);
      } else {
        final nuevo = Proveedor(
          nombre: nombre,
          telefono: telefono,
          correo: correo.isEmpty ? null : correo,
          direccion: direccion.isEmpty ? null : direccion,
          activo: true,
        );

        await widget.service.crearProveedor(nuevo);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar proveedor: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar proveedor' : 'Nuevo proveedor'),
      content: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _correoController,
              decoration: const InputDecoration(labelText: 'Correo'),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: _direccionController,
              decoration: const InputDecoration(labelText: 'Dirección'),
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

Future<bool> showProveedorFormDialog(
  BuildContext context, {
  required ProveedorService service,
  Proveedor? initial,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ProveedorFormDialog(
      service: service,
      initial: initial,
    ),
  );

  return result ?? false;
}
