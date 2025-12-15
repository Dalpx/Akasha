import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../models/producto.dart';
import '../../../../../models/proveedor.dart';
import '../../../../../models/categoria.dart';

class ProductoFormDialog extends StatefulWidget {
  final Producto? producto; // Si es null, es modo CREAR. Si no, es EDITAR.
  final List<Proveedor> proveedores;
  final List<Categoria> categorias;
  final List<Producto> productosExistentes; // Para validar unicidad del SKU

  const ProductoFormDialog({
    super.key,
    this.producto,
    required this.proveedores,
    required this.categorias,
    required this.productosExistentes,
  });

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _skuController;
  late TextEditingController _descripcionController;
  late TextEditingController _costoController;
  late TextEditingController _ventaController;

  Proveedor? _proveedorSeleccionado;
  Categoria? _categoriaSeleccionada;

  // Constantes internas
  static const int _minSKULength = 8;
  static const int _maxSKULength = 12;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;

    // Inicializar controladores con datos si es edición, o vacíos si es nuevo
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _descripcionController = TextEditingController(text: p?.descripcion ?? '');
    _costoController = TextEditingController(text: p?.precioCosto.toString() ?? '');
    _ventaController = TextEditingController(text: p?.precioVenta.toString() ?? '');

    // Inicializar Dropdowns buscando el objeto correcto en la lista
    if (p != null) {
      try {
        _proveedorSeleccionado = widget.proveedores.firstWhere(
          (prov) => prov.idProveedor == p.idProveedor,
        );
      } catch (_) {}

      try {
        _categoriaSeleccionada = widget.categorias.firstWhere(
          (cat) => cat.idCategoria == p.idCategoria,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _skuController.dispose();
    _descripcionController.dispose();
    _costoController.dispose();
    _ventaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool esEdicion = widget.producto != null;

    return AlertDialog(
      title: Text(esEdicion ? 'Editar producto' : 'Nuevo producto'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 1. Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              // 2. SKU
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU *'),
                validator: (value) => _validarSku(value),
              ),
              const SizedBox(height: 12.0),
              // 3. Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12.0),
              // 4. Precio Costo
              TextFormField(
                controller: _costoController,
                decoration: const InputDecoration(labelText: 'Precio costo *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) => _validarNumero(value, 'Precio costo'),
              ),
              const SizedBox(height: 12.0),
              // 5. Precio Venta
              TextFormField(
                controller: _ventaController,
                decoration: const InputDecoration(labelText: 'Precio venta *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) => _validarNumero(value, 'Precio venta'),
              ),
              const SizedBox(height: 12.0),
              // 6. Proveedor
              DropdownButtonFormField<Proveedor>(
                value: _proveedorSeleccionado,
                decoration: const InputDecoration(labelText: 'Proveedor *'),
                items: widget.proveedores.map((prov) {
                  return DropdownMenuItem(value: prov, child: Text(prov.nombre));
                }).toList(),
                onChanged: (val) => setState(() => _proveedorSeleccionado = val),
                validator: (val) => val == null ? 'El proveedor es obligatorio.' : null,
              ),
              const SizedBox(height: 12.0),
              // 7. Categoría
              DropdownButtonFormField<Categoria>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(labelText: 'Categoría *'),
                items: widget.categorias.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.nombreCategoria));
                }).toList(),
                onChanged: (val) => setState(() => _categoriaSeleccionada = val),
                validator: (val) => val == null ? 'La categoría es obligatoria.' : null,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cancelar retorna null
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardarFormulario,
          child: Text(esEdicion ? 'Guardar cambios' : 'Guardar'),
        ),
      ],
    );
  }

  String? _validarNumero(String? value, String campoName) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$campoName es obligatorio.';
    
    final numValue = double.tryParse(v);
    if (numValue == null) return 'Debe ser un número válido.';
    
    // Nueva validación específica para Precio Venta: debe ser >= Precio Costo
    if (campoName == 'Precio venta') {
      final costoText = _costoController.text.trim();
      final costoValue = double.tryParse(costoText);

      // Si el costo es válido y el precio de venta es menor, mostrar error
      if (costoValue != null && numValue < costoValue) {
        return 'El precio de venta debe ser mayor o igual al precio costo.';
      }
    }

    return null;
  }

  String? _validarSku(String? value) {
    final sku = value?.trim() ?? '';
    if (sku.isEmpty) return 'El SKU es obligatorio.';
    
    if (sku.length < _minSKULength || sku.length > _maxSKULength) {
      return 'Longitud entre $_minSKULength y $_maxSKULength caracteres.';
    }

    // Validación de unicidad
    // Buscamos si existe algun producto con el MISMO sku pero DISTINTO ID (para permitir editarse a sí mismo)
    bool existe = widget.productosExistentes.any((p) {
      bool mismoSku = p.sku.toLowerCase() == sku.toLowerCase();
      // Si estamos editando (widget.producto != null), ignoramos nuestro propio ID
      bool esOtroProducto = widget.producto == null || p.idProducto != widget.producto!.idProducto;
      return mismoSku && esOtroProducto;
    });

    if (existe) return 'El SKU ya está registrado.';
    return null;
  }

  void _guardarFormulario() {
    if (_formKey.currentState!.validate()) {
      // Construir el objeto Producto
      final nuevoProducto = Producto(
        // Si estamos editando, preservamos el ID original
        idProducto: widget.producto?.idProducto, 
        nombre: _nombreController.text.trim(),
        sku: _skuController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        precioCosto: double.tryParse(_costoController.text) ?? 0.0,
        precioVenta: double.tryParse(_ventaController.text) ?? 0.0,
        idProveedor: _proveedorSeleccionado!.idProveedor.toString(),
        idCategoria: _categoriaSeleccionada!.idCategoria.toString(),
        activo: true, // Asumimos true por defecto o mantenemos lógica
      );

      // Retornar el objeto creado/editado al padre
      Navigator.of(context).pop(nuevoProducto);
    }
  }
}