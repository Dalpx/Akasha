import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NECESARIO para FilteringTextInputFormatter

import '../../models/usuario.dart';
import '../../services/usuario_service.dart';

/// Pantalla para la gestión de usuarios del sistema.
/// Permite listar, crear, editar y desactivar usuarios.
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final UsuarioService _usuarioService = UsuarioService();
  late Future<List<Usuario>> _futureUsuarios;

  // Rango mínimo y máximo para la clave
  static const int _minClaveLength = 8;
  static const int _maxClaveLength = 64;

  // Expresión regular para validar Nombre Completo (letras y al menos dos palabras)
  static final RegExp _nombreCompletoRegExp = RegExp(
    r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ]+(?: [a-zA-ZáéíóúÁÉÍÓÚñÑ]+)+$',
  );
  
  // Expresión regular para validar formato de Email (estándar)
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

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
    final bool estaActivo = usuario.activo == true;
    return estaActivo ? 'Activo' : 'Inactivo';
  }

  /// Convierte el idTipoUsuario en un texto amigable.
  String _textoTipoUsuario(String? tipoUsuario) {
    int? idTipoUsuario = int.tryParse(tipoUsuario ?? '');
    switch (idTipoUsuario) {
      case 1:
        return 'Administrador (1)';
      case 2:
        return 'Vendedor (2)';
      case 3:
        return 'Consulta (3)';
      default:
        return tipoUsuario ?? '-';
    }
  }

  /// Muestra un diálogo para crear un nuevo usuario con validaciones.
  Future<void> _abrirDialogoNuevoUsuario() async {
    // Clave Global para validar el formulario
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController nombreUsuarioController =
        TextEditingController();
    final TextEditingController claveController = TextEditingController();
    final TextEditingController nombreCompletoController =
        TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController tipoUsuarioController = TextEditingController();

    bool activo = true;

    // Obtener la lista de usuarios actuales para validar unicidad
    final List<Usuario> usuariosExistentes =
        await _usuarioService.obtenerUsuarios();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setStateDialog,
          ) {
            return AlertDialog(
              title: const Text('Nuevo usuario'),
              // 1. Envolvemos el contenido en SingleChildScrollView y Form
              content: SingleChildScrollView(
                child: Form(
                  key: formKey, // Asignamos la clave
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // 1. Nombre de usuario (Obligatorio + No existente)
                      TextFormField(
                        controller: nombreUsuarioController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de usuario *',
                        ),
                        validator: (value) {
                          final nombre = value?.trim() ?? '';
                          if (nombre.isEmpty) {
                            return 'El campo "Nombre de usuario" es obligatorio.';
                          }
                          // Validación de unicidad
                          bool existe = usuariosExistentes.any(
                            (u) =>
                                u.nombreUsuario.toLowerCase() ==
                                nombre.toLowerCase(),
                          );
                          if (existe) {
                            return 'El nombre de usuario ya existe.';
                          }
                          return null;
                        },
                      ),
                      // 2. Clave / hash (Obligatorio + Longitud 8-64)
                      TextFormField(
                        controller: claveController,
                        decoration: InputDecoration(
                          labelText: 'Clave / hash *',
                          helperText:
                              'Mínimo $_minClaveLength y máximo $_maxClaveLength caracteres.',
                        ),
                        obscureText: true,
                        validator: (value) {
                          final clave = value?.trim() ?? '';
                          if (clave.isEmpty) {
                            return 'El campo "Clave" es obligatorio.';
                          }
                          if (clave.length < _minClaveLength ||
                              clave.length > _maxClaveLength) {
                            return 'La clave debe tener entre $_minClaveLength y $_maxClaveLength caracteres.';
                          }
                          return null;
                        },
                      ),
                      // 3. Nombre completo (Obligatorio + Validación de dos palabras, letras y espacios)
                      TextFormField(
                        controller: nombreCompletoController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo *',
                          helperText:
                              'Debe contener al menos un nombre y un apellido.',
                        ),
                        validator: (value) {
                          final nombreCompleto = value?.trim() ?? '';
                          
                          // Hacemos que sea obligatorio
                          if (nombreCompleto.isEmpty) {
                            return 'El campo "Nombre completo" es obligatorio.';
                          }

                          // Validación de formato con Expresión Regular
                          if (!_nombreCompletoRegExp.hasMatch(nombreCompleto)) {
                            return 'Debe contener al menos un nombre y un apellido (solo letras y espacios).';
                          }
                          return null;
                        },
                      ),
                      // 4. Email (Validación de formato, AHORA OBLIGATORIO)
                      TextFormField(
                        controller: emailController,
                        decoration:
                            const InputDecoration(labelText: 'Email *'), // Etiqueta actualizada
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          
                          // Hacemos que sea obligatorio
                          if (email.isEmpty) {
                            return 'El campo "Email" es obligatorio.';
                          }
                          
                          // Validación de formato
                          if (!_emailRegExp.hasMatch(email)) {
                            return 'El formato del correo electrónico proporcionado es incorrecto.';
                          }
                          return null;
                        },
                      ),
                      // 5. Tipo Usuario (Obligatorio + Solo 1, 2 o 3)
                      TextFormField(
                        controller: tipoUsuarioController,
                        decoration: const InputDecoration(
                          labelText: 'Tipo Usuario *',
                          helperText:
                              'Debe ser: 1=Admin, 2=Vendedor, o 3=Consulta',
                        ),
                        keyboardType: TextInputType.number,
                        // Limita a solo dígitos
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          final tipo = value?.trim() ?? '';
                          if (tipo.isEmpty) {
                            return 'El campo "Tipo Usuario" es obligatorio.';
                          }
                          final int? idTipo = int.tryParse(tipo);
                          if (idTipo == null || idTipo < 1 || idTipo > 3) {
                            return 'El valor debe ser 1, 2 o 3.';
                          }
                          return null;
                        },
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
                    final String nombreUsuario =
                        nombreUsuarioController.text.trim();

                    // **INICIO: Lógica para mostrar SnackBar de unicidad antes de validar todo el formulario**
                    // Re-verificar unicidad aquí, independientemente del validador del campo
                    bool existe = usuariosExistentes.any(
                      (u) =>
                          u.nombreUsuario.toLowerCase() ==
                          nombreUsuario.toLowerCase(),
                    );

                    if (existe) {
                      // Si el nombre de usuario ya existe, mostramos el SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ El nombre de usuario ya está registrado. Por favor, elige uno diferente.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      // Detenemos la ejecución para que el usuario pueda corregir
                      return; 
                    }
                    // **FIN: Lógica para mostrar SnackBar de unicidad**
                    
                    // Disparamos la validación del formulario (si pasamos el chequeo de unicidad con SnackBar)
                    if (formKey.currentState!.validate()) {
                      final String clave = claveController.text.trim();
                      final String nombreCompleto =
                          nombreCompletoController.text.trim();
                      
                      // El email es obligatorio y ya validado
                      final String email = emailController.text.trim();

                      // Aquí ya sabemos que tipoUsuarioController.text es '1', '2' o '3'
                      final String tipoUsuario =
                          tipoUsuarioController.text.trim();

                      final Usuario nuevo = Usuario(
                        nombreUsuario: nombreUsuario,
                        claveHash: clave,
                        nombreCompleto: nombreCompleto,
                        email: email,
                        // Asignamos el valor validado
                        tipoUsuario: tipoUsuario,
                        activo: activo,
                      );

                      await _usuarioService.crearUsuario(nuevo);

                      if (!mounted) {
                        return;
                      }

                      // Muestra un SnackBar de éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Usuario creado exitosamente.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      Navigator.of(context).pop();
                      _recargarUsuarios();
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

  /// Muestra un diálogo para editar un usuario existente con validaciones.
  Future<void> _abrirDialogoEditarUsuario(Usuario usuario) async {
    // Clave Global para validar el formulario
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController nombreUsuarioController = TextEditingController(
      text: usuario.nombreUsuario,
    );
    final TextEditingController claveController = TextEditingController(
      text: usuario.claveHash,
    );
    // El campo de nombre completo debe inicializarse con un valor no nulo
    final TextEditingController nombreCompletoController =
        TextEditingController(text: usuario.nombreCompleto ?? '');
    // El campo de email debe inicializarse con un valor no nulo
    final TextEditingController emailController = TextEditingController(
      text: usuario.email ?? '',
    );
    final TextEditingController tipoUsuarioController = TextEditingController(
      text: usuario.tipoUsuario,
    );

    bool activo = usuario.activo == true;

    // Obtener la lista de usuarios actuales para validar unicidad
    final List<Usuario> usuariosExistentes =
        await _usuarioService.obtenerUsuarios();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            void Function(void Function()) setStateDialog,
          ) {
            return AlertDialog(
              title: const Text('Editar usuario'),
              // 1. Envolvemos el contenido en SingleChildScrollView y Form
              content: SingleChildScrollView(
                child: Form(
                  key: formKey, // Asignamos la clave
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // 1. Nombre de usuario (Obligatorio + No existente, excluyendo el actual)
                      TextFormField(
                        controller: nombreUsuarioController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de usuario *',
                        ),
                        validator: (value) {
                          final nombre = value?.trim() ?? '';
                          if (nombre.isEmpty) {
                            return 'El campo "Nombre de usuario" es obligatorio.';
                          }
                          // Validación de unicidad (ignorando el ID del usuario que estamos editando)
                          bool existe = usuariosExistentes.any(
                            (u) =>
                                u.nombreUsuario.toLowerCase() ==
                                    nombre.toLowerCase() &&
                                u.idUsuario != usuario.idUsuario,
                          );
                          if (existe) {
                            return 'El nombre de usuario ya existe.';
                          }
                          return null;
                        },
                      ),
                      // 2. Clave / hash (Obligatorio + Longitud 8-64)
                      TextFormField(
                        controller: claveController,
                        decoration: InputDecoration(
                          labelText: 'Clave / hash *',
                          helperText:
                              'Mínimo $_minClaveLength y máximo $_maxClaveLength caracteres.',
                        ),
                        obscureText: true,
                        validator: (value) {
                          final clave = value?.trim() ?? '';
                          if (clave.isEmpty) {
                            return 'El campo "Clave" es obligatorio.';
                          }
                          if (clave.length < _minClaveLength ||
                              clave.length > _maxClaveLength) {
                            return 'La clave debe tener entre $_minClaveLength y $_maxClaveLength caracteres.';
                          }
                          return null;
                        },
                      ),
                      // 3. Nombre completo (Obligatorio + Validación de dos palabras, letras y espacios)
                      TextFormField(
                        controller: nombreCompletoController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo *',
                          helperText:
                              'Debe contener al menos un nombre y un apellido.',
                        ),
                        validator: (value) {
                          final nombreCompleto = value?.trim() ?? '';
                          
                          // Hacemos que sea obligatorio
                          if (nombreCompleto.isEmpty) {
                            return 'El campo "Nombre completo" es obligatorio.';
                          }

                          // Validación de formato con Expresión Regular
                          if (!_nombreCompletoRegExp.hasMatch(nombreCompleto)) {
                            return 'Debe contener al menos un nombre y un apellido (solo letras y espacios).';
                          }
                          return null;
                        },
                      ),
                      // 4. Email (Validación de formato, AHORA OBLIGATORIO)
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *', // Etiqueta actualizada
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          
                          // Hacemos que sea obligatorio
                          if (email.isEmpty) {
                            return 'El campo "Email" es obligatorio.';
                          }
                          
                          // Validación de formato
                          if (!_emailRegExp.hasMatch(email)) {
                            return 'El formato del correo electrónico proporcionado es incorrecto.';
                          }
                          return null;
                        },
                      ),
                      // 5. Tipo Usuario (Obligatorio + Solo 1, 2 o 3)
                      TextFormField(
                        controller: tipoUsuarioController,
                        decoration: const InputDecoration(
                          labelText: 'Tipo Usuario *',
                          helperText:
                              'Debe ser: 1=Admin, 2=Vendedor, o 3=Consulta',
                        ),
                        keyboardType: TextInputType.number,
                        // Limita a solo dígitos
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          final tipo = value?.trim() ?? '';
                          if (tipo.isEmpty) {
                            return 'El campo "Tipo Usuario" es obligatorio.';
                          }
                          final int? idTipo = int.tryParse(tipo);
                          if (idTipo == null || idTipo < 1 || idTipo > 3) {
                            return 'El valor debe ser 1, 2 o 3.';
                          }
                          return null;
                        },
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
                    final String nombreUsuario =
                        nombreUsuarioController.text.trim();

                    // **INICIO: Lógica para mostrar SnackBar de unicidad antes de validar todo el formulario**
                    // Re-verificar unicidad aquí, independientemente del validador del campo
                    bool existe = usuariosExistentes.any(
                      (u) =>
                          u.nombreUsuario.toLowerCase() ==
                              nombreUsuario.toLowerCase() &&
                          u.idUsuario != usuario.idUsuario,
                    );

                    if (existe) {
                      // Si el nombre de usuario ya existe, mostramos el SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ El nombre de usuario ya está registrado para otro usuario. Por favor, elige uno diferente.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      // Detenemos la ejecución para que el usuario pueda corregir
                      return; 
                    }
                    // **FIN: Lógica para mostrar SnackBar de unicidad**


                    // Disparamos la validación del formulario
                    if (formKey.currentState!.validate()) {
                      // Los campos requeridos ya fueron validados, podemos asignar
                      usuario.nombreUsuario =
                          nombreUsuarioController.text.trim();
                      usuario.claveHash = claveController.text.trim();
                      usuario.nombreCompleto =
                          nombreCompletoController.text.trim();
                      
                      // El email es obligatorio y ya validado
                      usuario.email = emailController.text.trim();
                          
                      // Asignamos el valor validado
                      usuario.tipoUsuario = tipoUsuarioController.text.trim();
                      usuario.activo = activo;

                      await _usuarioService.actualizarUsuario(usuario);

                      if (!mounted) {
                        return;
                      }

                      // Muestra un SnackBar de éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Usuario actualizado exitosamente.'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.of(context).pop();
                      _recargarUsuarios();
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
                  
                  // Muestra un SnackBar de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🗑️ Usuario "${usuario.nombreUsuario}" desactivado.'),
                      backgroundColor: Colors.orange,
                    ),
                  );

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
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<Usuario>> snapshot,
                ) {
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

                  final List<Usuario> usuarios =
                      snapshot.data!.where((usuario) => usuario.activo == true).toList();

                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Usuario usuario = usuarios[index];

                      return Card(
                        child: ListTile(
                          title: Text(usuario.nombreUsuario),
                          subtitle: Text(
                            'Nombre completo: ${usuario.nombreCompleto ?? '-'}\n'
                            'Email: ${usuario.email ?? '-'}\n'
                            'Tipo: ${_textoTipoUsuario(usuario.tipoUsuario)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
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

// Extensión para simplificar la búsqueda de elementos iniciales en listas
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}