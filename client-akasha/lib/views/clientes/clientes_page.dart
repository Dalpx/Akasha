import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cliente.dart';
import '../../services/cliente_service.dart';

/// Pantalla para la gestión de clientes del sistema.
/// Permite listar, crear, editar y desactivar clientes.
class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final ClienteService _clienteService = ClienteService();
  late Future<List<Cliente>> _futureClientes;

  // Expresión regular para validar email
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Expresión regular para validar teléfono (Venezuela)
  static final RegExp _telefonoRegExp = RegExp(
    r'^(0412|0422|0414|0424|0416|0426)\d{7}$',
  );

  @override
  void initState() {
    super.initState();
    _futureClientes = _clienteService.obtenerClientesActivos();
  }

  void _recargarClientes() {
    setState(() {
      _futureClientes = _clienteService.obtenerClientesActivos();
    });
  }

  String _textoEstado(Cliente cliente) {
    return cliente.activo ? 'Activo' : 'Inactivo';
  }

  /// Convierte el tipoDocumento en un texto amigable.
  String _textoTipoDocumento(String tipoDocumento) {
    switch (tipoDocumento) {
      case '1':
        return 'Cédula';
      case '2':
        return 'Pasaporte';
      default:
        return tipoDocumento;
    }
  }

  /// Valida el formato del número de documento según el tipo
  String? _validarDocumento(String? value, String tipoDocumento) {
    if (value == null || value.isEmpty) {
      return 'El número de documento es obligatorio';
    }

    if (tipoDocumento == '1') {
      // Cédula
      final cedulaRegExp = RegExp(r'^(V|E)-\d{8,9}$', caseSensitive: false);
      if (!cedulaRegExp.hasMatch(value)) {
        return 'Formato inválido. Debe ser: V-12345678 o E-12345678';
      }
    } else if (tipoDocumento == '2') {
      // Pasaporte
      final pasaporteRegExp = RegExp(
        r'^P-[A-Z0-9]{9,15}$',
        caseSensitive: false,
      );
      if (!pasaporteRegExp.hasMatch(value)) {
        return 'Formato inválido. Debe ser: P-ABC123456 (9-15 caracteres)';
      }
    }

    return null;
  }

  /// Muestra un diálogo para crear un nuevo cliente con validaciones.
  Future<void> _abrirDialogoNuevoCliente() async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController nombreController = TextEditingController();
    final TextEditingController apellidoController = TextEditingController();
    final TextEditingController tipoDocumentoController = TextEditingController(
      text: '1',
    );
    final TextEditingController nroDocumentoController =
        TextEditingController();
    final TextEditingController telefonoController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController direccionController = TextEditingController();

    String tipoDocumentoSeleccionado = '1';

    // Obtener la lista de clientes actuales para validar unicidad
    final List<Cliente> clientesExistentes = await _clienteService
        .obtenerClientesActivos();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setStateDialog,
              ) {
                return AlertDialog(
                  title: const Text('Nuevo cliente'),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
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
                              final nombre = value?.trim() ?? '';
                              if (nombre.isEmpty) {
                                return 'El nombre es obligatorio';
                              }
                              return null;
                            },
                          ),

                          // 2. Apellido (Obligatorio)
                          TextFormField(
                            controller: apellidoController,
                            decoration: const InputDecoration(
                              labelText: 'Apellido *',
                            ),
                            validator: (value) {
                              final apellido = value?.trim() ?? '';
                              if (apellido.isEmpty) {
                                return 'El apellido es obligatorio';
                              }
                              return null;
                            },
                          ),

                          // 3. Tipo de Documento
                          DropdownButtonFormField<String>(
                            initialValue: tipoDocumentoSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Documento *',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '1',
                                child: Text('Cédula'),
                              ),
                              DropdownMenuItem(
                                value: '2',
                                child: Text('Pasaporte'),
                              ),
                            ],
                            onChanged: (String? value) {
                              setStateDialog(() {
                                tipoDocumentoSeleccionado = value!;
                                tipoDocumentoController.text = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Seleccione un tipo de documento';
                              }
                              return null;
                            },
                          ),

                          // 4. Número de Documento (Obligatorio + Validación de formato)
                          TextFormField(
                            controller: nroDocumentoController,
                            decoration: InputDecoration(
                              labelText: 'Número de Documento *',
                              helperText: tipoDocumentoSeleccionado == '1'
                                  ? 'Formato: V-12345678 o E-12345678'
                                  : 'Formato: P-ABC123456 (9-15 caracteres)',
                            ),
                            validator: (value) {
                              return _validarDocumento(
                                value,
                                tipoDocumentoSeleccionado,
                              );
                            },
                          ),

                          // 5. Teléfono (Validación de formato)
                          TextFormField(
                            controller: telefonoController,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono',
                              helperText: 'Formato: 04141112233 (solo números)',
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!_telefonoRegExp.hasMatch(value)) {
                                  return 'Formato inválido. Ej: 04141112233';
                                }
                              }
                              return null;
                            },
                          ),

                          // 6. Email (Validación de formato)
                          TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (!_emailRegExp.hasMatch(value)) {
                                  return 'Formato de email inválido';
                                }
                              }
                              return null;
                            },
                          ),

                          // 7. Dirección
                          TextFormField(
                            controller: direccionController,
                            decoration: const InputDecoration(
                              labelText: 'Dirección',
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
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
                        final String nroDocumento = nroDocumentoController.text
                            .trim();

                        // Verificar unicidad del documento
                        bool existe = clientesExistentes.any(
                          (c) =>
                              c.nroDocumento.toLowerCase() ==
                              nroDocumento.toLowerCase(),
                        );

                        if (existe) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ya existe un cliente con este número de documento',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (formKey.currentState!.validate()) {
                          final Cliente nuevo = Cliente(
                            nombre: nombreController.text.trim(),
                            apellido: apellidoController.text.trim(),
                            tipoDocumento: tipoDocumentoSeleccionado,
                            nroDocumento: nroDocumento,
                            telefono: telefonoController.text.trim(),
                            email: emailController.text.trim().isNotEmpty
                                ? emailController.text.trim()
                                : null,
                            direccion:
                                direccionController.text.trim().isNotEmpty
                                ? direccionController.text.trim()
                                : null,
                            activo: true,
                          );

                          await _clienteService.crearCliente(nuevo);

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cliente creado exitosamente'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          Navigator.of(context).pop();
                          _recargarClientes();
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

  /// Convierte los distintos formatos de tipoDocumento (código o texto)
  /// al código que usa el dropdown ('1' = Cédula, '2' = Pasaporte)
  String _mapTipoDocumentoToCode(String value) {
    final v = value.toLowerCase();
    if (v == '1' || v == 'cédula' || v == 'cedula') {
      return '1';
    }
    if (v == '2' || v == 'pasaporte') {
      return '2';
    }
    // Si viene algo raro, por defecto '1'
    return '1';
  }

  /// Muestra un diálogo para editar un cliente existente con validaciones.
  Future<void> _abrirDialogoEditarCliente(Cliente cliente) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController nombreController = TextEditingController(
      text: cliente.nombre,
    );
    final TextEditingController apellidoController = TextEditingController(
      text: cliente.apellido,
    );

    // 👉 AQUI: mapear lo que venga de la BBDD al código del dropdown
    final String codigoTipoDocumento = _mapTipoDocumentoToCode(
      cliente.tipoDocumento,
    );

    final TextEditingController tipoDocumentoController = TextEditingController(
      text: codigoTipoDocumento,
    );

    final TextEditingController nroDocumentoController = TextEditingController(
      text: cliente.nroDocumento,
    );
    final TextEditingController telefonoController = TextEditingController(
      text: cliente.telefono ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: cliente.email ?? '',
    );
    final TextEditingController direccionController = TextEditingController(
      text: cliente.direccion ?? '',
    );

    String tipoDocumentoSeleccionado = codigoTipoDocumento;

    // Obtener la lista de clientes actuales para validar unicidad
    final List<Cliente> clientesExistentes = await _clienteService
        .obtenerClientesActivos();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setStateDialog) {
            return AlertDialog(
              title: const Text('Editar cliente'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                          final nombre = value?.trim() ?? '';
                          if (nombre.isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),

                      // 2. Apellido (Obligatorio)
                      TextFormField(
                        controller: apellidoController,
                        decoration: const InputDecoration(
                          labelText: 'Apellido *',
                        ),
                        validator: (value) {
                          final apellido = value?.trim() ?? '';
                          if (apellido.isEmpty) {
                            return 'El apellido es obligatorio';
                          }
                          return null;
                        },
                      ),

                      // 3. Tipo de Documento
                      DropdownButtonFormField<String>(
                        initialValue: tipoDocumentoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Documento *',
                        ),
                        items: const [
                          DropdownMenuItem(value: '1', child: Text('Cédula')),
                          DropdownMenuItem(
                            value: '2',
                            child: Text('Pasaporte'),
                          ),
                        ],
                        onChanged: (String? value) {
                          setStateDialog(() {
                            tipoDocumentoSeleccionado = value!;
                            tipoDocumentoController.text = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Seleccione un tipo de documento';
                          }
                          return null;
                        },
                      ),

                      // 4. Número de Documento (Obligatorio + Validación de formato)
                      TextFormField(
                        controller: nroDocumentoController,
                        decoration: InputDecoration(
                          labelText: 'Número de Documento *',
                          helperText: tipoDocumentoSeleccionado == '1'
                              ? 'Formato: V-12345678 o E-12345678'
                              : 'Formato: P-ABC123456 (9-15 caracteres)',
                        ),
                        validator: (value) {
                          return _validarDocumento(
                            value,
                            tipoDocumentoSeleccionado,
                          );
                        },
                      ),

                      // 5. Teléfono (Validación de formato)
                      TextFormField(
                        controller: telefonoController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          helperText: 'Formato: 04141112233 (solo números)',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!_telefonoRegExp.hasMatch(value)) {
                              return 'Formato inválido. Ej: 04141112233';
                            }
                          }
                          return null;
                        },
                      ),

                      // 6. Email (Validación de formato)
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!_emailRegExp.hasMatch(value)) {
                              return 'Formato de email inválido';
                            }
                          }
                          return null;
                        },
                      ),

                      // 7. Dirección
                      TextFormField(
                        controller: direccionController,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                        ),
                        maxLines: 2,
                      ),

                      // 8. Estado
                      SwitchListTile(
                        title: const Text('Activo'),
                        contentPadding: EdgeInsets.zero,
                        value: cliente.activo,
                        onChanged: (bool value) {
                          setStateDialog(() {
                            cliente.activo = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
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
                    final String nroDocumento = nroDocumentoController.text
                        .trim();

                    // Verificar unicidad del documento (excluyendo el cliente actual)
                    bool existe = clientesExistentes.any(
                      (c) =>
                          c.nroDocumento.toLowerCase() ==
                              nroDocumento.toLowerCase() &&
                          c.idCliente != cliente.idCliente,
                    );

                    if (existe) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ya existe otro cliente con este número de documento',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (formKey.currentState!.validate()) {
                      cliente.nombre = nombreController.text.trim();
                      cliente.apellido = apellidoController.text.trim();
                      cliente.tipoDocumento = tipoDocumentoSeleccionado;
                      cliente.nroDocumento = nroDocumento;
                      cliente.telefono = telefonoController.text.trim();
                      cliente.email = emailController.text.trim().isNotEmpty
                          ? emailController.text.trim()
                          : null;
                      cliente.direccion =
                          direccionController.text.trim().isNotEmpty
                          ? direccionController.text.trim()
                          : null;

                      await _clienteService.actualizarCliente(cliente);

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cliente actualizado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.of(context).pop();
                      _recargarClientes();
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

  void _confirmarEliminarCliente(Cliente cliente) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar desactivación'),
          content: Text(
            '¿Seguro que deseas desactivar al cliente "${cliente.nombre} ${cliente.apellido}"?',
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
                if (cliente.idCliente != null) {
                  await _clienteService.eliminarCliente(cliente.idCliente!);
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cliente "${cliente.nombre}" desactivado'),
                      backgroundColor: Colors.orange,
                    ),
                  );

                  Navigator.of(context).pop();
                  _recargarClientes();
                }
              },
              child: const Text('Desactivar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de clientes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Clientes del sistema',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _abrirDialogoNuevoCliente,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Cliente>>(
                future: _futureClientes,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<Cliente>> snapshot,
                    ) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error al cargar clientes: ${snapshot.error}',
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No se encontraron clientes.'),
                        );
                      }

                      final List<Cliente> clientes = snapshot.data!
                          .where((cliente) => cliente.activo)
                          .toList();

                      return ListView.builder(
                        itemCount: clientes.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Cliente cliente = clientes[index];

                          return Card(
                            child: ListTile(
                              title: Text(
                                '${cliente.nombre} ${cliente.apellido}',
                              ),
                              subtitle: Text(
                                'Documento: ${_textoTipoDocumento(cliente.tipoDocumento)} ${cliente.nroDocumento}\n'
                                'Teléfono: ${cliente.telefono ?? '-'}\n'
                                'Email: ${cliente.email ?? '-'}\n'
                                'Estado: ${_textoEstado(cliente)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Editar',
                                    onPressed: () {
                                      _abrirDialogoEditarCliente(cliente);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: 'Desactivar',
                                    onPressed: () {
                                      _confirmarEliminarCliente(cliente);
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
