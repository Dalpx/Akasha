import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/usuario_service.dart';

/// Pantalla para la gestión de usuarios del sistema.
/// Permite listar, crear, editar y desactivar usuarios.
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({Key? key}) : super(key: key);

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final UsuarioService _usuarioService = UsuarioService();
  late Future<List<Usuario>> _futureUsuarios;

  @override
  void initState() {
    super.initState();
    _futureUsuarios = _usuarioService.obtenerUsuarios();
  }

  void _recargarUsuarios() {
    setState(() {
      _futureUsuarios = _usuarioService.obtenerUsuarios();
    });
  }

  String _textoEstado(Usuario usuario) {
    final bool estaActivo = usuario.activo == null || usuario.activo == true;
    return estaActivo ? 'Activo' : 'Inactivo';
  }

  /// Convierte el idTipoUsuario en un texto amigable.
  String _textoTipoUsuario(int? idTipoUsuario) {
    switch (idTipoUsuario) {
      case 1:
        return 'Administrador (1)';
      case 2:
        return 'Vendedor (2)';
      case 3:
        return 'Consulta (3)';
      default:
        return idTipoUsuario?.toString() ?? '-';
    }
  }

  Future<void> _abrirDialogoNuevoUsuario() async {
    final TextEditingController nombreUsuarioController =
        TextEditingController();
    final TextEditingController claveController = TextEditingController();
    final TextEditingController nombreCompletoController =
        TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController tipoUsuarioController = TextEditingController();

    bool activo = true;

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
                  title: const Text('Nuevo usuario'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: nombreUsuarioController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de usuario',
                          ),
                        ),
                        TextField(
                          controller: claveController,
                          decoration: const InputDecoration(
                            labelText: 'Clave / hash',
                          ),
                          obscureText: true,
                        ),
                        TextField(
                          controller: nombreCompletoController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                          ),
                        ),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        TextField(
                          controller: tipoUsuarioController,
                          decoration: const InputDecoration(
                            labelText: 'Tipo Usuario',
                            helperText:
                                'Por ejemplo: 1=Admin, 2=Vendedor, 3=Consulta',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8.0),
                        SwitchListTile(
                          title: const Text('Activo'),
                          contentPadding: EdgeInsets.zero,
                          value: activo,
                          onChanged: (bool value) {
                            setStateDialog(() {
                              activo = value;
                            });
                          },
                        ),
                      ],
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
                        final String nombreUsuario = nombreUsuarioController
                            .text
                            .trim();
                        final String clave = claveController.text.trim();

                        // Campos mínimos
                        if (nombreUsuario.isEmpty || clave.isEmpty) {
                          // Si quieres, aquí puedes mostrar un SnackBar de error.
                          return;
                        }

                        final String? nombreCompleto =
                            nombreCompletoController.text.trim().isEmpty
                            ? null
                            : nombreCompletoController.text.trim();

                        final String? email =
                            emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim();

                        final String? tipoUsuario =
                            tipoUsuarioController.text.trim().isEmpty
                            ? null
                            : tipoUsuarioController.text.trim();

                        final Usuario nuevo = Usuario(
                          nombreUsuario: nombreUsuario,
                          claveHash: clave,
                          nombreCompleto: nombreCompleto,
                          email: email,
                          tipoUsuario: tipoUsuario,
                          activo: activo,
                        );

                        await _usuarioService.crearUsuario(nuevo);

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
                        _recargarUsuarios();
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

  Future<void> _abrirDialogoEditarUsuario(Usuario usuario) async {
    final TextEditingController nombreUsuarioController = TextEditingController(
      text: usuario.nombreUsuario,
    );
    final TextEditingController claveController = TextEditingController(
      text: usuario.claveHash,
    );
    final TextEditingController nombreCompletoController =
        TextEditingController(text: usuario.nombreCompleto ?? '');
    final TextEditingController emailController = TextEditingController(
      text: usuario.email ?? '',
    );
    final TextEditingController tipoUsuarioController = TextEditingController(
      text: usuario.tipoUsuario,
    );

    bool activo = usuario.activo == null || usuario.activo == true;

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
                  title: const Text('Editar usuario'),
                  content: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: nombreUsuarioController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de usuario',
                          ),
                        ),
                        TextField(
                          controller: claveController,
                          decoration: const InputDecoration(
                            labelText: 'Clave / hash',
                          ),
                          obscureText: true,
                        ),
                        TextField(
                          controller: nombreCompletoController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo (opcional)',
                          ),
                        ),
                        TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email (opcional)',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        TextField(
                          controller: tipoUsuarioController,
                          decoration: const InputDecoration(
                            labelText: 'Id tipo usuario (opcional)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8.0),
                        SwitchListTile(
                          title: const Text('Activo'),
                          contentPadding: EdgeInsets.zero,
                          value: activo,
                          onChanged: (bool value) {
                            setStateDialog(() {
                              activo = value;
                            });
                          },
                        ),
                      ],
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
                        usuario.nombreUsuario = nombreUsuarioController.text
                            .trim();
                        usuario.claveHash = claveController.text.trim();
                        usuario.nombreCompleto =
                            nombreCompletoController.text.trim().isEmpty
                            ? null
                            : nombreCompletoController.text.trim();
                        usuario.email = emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim();
                        usuario.tipoUsuario =
                            tipoUsuarioController.text.trim().isEmpty
                            ? null
                            : tipoUsuarioController.text.trim();
                        usuario.activo = activo;

                        await _usuarioService.actualizarUsuario(usuario);

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(context).pop();
                        _recargarUsuarios();
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

  void _confirmarEliminarUsuario(Usuario usuario) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Seguro que deseas desactivar al usuario "${usuario.nombreUsuario}"?',
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
                if (usuario.idUsuario != null) {
                  await _usuarioService.eliminarUsuario(usuario.idUsuario!);
                  if (!mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                  _recargarUsuarios();
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
      appBar: AppBar(title: const Text('Gestión de usuarios')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Usuarios del sistema',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _abrirDialogoNuevoUsuario,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Usuario>>(
                future: _futureUsuarios,
                builder: (BuildContext context, AsyncSnapshot<List<Usuario>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar usuarios: ${snapshot.error}',
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron usuarios.'),
                    );
                  }

                  final List<Usuario> usuarios = snapshot.data!;

                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Usuario usuario = usuarios[index];

                      final bool estaActivo =
                          usuario.activo == null || usuario.activo == true;

                      return Card(
                        child: ListTile(
                          title: Text(usuario.nombreUsuario),
                          subtitle: Text(
                            'Nombre completo: ${usuario.nombreCompleto ?? '-'}\n'
                            'Email: ${usuario.email ?? '-'}\n'
                            'Tipo: ${usuario.tipoUsuario}\n'
                            'Estado: ${_textoEstado(usuario)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                estaActivo ? Icons.check_circle : Icons.cancel,
                                color: estaActivo
                                    ? Colors.green
                                    : Colors.redAccent,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Editar',
                                onPressed: () {
                                  _abrirDialogoEditarUsuario(usuario);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Desactivar',
                                onPressed: () {
                                  _confirmarEliminarUsuario(usuario);
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
