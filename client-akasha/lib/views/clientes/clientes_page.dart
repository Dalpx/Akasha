import 'package:akasha/models/cliente.dart';
import 'package:akasha/services/cliente_service.dart';
import 'package:akasha/widgets/cliente/cliente_detalles.dart';
import 'package:akasha/widgets/cliente/cliente_form_dialog.dart';
import 'package:akasha/widgets/cliente/cliente_list_item.dart';
import 'package:flutter/material.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final ClienteService _clienteService = ClienteService();
  late Future<List<Cliente>> _futureClientes;

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

  Future<void> _abrirFormularioCliente({Cliente? clienteEditar}) async {
    final List<Cliente> clientesActuales = await _clienteService
        .obtenerClientesActivos();

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
        title: Text(
          cliente.activo ? 'Desactivar Cliente' : 'Reactivar Cliente',
        ),
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
      _recargarClientes();
    }
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
                        'Clientes',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text("Gestión de clientes"),
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

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: FutureBuilder<List<Cliente>>(
                    future: _futureClientes,
                    builder: (context, snapshot) {
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
                          child: Text('No hay clientes registrados.'),
                        );
                      }

                      List<Cliente> clientes = snapshot.data!
                          .where((cliente) => cliente.activo)
                          .toList();

                      return ListView.builder(
                        itemCount: clientes.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Cliente cliente = clientes[index];

                          return ClienteListItem(
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
            ),
          ],
        ),
      ),
    );
  }
}
