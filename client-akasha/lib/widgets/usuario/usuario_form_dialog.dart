import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/usuario.dart';

class UsuarioFormDialog extends StatefulWidget {
  final Usuario? usuario; // null para crear, Usuario para editar
  final List<Usuario> usuariosExistentes; // Para validar unicidad del email

  const UsuarioFormDialog({
    super.key,
    this.usuario,
    required this.usuariosExistentes,
  });

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  // Constantes y RegEx movidas de UsuariosPage
  static const int _minClaveLength = 8;
  static const int _maxClaveLength = 64;

  static final RegExp _nombreCompletoRegExp = RegExp(
    r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ]+(?: [a-zA-ZáéíóúÁÉÍÓÚñÑ]+)+$',
  );
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _nombreCompletoController;
  late TextEditingController _nombreUsuarioController;
  late TextEditingController _emailController;
  late TextEditingController _claveController;
  late TextEditingController _confirmarClaveController;

  // Estado para el Dropdown
  // Los valores deben ser minúsculas: 'super', 'administrador', 'almacen'
  late String _tipoUsuarioSeleccionado;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    print(u);

    _nombreCompletoController = TextEditingController(
      text: u?.nombreCompleto ?? '',
    );
    _nombreUsuarioController = TextEditingController(
      text: u?.nombreUsuario ?? '',
    );
    _emailController = TextEditingController(text: u?.email ?? '');
    _claveController = TextEditingController();
    _confirmarClaveController = TextEditingController();

    _tipoUsuarioSeleccionado = u?.tipoUsuario?.toLowerCase() ?? 'super';
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _nombreUsuarioController.dispose();
    _emailController.dispose();
    _claveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }

  // ============== LÓGICA DE VALIDACIÓN ==============

  /// Valida que el email no esté duplicado con otro usuario.
  /// Permite que el usuario actual (en edición) mantenga su propio email.
  bool _validarUnicidadEmail(String email) {
    final emailLimpio = email.trim().toLowerCase();

    for (final usuarioExistente in widget.usuariosExistentes) {
      // Se añade el ? a usuarioExistente.email por si el campo es opcional en el modelo
      final emailExistenteLimpio = usuarioExistente.email?.trim().toLowerCase();

      if (emailExistenteLimpio == emailLimpio) {
        // Encontró una coincidencia

        // Si estamos editando y el email pertenece al usuario actual, está permitido.
        if (widget.usuario != null &&
            usuarioExistente.idUsuario == widget.usuario!.idUsuario) {
          continue;
        }

        // El email ya está registrado por otro usuario.
        return false;
      }
    }
    return true; // Es único
  }

  /// Valida la clave, obligatoria para crear, opcional para editar.
  String? _validarClave(String? value) {
    final clave = value?.trim() ?? '';
    final esCreacion = widget.usuario == null;

    if (esCreacion) {
      // Clave OBLIGATORIA en modo Creación
      if (clave.isEmpty) return 'La clave es obligatoria.';
    } else {
      // Clave OPCIONAL en modo Edición
      if (clave.isEmpty) return null; // Si está vacía, no se edita y es válido.
    }

    // Validar longitud si se proporcionó una clave
    if (clave.length < _minClaveLength || clave.length > _maxClaveLength) {
      return 'Debe tener entre $_minClaveLength y $_maxClaveLength caracteres.';
    }

    return null;
  }

  void _guardarFormulario() {
    if (_formKey.currentState!.validate()) {
      final String email = _emailController.text.trim();

      // 1. Validación de unicidad de email
      if (!_validarUnicidadEmail(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El email ya está registrado por otro usuario.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Validación de confirmación de clave (sólo si se proporcionó una)
      final claveNueva = _claveController.text.trim();
      if (claveNueva.isNotEmpty &&
          claveNueva != _confirmarClaveController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La clave y la confirmación no coinciden.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final String tipoU;

      switch (_tipoUsuarioSeleccionado) {
        case "super":
          tipoU = "1";
        case "administrador":
          tipoU = "2";
        case "almacen":
          tipoU = "3";
        default:
          tipoU = "2";
      }

      // 3. Construir el objeto Usuario
      final Usuario usuarioResultado = Usuario(
        idUsuario: widget.usuario?.idUsuario,
        nombreUsuario: _nombreUsuarioController.text.trim(),
        nombreCompleto: _nombreCompletoController.text.trim(),
        email: email,

        claveHash: claveNueva.isNotEmpty ? claveNueva : null,

        tipoUsuario: tipoU,
        activo: widget.usuario?.activo ?? true,
      );

      // Retornar el objeto Usuario al padre
      Navigator.of(context).pop(usuarioResultado);
    }
  }

  /// Construye el AlertDialog con el formulario.
  @override
  Widget build(BuildContext context) {
    final bool esEdicion = widget.usuario != null;

    return AlertDialog(
      title: Text(esEdicion ? 'Editar Usuario' : 'Nuevo Usuario'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 0. Nombre de Usuario
              TextFormField(
                controller: _nombreUsuarioController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Usuario *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre de usuario es obligatorio.';
                  }
                  return null;
                },
              ),
              // 1. Nombre Completo
              TextFormField(
                controller: _nombreCompletoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre completo es obligatorio.';
                  }
                  if (!_nombreCompletoRegExp.hasMatch(value.trim())) {
                    return 'Debe ingresar nombre y apellido.';
                  }
                  return null;
                },
              ),
              // 2. Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'El email es obligatorio.';
                  if (!_emailRegExp.hasMatch(email)) {
                    return 'Formato de email inválido.';
                  }
                  return null;
                },
              ),
              // 3. Tipo de Usuario (Dropdown)
              DropdownButtonFormField<String>(
                value: _tipoUsuarioSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Usuario *',
                ),
                // Los values de los items deben coincidir con el valor inicial (_tipoUsuarioSeleccionado)
                items: const [
                  DropdownMenuItem(value: 'super', child: Text('Super')),
                  DropdownMenuItem(
                    value: 'administrador',
                    child: Text('Administrador'),
                  ),
                  DropdownMenuItem(value: 'almacen', child: Text('Almacen')),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _tipoUsuarioSeleccionado = value!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleccione un tipo de usuario.' : null,
              ),
              const SizedBox(height: 16),

              // 4. Clave (Condicional: obligatoria en creación)
              TextFormField(
                controller: _claveController,
                decoration: InputDecoration(
                  labelText: esEdicion ? 'Nueva Clave (Opcional)' : 'Clave *',
                  helperText: esEdicion
                      ? 'Dejar vacío para no cambiar'
                      : 'Mínimo $_minClaveLength caracteres',
                ),
                obscureText: true,
                validator: _validarClave,
              ),
              // 5. Confirmar Clave (Condicional: sólo se valida si se ingresó clave)
              TextFormField(
                controller: _confirmarClaveController,
                decoration: const InputDecoration(labelText: 'Confirmar Clave'),
                obscureText: true,
                validator: (value) {
                  final clave = _claveController.text.trim();
                  final confirmar = value?.trim() ?? '';

                  // Solo es obligatorio y debe coincidir si se proporcionó una clave nueva
                  if (clave.isNotEmpty && confirmar.isEmpty) {
                    return 'Debe confirmar la clave.';
                  }
                  if (clave.isNotEmpty && clave != confirmar) {
                    return 'Las claves no coinciden.';
                  }
                  return null;
                },
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
