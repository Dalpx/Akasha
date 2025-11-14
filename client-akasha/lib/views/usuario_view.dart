import 'dart:developer';

import 'package:akasha/models/usuario.dart';
import 'package:akasha/services/usuario_service.dart';
import 'package:flutter/material.dart';

class UsuarioView extends StatefulWidget {
  const UsuarioView({super.key});

  @override
  State<UsuarioView> createState() => _UsuarioViewState();
}

class _UsuarioViewState extends State<UsuarioView> {
  final UsuarioService _usuarioService = UsuarioService();
  late Future<List<Usuario>> _futureUsuarios;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nombreCompletoController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _rolSeleccionado;

  final _roles = const ['super', 'admin', 'almacen'];

  @override
  void initState() {
    super.initState();
    _futureUsuarios = _usuarioService.fetchApiData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nombreCompletoController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _recargarUsuarios() {
    setState(() {
      _futureUsuarios = _usuarioService.fetchApiData();
    });
  }

  void _openUsuarioDialog({Usuario? usuario}) async {
    // Limpiar / precargar campos
    if (usuario == null) {
      _usernameController.clear();
      _passwordController.clear();
      _nombreCompletoController.clear();
      _emailController.clear();
      _rolSeleccionado = _roles.first;
    } else {
      _usernameController.text = usuario.username;
      _passwordController.clear(); // No conocemos la clave actual
      _nombreCompletoController.text = usuario.nombreCompleto;
      _emailController.text = usuario.email;
      _rolSeleccionado = usuario.permiso.isNotEmpty
          ? usuario.permiso
          : _roles.first;
    }

    await showDialog(
      context: context,
      builder: (context) {
        final isEdit = usuario != null;

        return AlertDialog(
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'Editar usuario' : 'Nuevo usuario',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isEdit
                          ? 'Nueva contraseña (obligatoria)'
                          : 'Contraseña',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreCompletoController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _rolSeleccionado,
                    decoration: const InputDecoration(labelText: 'Rol'),
                    items: _roles
                        .map(
                          (rol) =>
                              DropdownMenuItem(value: rol, child: Text(rol)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _rolSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  if (isEdit)
                    const Text(
                      'Al editar debes ingresar una nueva contraseña.',
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = _usernameController.text.trim();
                final pass = _passwordController.text.trim();
                final nomC = _nombreCompletoController.text.trim();
                final email = _emailController.text.trim();
                final rol = _rolSeleccionado;

                // Nota: Para que el backend reciba bien los datos,
                // obligamos a llenar todos los campos incluyendo contraseña
                if (user.isEmpty ||
                    nomC.isEmpty ||
                    email.isEmpty ||
                    rol == null ||
                    pass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Completa todos los campos, incluida la contraseña.',
                      ),
                    ),
                  );
                  return;
                }

                final nuevoUsuario = Usuario(
                  idUsuario: usuario?.idUsuario,
                  username: user,
                  nombreCompleto: nomC,
                  email: email,
                  permiso: rol,
                  password: pass,
                );

                bool ok = false;

                if (usuario == null) {
                  ok = await _usuarioService.createUsuario(nuevoUsuario);
                } else {
                  ok = await _usuarioService.updateUsuario(nuevoUsuario);
                }

                if (!mounted) return;

                if (ok) {
                  Navigator.of(context).pop();
                  _recargarUsuarios();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? 'No se pudo actualizar el usuario.'
                            : 'No se pudo crear el usuario.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmarEliminar(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que deseas eliminar a "${usuario.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final ok = await _usuarioService.deleteUsuario(usuario);
      if (!mounted) return;

      if (ok) {
        _recargarUsuarios();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el usuario.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              log('Redirigir a notificaciones');
            },
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
              log('Cerrar sesión');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-agregar-usuario',
        onPressed: () => _openUsuarioDialog(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Usuario>>(
        // Usamos el Future almacenado en el estado
        future: _futureUsuarios,

        // builder = cómo reaccionar a cada estado del Future
        builder: (context, snapshot) {
          // --- 1) MIENTRAS SE ESPERA RESPUESTA DEL API ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- 2) SI HUBO ERROR EN LA PETICIÓN ---
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar usuarios: ${snapshot.error}'),
            );
          }

          // --- 3) CUANDO LLEGAN LOS DATOS CORRECTAMENTE ---
          if (snapshot.hasData) {
            // final List<Usuario> usuarios = snapshot.data!
            //     .where((usuario) => usuario.activo != 1)
            //     .toList();
            final List<Usuario> usuarios = snapshot.data!.toList();

            // Si la lista está vacía, mostramos un mensaje
            if (usuarios.isEmpty) {
              return const Center(child: Text('No se encontraron usuarios.'));
            }

            for (var element in usuarios) {
              print(element.toString());
            }

            // ListView.builder para renderizar cada usuario
            return ListView.builder(
              itemCount: usuarios.length,
              itemBuilder: (context, index) {
                final usuario = usuarios[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListTile(
                    onTap: () => _openUsuarioDialog(usuario: usuario),
                    onLongPress: () => _confirmarEliminar(usuario),
                    leading: Text(
                      usuario.idUsuario?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    title: Text(usuario.username),
                    subtitle: Text(
                      '${usuario.nombreCompleto}\n${usuario.email}',
                    ),
                    trailing: Text(usuario.permiso),
                  ),
                );
              },
            );
          }
          // Si llegamos aquí, no hay datos ni error (caso poco común)
          return const Center(child: Text('Inicie la carga de datos.'));
        },
      ),
    );
  }
}
