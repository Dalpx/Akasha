
import 'package:akasha/views/seguridad/widgets/usuario_detalles.dart';
import 'package:akasha/views/seguridad/widgets/usuario_form_dialog.dart';
import 'package:akasha/views/seguridad/widgets/usuario_list_item.dart';
import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';

/// Pantalla para la gestión de usuarios del sistema.
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

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

  Future<void> _abrirFormularioUsuario({Usuario? usuarioEditar}) async {
    final List<Usuario> usuariosActuales = await _usuarioService
        .obtenerUsuarios();

    if (!mounted) return;

    final Usuario? usuarioResultado = await showDialog<Usuario>(
      context: context,
      builder: (context) => UsuarioFormDialog(
        usuario: usuarioEditar, // Si es null, el diálogo es 'Nuevo'
        usuariosExistentes: usuariosActuales,
      ),
    );

    if (usuarioResultado != null) {
      if (usuarioEditar == null) {
        // CREAR
        await _usuarioService.crearUsuario(usuarioResultado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // EDITAR
        await _usuarioService.actualizarUsuario(usuarioResultado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      _recargarUsuarios();
    }
  }

  Future<void> _confirmarEliminarUsuario(Usuario usuario) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          usuario.activo ? 'Desactivar Usuario' : 'Reactivar Usuario',
        ),
        content: Text(
          usuario.activo
              ? '¿Está seguro de que desea desactivar al usuario ${usuario.nombreCompleto}? Esto inhabilitará su acceso.'
              : '¿Está seguro de que desea reactivar al usuario ${usuario.nombreCompleto}?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              usuario.activo ? 'Desactivar' : 'Reactivar',
              style: TextStyle(
                color: usuario.activo ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (usuario.activo) {
        await _usuarioService.eliminarUsuario(usuario.idUsuario!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Usuario ${usuario.activo ? 'desactivado' : 'reactivado'} correctamente.',
              ),
              backgroundColor: usuario.activo ? Colors.red : Colors.green,
            ),
          );
        }
        _recargarUsuarios();
      }
    }
  }

  void _mostrarDetallesDeUsuario(Usuario usuario) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return UsuarioDetalles(usuario: usuario);
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usuario',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text("Gestión de usuarios"),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _abrirFormularioUsuario();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: FutureBuilder<List<Usuario>>(
                    future: _futureUsuarios,
                    builder: (context, snapshot) {
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
                          child: Text('No hay usuarios registrados.'),
                        );
                      }

                      final usuarios = snapshot.data!
                          .where((usuario) => usuario.activo)
                          .toList();

                      // Aquí se usa el widget extraído UsuarioListItem
                      return ListView.builder(
                        itemCount: usuarios.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Usuario usuario = usuarios[index];

                          return UsuarioListItem(
                            usuario: usuario,
                            // El botón de editar ahora llama a la función unificada
                            onEditar: () {
                              _abrirFormularioUsuario(usuarioEditar: usuario);
                            },
                            // El botón de activar/desactivar llama a la función de la página
                            onDesactivar: () {
                              _confirmarEliminarUsuario(usuario);
                            },
                            onVerDetalle: (){
                              _mostrarDetallesDeUsuario(usuario);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
