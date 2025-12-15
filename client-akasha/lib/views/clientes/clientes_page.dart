import 'package:akasha/common/custom_card.dart';
import 'package:akasha/models/cliente.dart';
import 'package:akasha/services/cliente_service.dart';
import 'package:akasha/views/clientes/widgets/cliente_detalles.dart';
import 'package:akasha/views/clientes/widgets/cliente_form_dialog.dart';
import 'package:akasha/views/clientes/widgets/cliente_list_item.dart';
import 'package:flutter/material.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage>
    with AutomaticKeepAliveClientMixin {
  final ClienteService _clienteService = ClienteService();

  late Future<List<Cliente>> _futureClientes;
  List<Cliente>? _cacheClientes;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';

  String? _filtroTipoDocumento;
  bool _soloConEmail = false;
  bool _soloConDireccion = false;

  int _conteoFiltrado = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futureClientes = _cargarClientesConCache();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Cliente>> _cargarClientesConCache() async {
    if (_cacheClientes != null) return _cacheClientes!;
    final clientes = await _clienteService.obtenerClientesActivos();
    _cacheClientes = clientes;
    return clientes;
  }

  void _recargarClientes() {
    if (!mounted) return;
    setState(() {
      _futureClientes = _cargarClientesConCache();
    });
  }

  Future<void> _abrirFormularioCliente({Cliente? clienteEditar}) async {
    final List<Cliente> clientesActuales =
        await _clienteService.obtenerClientesActivos();

    if (!mounted) return;

    final Cliente? clienteResultado = await showDialog<Cliente>(
      context: context,
      builder: (context) => ClienteFormDialog(
        cliente: clienteEditar,
        clientesExistentes: clientesActuales,
      ),
    );

    if (clienteResultado != null) {
      if (clienteEditar == null) {
        await _clienteService.crearCliente(clienteResultado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente creado exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _clienteService.actualizarCliente(clienteResultado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente actualizado exitosamente.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      _cacheClientes = null;
      _recargarClientes();
    }
  }

  void _mostrarDetallesDeClientes(Cliente cliente) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ClienteDetalles(cliente: cliente);
      },
    );
  }

  Future<void> _confirmarEliminarCliente(Cliente cliente) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cliente.activo ? 'Desactivar Cliente' : 'Reactivar Cliente'),
        content: Text(
          cliente.activo
              ? '¿Está seguro de que desea desactivar al cliente ${cliente.nombre} ${cliente.apellido}? Esto lo inhabilitará para nuevas ventas.'
              : '¿Está seguro de que desea reactivar al cliente ${cliente.nombre} ${cliente.apellido}?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              cliente.activo ? 'Desactivar' : 'Reactivar',
              style: TextStyle(
                color: cliente.activo ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (cliente.activo) {
        await _clienteService.eliminarCliente(cliente.idCliente!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cliente ${cliente.activo ? 'desactivado' : 'reactivado'} correctamente.',
            ),
            backgroundColor: cliente.activo ? Colors.red : Colors.green,
          ),
        );
      }
      _cacheClientes = null;
      _recargarClientes();
    }
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
    if ((_filtroTipoDocumento ?? '').trim().isNotEmpty) return true;
    if (_soloConEmail) return true;
    if (_soloConDireccion) return true;
    return false;
  }

  List<String> _valoresUnicosTipoDocumento(List<Cliente> clientes) {
    final set = <String>{};
    for (final c in clientes) {
      final v = c.tipoDocumento.trim();
      if (v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Cliente> _filtrarClientes(List<Cliente> clientes) {
    Iterable<Cliente> res = clientes;

    res = res.where((c) => c.activo);

    if ((_filtroTipoDocumento ?? '').trim().isNotEmpty) {
      final ft = _filtroTipoDocumento!.trim();
      res = res.where((c) => c.tipoDocumento.trim() == ft);
    }

    if (_soloConEmail) {
      res = res.where((c) => (c.email ?? '').trim().isNotEmpty);
    }

    if (_soloConDireccion) {
      res = res.where((c) => (c.direccion ?? '').trim().isNotEmpty);
    }

    final q = _searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((c) {
        final nombre = c.nombre.toLowerCase();
        final apellido = c.apellido.toLowerCase();
        final doc = c.nroDocumento.toLowerCase();
        final tel = c.telefono.toLowerCase();
        final email = (c.email ?? '').toLowerCase();
        final dir = (c.direccion ?? '').toLowerCase();
        return nombre.contains(q) ||
            apellido.contains(q) ||
            ('$nombre $apellido').contains(q) ||
            doc.contains(q) ||
            tel.contains(q) ||
            email.contains(q) ||
            dir.contains(q);
      });
    }

    return res.toList();
  }

  Future<void> _abrirFiltros() async {
    final clientes = _cacheClientes ?? await _cargarClientesConCache();
    if (!mounted) return;

    final tipos = _valoresUnicosTipoDocumento(clientes);

    String? tipoLocal = _filtroTipoDocumento;
    bool soloConEmailLocal = _soloConEmail;
    bool soloConDireccionLocal = _soloConDireccion;

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
                          child: Text('Todos los tipos de documento'),
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
                        labelText: 'Tipo de documento',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    setDialogState(() {
                      tipoLocal = null;
                      soloConEmailLocal = false;
                      soloConDireccionLocal = false;
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
                      _filtroTipoDocumento = tipoLocal;
                      _soloConEmail = soloConEmailLocal;
                      _soloConDireccion = soloConDireccionLocal;
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
                        'Clientes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Text('Gestión de clientes'),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _abrirFormularioCliente();
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
                    hintText: 'Buscar clientes...',
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
                content: FutureBuilder<List<Cliente>>(
                  future: _futureClientes,
                  initialData: _cacheClientes,
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
                          'Error al cargar clientes: ${snapshot.error}',
                        ),
                      );
                    }

                    final data = snapshot.data ?? <Cliente>[];
                    final clientes = _filtrarClientes(data);

                    _syncConteo(clientes.length);

                    if (clientes.isEmpty) {
                      return const Center(
                        child: Text('No hay clientes para los filtros actuales.'),
                      );
                    }

                    return ListView.builder(
                      key: const PageStorageKey('clientes_list'),
                      itemCount: clientes.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Cliente cliente = clientes[index];

                        return ClienteListItem(
                          index: index + 1,
                          cliente: cliente,
                          onEditar: () {
                            _abrirFormularioCliente(clienteEditar: cliente);
                          },
                          onDesactivar: () {
                            _confirmarEliminarCliente(cliente);
                          },
                          onVerDetalle: () {
                            _mostrarDetallesDeClientes(cliente);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Text('Clientes encontrados ( $_conteoFiltrado )'),
          ],
        ),
      ),
    );
  }
}
