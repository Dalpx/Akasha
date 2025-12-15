import 'package:akasha/models/cliente.dart';
import 'package:akasha/services/cliente_service.dart';
import 'package:akasha/widgets/cliente/cliente_form_dialog.dart';
import 'package:flutter/material.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> 
    with AutomaticKeepAliveClientMixin {
  
  // Servicios y Estado
  final ClienteService _clienteService = ClienteService();
  late Future<List<Cliente>> _futureClientes;
  
  // Control de Búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = "";

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futureClientes = _loadClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Cliente>> _loadClientes() {
    // Nota: Asumimos que el servicio trae todos o gestiona el filtro.
    // Si tu servicio solo trae activos, la búsqueda solo buscará en activos.
    return _clienteService.obtenerClientesActivos(); 
  }

  void _recargarClientes() {
    if (!mounted) return;
    setState(() {
      _futureClientes = _loadClientes();
    });
  }

  // --- LÓGICA DE ACCIONES ---

  Future<void> _abrirFormulario({Cliente? cliente}) async {
    // Obtenemos lista actual para validaciones (si el dialog lo requiere)
    final List<Cliente> clientesActuales = await _clienteService.obtenerClientesActivos();
    
    if (!mounted) return;

    final Cliente? clienteResultado = await showDialog<Cliente>(
      context: context,
      builder: (context) => ClienteFormDialog(
        cliente: cliente,
        clientesExistentes: clientesActuales,
      ),
    );

    if (clienteResultado != null) {
      if (cliente == null) {
        await _clienteService.crearCliente(clienteResultado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente creado exitosamente'), backgroundColor: Colors.green),
          );
        }
      } else {
        await _clienteService.actualizarCliente(clienteResultado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cliente actualizado exitosamente'), backgroundColor: Colors.green),
          );
        }
      }
      _recargarClientes();
    }
  }

  Future<void> _confirmarEliminarCliente(Cliente cliente) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cliente.activo ? 'Desactivar Cliente' : 'Reactivar Cliente'),
        content: Text(
          cliente.activo
              ? '¿Desea desactivar a ${cliente.nombre} ${cliente.apellido}? No podrá realizar nuevas compras.'
              : '¿Desea reactivar a ${cliente.nombre} ${cliente.apellido}?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cliente.activo ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(cliente.activo ? 'Desactivar' : 'Reactivar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (cliente.idCliente != null) {
        // Asumiendo que eliminarCliente hace un "Soft Delete" (cambia activo a 0)
        await _clienteService.eliminarCliente(cliente.idCliente!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado del cliente actualizado.'),
            backgroundColor: cliente.activo ? Colors.orange : Colors.green,
          ),
        );
      }
      _recargarClientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // --- HEADER (Igual que Proveedores pero con ícono de Clientes) ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50, // Azul para clientes
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.people_alt_rounded, color: Colors.blue.shade700, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Clientes",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          "Directorio de clientes y compradores",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // --- BARRA DE BÚSQUEDA ---
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar por nombre, apellido o documento...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _filtroBusqueda.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _filtroBusqueda = "";
                            });
                          },
                        ) 
                      : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filtroBusqueda = value.toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),

          // --- LISTA DE RESULTADOS ---
          Expanded(
            child: FutureBuilder<List<Cliente>>(
              future: _futureClientes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final listaCompleta = snapshot.data!;
                
                // Filtrado Local
                final listaFiltrada = listaCompleta.where((c) {
                  final nombre = c.nombre.toLowerCase();
                  final apellido = c.apellido.toLowerCase();
                  final doc = c.nroDocumento.toLowerCase();
                  
                  return nombre.contains(_filtroBusqueda) || 
                         apellido.contains(_filtroBusqueda) ||
                         doc.contains(_filtroBusqueda);
                }).toList();

                if (listaFiltrada.isEmpty) {
                  return _buildEmptyState(isSearch: true);
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: listaFiltrada.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final c = listaFiltrada[index];
                    return _buildClienteCard(c);
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nuevo Cliente", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState({bool isSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.person_off_outlined, 
            size: 60, 
            color: Colors.grey.shade300
          ),
          const SizedBox(height: 10),
          Text(
            isSearch ? "No se encontraron clientes" : "No hay clientes registrados",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // --- TARJETA DE CLIENTE ---
  Widget _buildClienteCard(Cliente c) {
    // Iniciales para el Avatar (Nombre + Apellido)
    String iniciales = c.nombre.isNotEmpty ? c.nombre[0] : '';
    if (c.apellido.isNotEmpty) {
      iniciales += c.apellido[0];
    }
    iniciales = iniciales.toUpperCase();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _abrirFormulario(cliente: c),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar con iniciales y Badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      iniciales,
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.activo ? Colors.green : Colors.red,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${c.nombre} ${c.apellido}",
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black87
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Documento y Teléfono
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem(Icons.badge_outlined, c.nroDocumento),
                        const SizedBox(width: 16),
                        _buildInfoItem(Icons.phone_outlined, c.telefono),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Email
                    _buildInfoItem(Icons.email_outlined, c.email),
                    const SizedBox(height: 6),

                    // Dirección
                    _buildInfoItem(Icons.location_on_outlined, c.direccion),
                  ],
                ),
              ),

              // Menú de opciones
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                onSelected: (value) {
                  if (value == 'edit') {
                    _abrirFormulario(cliente: c);
                  } else if (value == 'toggle') {
                    _confirmarEliminarCliente(c);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          c.activo ? Icons.block : Icons.check_circle_outline, 
                          size: 20, 
                          color: c.activo ? Colors.redAccent : Colors.green
                        ),
                        const SizedBox(width: 10),
                        Text(c.activo ? 'Desactivar' : 'Reactivar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper pequeño para filas de iconos+texto
  Widget _buildInfoItem(IconData icon, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}