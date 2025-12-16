import 'package:akasha/common/custom_card.dart';
import 'package:akasha/views/usuarios/widgets/usuario_detalles.dart';
import 'package:akasha/views/usuarios/widgets/usuario_form_dialog.dart';
import 'package:akasha/views/usuarios/widgets/usuario_list_item.dart';
import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/usuario_service.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage>
    with AutomaticKeepAliveClientMixin {
  final UsuarioService _usuarioService = UsuarioService();

  late Future<List<Usuario>> _futureUsuarios;
  List<Usuario>? _cacheUsuarios;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  String? _filtroTipoUsuario;
  bool _soloConEmail = false;

  int _conteoFiltrado = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futureUsuarios = _cargarUsuariosConCache();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Usuario>> _cargarUsuariosConCache() async {
    if (_cacheUsuarios != null) return _cacheUsuarios!;
    final usuarios = await _usuarioService.obtenerUsuarios();
    _cacheUsuarios = usuarios;
    return usuarios;
  }

  void _recargarUsuarios() {
    if (!mounted) return;
    setState(() {
      _futureUsuarios = _cargarUsuariosConCache();
    });
  }

  Future<void> _abrirFormularioUsuario({Usuario? usuarioEditar}) async {
    final List<Usuario> usuariosActuales = await _usuarioService
        .obtenerUsuarios();

    if (!mounted) return;

    final Usuario? usuarioResultado = await showDialog<Usuario>(
      context: context,
      builder: (context) => UsuarioFormDialog(
        usuario: usuarioEditar,
        usuariosExistentes: usuariosActuales,
      ),
    );

    if (usuarioResultado != null) {
      if (usuarioEditar == null) {
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

      _cacheUsuarios = null;
      _recargarUsuarios();
    }
  }

  Future<void> _confirmarEliminarUsuario(Usuario usuario) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(usuario.activo ? 'Desactivar Usuario' : 'Reactivar Usuario'),
        content: Text(
          usuario.activo
              ? '¿Está seguro de que desea desactivar al usuario ${usuario.nombreCompleto ?? usuario.nombreUsuario}? Esto inhabilitará su acceso.'
              : '¿Está seguro de que desea reactivar al usuario ${usuario.nombreCompleto ?? usuario.nombreUsuario}?',
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
        _cacheUsuarios = null;
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

  void _syncConteo(int value) {
    if (_conteoFiltrado == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _conteoFiltrado = value);
    });
  }

  void _limpiarBusqueda() {
    _searchCtrl.clear();
    setState(() => _searchText = '');
  }

  bool _hasActiveFilters() {
    if ((_filtroTipoUsuario ?? '').trim().isNotEmpty) return true;
    if (_soloConEmail) return true;
    return false;
  }

  List<String> _valoresUnicosTipoUsuario(List<Usuario> usuarios) {
    final set = <String>{};
    for (final u in usuarios) {
      final v = (u.tipoUsuario ?? '').trim();
      if (v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Usuario> _filtrarUsuarios(List<Usuario> usuarios) {
    Iterable<Usuario> res = usuarios;

    res = res.where((u) => u.activo);

    if ((_filtroTipoUsuario ?? '').trim().isNotEmpty) {
      final ft = _filtroTipoUsuario!.trim();
      res = res.where((u) => (u.tipoUsuario ?? '').trim() == ft);
    }

    if (_soloConEmail) {
      res = res.where((u) => (u.email ?? '').trim().isNotEmpty);
    }

    final q = _searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((u) {
        final nombreUsuario = u.nombreUsuario.toLowerCase();
        final nombreCompleto = (u.nombreCompleto ?? '').toLowerCase();
        final email = (u.email ?? '').toLowerCase();
        final tipo = (u.tipoUsuario ?? '').toLowerCase();
        return nombreUsuario.contains(q) ||
            nombreCompleto.contains(q) ||
            email.contains(q) ||
            tipo.contains(q);
      });
    }

    return res.toList();
  }

  Future<void> _abrirFiltros() async {
    final usuarios = _cacheUsuarios ?? await _cargarUsuariosConCache();
    if (!mounted) return;

    final tipos = _valoresUnicosTipoUsuario(usuarios);

    String? tipoLocal = _filtroTipoUsuario;
    bool soloConEmailLocal = _soloConEmail;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filtros'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: (tipoLocal != null && tipos.contains(tipoLocal))
                          ? tipoLocal
                          : null,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los tipos de usuario'),
                        ),
                        ...tipos.map(
                          (t) => DropdownMenuItem<String?>(
                            value: t,
                            child: Text(t),
                          ),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => tipoLocal = v),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de usuario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    setDialogState(() {
                      tipoLocal = null;
                      soloConEmailLocal = false;
                    });
                  },
                  child: const Text('Limpiar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filtroTipoUsuario = tipoLocal;
                      _soloConEmail = soloConEmailLocal;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                      const Text('Gestión de usuarios'),
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
            Row(
              children: [
                SizedBox(
                  height: 40,
                  width: 300,
                  child: SearchBar(
                    controller: _searchCtrl,
                    hintText: 'Buscar usuarios...',
                    onChanged: (String value) {
                      setState(() => _searchText = value);
                    },
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (_searchText.trim().isNotEmpty)
                        IconButton(
                          tooltip: 'Limpiar',
                          onPressed: _limpiarBusqueda,
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Filtros',
                  onPressed: _abrirFiltros,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.filter_list),
                      if (_hasActiveFilters())
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            child: Center(
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 18,
                                  height: 0.9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: CustomCard(
                content: FutureBuilder<List<Usuario>>(
                  future: _futureUsuarios,
                  initialData: _cacheUsuarios,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        (snapshot.data == null || snapshot.data!.isEmpty)) {
                      _syncConteo(0);
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      _syncConteo(0);
                      return Center(
                        child: Text(
                          'Error al cargar usuarios: ${snapshot.error}',
                        ),
                      );
                    }

                    final data = snapshot.data ?? <Usuario>[];
                    final usuarios = _filtrarUsuarios(data);

                    _syncConteo(usuarios.length);

                    if (usuarios.isEmpty) {
                      return const Center(
                        child: Text('No hay usuarios para los filtros actuales.'),
                      );
                    }

                    return ListView.builder(
                      key: const PageStorageKey('usuarios_list'),
                      itemCount: usuarios.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Usuario usuario = usuarios[index];

                        return UsuarioListItem(
                          index: index + 1,
                          usuario: usuario,
                          onEditar: () {
                            _abrirFormularioUsuario(usuarioEditar: usuario);
                          },
                          onDesactivar: () {
                            _confirmarEliminarUsuario(usuario);
                          },
                          onVerDetalle: () {
                            _mostrarDetallesDeUsuario(usuario);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Text('Usuarios encontrados ( $_conteoFiltrado )'),
          ],
        ),
      ),
    );
  }
}
