import 'package:akasha/models/proveedor.dart';
import 'package:akasha/services/proveedor_service.dart';
import 'package:akasha/widgets/entidades_maestras/dialogs/proveedor_form_dialog.dart';
import 'package:flutter/material.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> 
    with AutomaticKeepAliveClientMixin {
  
  // Servicios y Estado de Datos
  final ProveedorService _proveedorService = ProveedorService();
  late Future<List<Proveedor>> _futureProveedores;
  List<Proveedor>? _cacheProveedores;

  // Estado de Búsqueda
  String _filtroBusqueda = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _futureProveedores = _loadProveedores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE DATOS ---

  Future<List<Proveedor>> _loadProveedores({bool force = false}) async {
    if (!force && _cacheProveedores != null) {
      return _cacheProveedores!;
    }
    final list = await _proveedorService.obtenerProveedoresActivos();
    _cacheProveedores = list;
    return list;
  }

  void _recargarProveedores() {
    if (!mounted) return;
    setState(() {
      _futureProveedores = _loadProveedores(force: true);
    });
  }

  // --- LÓGICA DE ACCIONES ---

  Future<void> _abrirFormulario({Proveedor? proveedor}) async {
    final ok = await showProveedorFormDialog(
      context,
      service: _proveedorService,
      initial: proveedor,
    );
    // Si se creó o editó con éxito, recargamos la lista
    if (ok && mounted) _recargarProveedores();
  }

  void _confirmarEliminarProveedor(Proveedor proveedor) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Seguro que deseas eliminar al proveedor "${proveedor.nombre}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (proveedor.idProveedor != null) {
                  await _proveedorService.eliminarProveedor(
                    proveedor.idProveedor!,
                  );
                }
                if (!mounted) return;
                
                Navigator.of(dialogContext).pop(); // Cerrar diálogo
                
                // Limpiar caché y recargar
                _cacheProveedores = null; 
                _recargarProveedores();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Proveedor eliminado correctamente")),
                );
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Fondo suave
      body: Column(
        children: [
          // --- HEADER PERSONALIZADO (Estilo Tab) ---
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
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.local_shipping, color: Colors.indigo.shade700, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Proveedores",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          "Gestión de proveedores",
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
                    hintText: "Buscar por nombre o correo...",
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
            child: FutureBuilder<List<Proveedor>>(
              future: _futureProveedores,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                
                final listaCompleta = snapshot.data ?? [];
                
                // Filtrado local usando la barra de búsqueda
                final listaFiltrada = listaCompleta.where((p) {
                  final nombre = p.nombre.toLowerCase();
                  final correo = p.correo?.toLowerCase() ?? '';
                  
                  return nombre.contains(_filtroBusqueda) || 
                         correo.contains(_filtroBusqueda);
                }).toList();

                if (listaFiltrada.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text(
                          "No se encontraron proveedores",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: listaFiltrada.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = listaFiltrada[index];
                    return _buildProveedorCard(p);
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // Botón flotante para añadir
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nuevo", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // --- WIDGET DE TARJETA (El diseño bonito) ---
  Widget _buildProveedorCard(Proveedor p) {
    return Card(
      elevation: 0, // Plano pero con borde sutil
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _abrirFormulario(proveedor: p),
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
                    backgroundColor: Colors.indigo.shade50,
                    child: Text(
                      p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700
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
                        color: p.activo ? Colors.green : Colors.red,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Información Principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.black87
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Fila de Contacto (Teléfono y Correo)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContactDetail(Icons.phone, p.telefono),
                        const SizedBox(width: 20),
                        _buildContactDetail(Icons.email_outlined, p.correo),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Dirección (Con corrección de nulos)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (p.direccion ?? '').isNotEmpty ? p.direccion! : 'Sin dirección registrada',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de opciones
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
                onSelected: (value) {
                  if (value == 'delete') {
                    _confirmarEliminarProveedor(p);
                  } else if (value == 'edit') {
                    _abrirFormulario(proveedor: p);
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
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Eliminar'),
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

  // Helper para detalles
  Widget _buildContactDetail(IconData icon, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink(); 
    }
    
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}