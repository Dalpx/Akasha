import 'package:flutter/material.dart';
import '../../../../../models/categoria.dart';
import '../../../../../services/categoria_service.dart';

class CategoriaFormDialog extends StatefulWidget {
  final CategoriaService service;
  final Categoria? initial;

  const CategoriaFormDialog({
    super.key,
    required this.service,
    this.initial,
  });

  @override
  State<CategoriaFormDialog> createState() => _CategoriaFormDialogState();
}

class _CategoriaFormDialogState extends State<CategoriaFormDialog> {
  late final TextEditingController _nombreController;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.initial?.nombreCategoria ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  String _norm(String v) =>
      v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<List<Categoria>> _fetchCategorias() async {
    final svc = widget.service as dynamic;

    try {
      final res = await svc.obtenerCategorias();
      return (res as List).cast<Categoria>();
    } catch (_) {}

    try {
      final res = await svc.listarCategorias();
      return (res as List).cast<Categoria>();
    } catch (_) {}

    throw Exception('No se pudo cargar categorías para validar duplicados.');
  }

  Future<bool> _nombreCategoriaDuplicado(String nombre) async {
    final objetivo = _norm(nombre);
    final actual = _norm(widget.initial?.nombreCategoria ?? '');
    if (_isEdit && objetivo == actual) return false;

    final categorias = await _fetchCategorias();
    return categorias.any((c) => _norm(c.nombreCategoria) == objetivo);
  }

  Future<void> _save() async {
    if (_saving) return;

    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final duplicado = await _nombreCategoriaDuplicado(nombre);
      if (duplicado) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe una categoría con ese nombre.')),
        );
        return;
      }

      if (_isEdit) {
        final categoria = widget.initial!;
        categoria.nombreCategoria = nombre;
        await widget.service.actualizarCategoria(categoria);
      } else {
        final nueva = Categoria(
          nombreCategoria: nombre,
          activo: true,
        );
        await widget.service.crearCategoria(nueva);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar categoría: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar categoría' : 'Nueva categoría'),
      content: TextField(
        controller: _nombreController,
        decoration: const InputDecoration(labelText: 'Nombre categoría'),
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

Future<bool> showCategoriaFormDialog(
  BuildContext context, {
  required CategoriaService service,
  Categoria? initial,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => CategoriaFormDialog(
      service: service,
      initial: initial,
    ),
  );

  return result ?? false;
}
