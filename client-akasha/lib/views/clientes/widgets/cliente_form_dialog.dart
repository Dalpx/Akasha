import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/cliente.dart';

class ClienteFormDialog extends StatefulWidget {
  final Cliente? cliente; // null para crear, Cliente para editar
  final List<Cliente> clientesExistentes;

  const ClienteFormDialog({
    super.key,
    this.cliente,
    required this.clientesExistentes,
  });

  @override
  State<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<ClienteFormDialog> {
  // Expresiones regulares
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _telefonoRegExp = RegExp(
    r'^(0412|0422|0414|0424|0416|0426)\d{7}$',
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _nroDocumentoController;
  late TextEditingController _telefonoController;
  late TextEditingController _emailController;
  late TextEditingController _direccionController;

  // Estado para el Dropdown
  late String _tipoDocumentoSeleccionado;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    
    final String codigoDocInicial = c != null 
        ? _mapTipoDocumentoToCode(c.tipoDocumento) 
        : '1';
    
    _nombreController = TextEditingController(text: c?.nombre ?? '');
    _apellidoController = TextEditingController(text: c?.apellido ?? '');
    _nroDocumentoController = TextEditingController(text: c?.nroDocumento ?? '');
    _telefonoController = TextEditingController(text: c?.telefono ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _direccionController = TextEditingController(text: c?.direccion ?? '');
    _tipoDocumentoSeleccionado = codigoDocInicial;
  }


  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _nroDocumentoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }


  String _mapTipoDocumentoToCode(String value) {
    if (value.toUpperCase().contains('CEDULA')) return '1';
    if (value.toUpperCase().contains('PASAPORTE')) return '2';
    return '1';
  }


  String? _validarDocumento(String? value, String tipoDocumento) {
    final doc = value?.trim().toUpperCase() ?? '';
    if (doc.isEmpty) return 'El número de documento es obligatorio.';

    if (tipoDocumento == '1') {
      final RegExp cedulaRegExp = RegExp(r'^[VEG]-\d{7,10}$');
      if (!cedulaRegExp.hasMatch(doc)) {
        return 'Formato inválido. Ej: V-12345678.';
      }
    } else if (tipoDocumento == '2') {
      final RegExp pasaporteRegExp = RegExp(r'^P-[A-Z0-9]{8,14}$');
      if (!pasaporteRegExp.hasMatch(doc)) {
        return 'Formato inválido. Debe ser P- seguido de 8 a 14 caracteres alfanuméricos.';
      }
    }
    return null;
  }

  bool _validarUnicidadDocumento(String nroDocumento) {
    final documentoLimpio = nroDocumento.trim().toLowerCase();

    for (final clienteExistente in widget.clientesExistentes) {
      final documentoExistenteLimpio = clienteExistente.nroDocumento.trim().toLowerCase();

      if (documentoExistenteLimpio == documentoLimpio) {
        if (widget.cliente != null && 
            clienteExistente.idCliente == widget.cliente!.idCliente) {
          continue; 
        }
        return false; 
      }
    }
    return true;
  }

  void _guardarFormulario() {
    if (_formKey.currentState!.validate()) {
      final String nroDocumento = _nroDocumentoController.text.trim();
      
      // Muestra error si el documento está duplicado
      if (!_validarUnicidadDocumento(nroDocumento)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El número de documento ya está registrado por otro cliente.'), backgroundColor: Colors.red),
        );
        return; 
      }
      
      // Construir el objeto Cliente
      final Cliente clienteResultado = Cliente(
        idCliente: widget.cliente?.idCliente,
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        tipoDocumento: _tipoDocumentoSeleccionado,
        nroDocumento: nroDocumento,
        telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : "null",
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        direccion: _direccionController.text.trim().isNotEmpty ? _direccionController.text.trim() : null,
        activo: widget.cliente?.activo ?? true,
      );

      Navigator.of(context).pop(clienteResultado);
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool esEdicion = widget.cliente != null;

    return AlertDialog(
      title: Text(esEdicion ? 'Editar cliente' : 'Nuevo cliente'),
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
                  if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              // 2. Apellido
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'El apellido es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              // 3. Tipo de Documento
              DropdownButtonFormField<String>(
                value: _tipoDocumentoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo de Documento *'),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('Cédula')),
                  DropdownMenuItem(value: '2', child: Text('Pasaporte')),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _tipoDocumentoSeleccionado = value!;
                  });
                },
                validator: (value) => value == null ? 'Seleccione un tipo de documento' : null,
              ),
              const SizedBox(height: 12.0),
              // 4. Número de Documento 
              TextFormField(
                controller: _nroDocumentoController,
                decoration: InputDecoration(
                  labelText: 'Número de Documento *',
                  helperText: _tipoDocumentoSeleccionado == '1'
                      ? 'Ej: V-12345678'
                      : 'Ej: P-ABC123456',
                ),
                validator: (value) => _validarDocumento(value, _tipoDocumentoSeleccionado),
              ),
              const SizedBox(height: 12.0),
              // 5. Teléfono
              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: 'Teléfono', helperText: 'Ej: 04141112233'),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty && !_telefonoRegExp.hasMatch(value)) {
                    return 'Formato inválido. Ej: 04141112233';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              // 6. Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !_emailRegExp.hasMatch(value)) {
                    return 'Formato de email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              // 7. Dirección
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardarFormulario,
          child: Text(esEdicion ? 'Guardar cambios' : 'Guardar'),
        ),
      ],
    );
  }
}