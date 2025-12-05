import 'package:flutter/material.dart';

import '../../core/session_manager.dart';

import '../../models/producto.dart';
import '../../models/ubicacion.dart';
import '../../models/proveedor.dart';
import '../../models/movimiento_inventario.dart';

import '../../services/inventario_service.dart';
import '../../services/ubicacion_service.dart';
import '../../services/proveedor_service.dart';
import '../../services/movimiento_inventario_service.dart';

class MovimientoInventarioPage extends StatefulWidget {
  final SessionManager sessionManager;

  const MovimientoInventarioPage({super.key, required this.sessionManager});

  @override
  State<MovimientoInventarioPage> createState() =>
      _MovimientoInventarioPageState();
}

class _MovimientoInventarioPageState extends State<MovimientoInventarioPage> {
  final _formKey = GlobalKey<FormState>();

  final MovimientoInventarioService _movService = MovimientoInventarioService();
  final InventarioService _inventarioService = InventarioService();
  final UbicacionService _ubicacionService = UbicacionService();
  final ProveedorService _proveedorService = ProveedorService();

  List<MovimientoInventario> _movimientos = [];
  List<Producto> _productos = [];
  List<Ubicacion> _ubicaciones = [];
  List<Proveedor> _proveedores = [];

  Producto? _productoSeleccionado;
  Ubicacion? _ubicacionSeleccionada;
  Proveedor? _proveedorSeleccionado;

  // 1 = entrada, 0 = salida
  int _tipoMovimiento = 1;

  final TextEditingController _cantidadCtrl = TextEditingController(text: '1');
  final TextEditingController _descripcionCtrl = TextEditingController();

  bool _cargandoInicial = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargandoInicial = true);
    try {
      final results = await Future.wait([
        _movService.obtenerMovimientos(),
        _inventarioService.obtenerProductos(),
        _ubicacionService.obtenerUbicacionesActivas(),
        _proveedorService.obtenerProveedoresActivos(),
      ]);

      setState(() {
        _movimientos = results[0] as List<MovimientoInventario>;
        _productos = results[1] as List<Producto>;
        _ubicaciones = results[2] as List<Ubicacion>;
        _proveedores = results[3] as List<Proveedor>;

        if (_productos.isNotEmpty) {
          _productoSeleccionado ??= _productos.first;
        }
        if (_ubicaciones.isNotEmpty) {
          _ubicacionSeleccionada ??= _ubicaciones.first;
        }
      });
    } catch (e) {
      _showMessage('Error cargando datos: $e');
    } finally {
      if (mounted) setState(() => _cargandoInicial = false);
    }
  }

  int _parseInt(String s) => int.tryParse(s.trim()) ?? 0;

  Future<void> _refrescar() async {
    try {
      final data = await _movService.obtenerMovimientos();
      setState(() => _movimientos = data);
    } catch (e) {
      _showMessage('Error al refrescar: $e');
    }
  }

  Future<void> _registrarMovimiento() async {
    if (!_formKey.currentState!.validate()) return;

    final usuario = widget.sessionManager.obtenerUsuarioActual();
    if (usuario?.idUsuario == null) {
      _showMessage('No hay usuario en sesión.');
      return;
    }

    final producto = _productoSeleccionado;
    final ubicacion = _ubicacionSeleccionada;

    if (producto?.idProducto == null) {
      _showMessage('Selecciona un producto.');
      return;
    }
    if (ubicacion?.idUbicacion == null) {
      _showMessage('Selecciona una ubicación.');
      return;
    }

    final cantidad = _parseInt(_cantidadCtrl.text);
    if (cantidad <= 0) {
      _showMessage('Cantidad inválida.');
      return;
    }

    // // Validación útil para salida (evitar negativos)
    // if (_tipoMovimiento == 0) {
    //   try {
    //     final stock = await _inventarioService.obtenerStockPorUbicacion(
    //       producto!.idProducto!,
    //       ubicacion!.idUbicacion!,
    //     );
    //     if (stock < cantidad) {
    //       _showMessage(
    //         'Stock insuficiente para salida. Disponible: $stock.',
    //       );
    //       return;
    //     }
    //   } catch (_) {
    //     // Si no existe este método en tu servicio, puedes quitar este bloque.
    //   }
    // }

    final mov = MovimientoCreate(
      tipoMovimiento: _tipoMovimiento,
      cantidad: cantidad,
      descripcion: _descripcionCtrl.text.trim(),
      idProducto: producto!.idProducto!,
      idUsuario: usuario!.idUsuario!,
      idProveedor: _proveedorSeleccionado?.idProveedor,
      idUbicacion: ubicacion!.idUbicacion!,
    );

    setState(() => _guardando = true);
    try {
      final ok = await _movService.registrarMovimiento(mov);
      if (ok) {
        _showMessage('Movimiento registrado.');
        _cantidadCtrl.text = '1';
        _descripcionCtrl.clear();
        await _refrescar();
      }
    } catch (e) {
      _showMessage('Error al registrar movimiento: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimientos de Inventario')),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 18,
                          runSpacing: 18,
                          children: [
                            Expanded(child: _buildTipoMovimientoSelector()),
                            Expanded(child: _buildProductoSelector()),
                            Expanded(child: _buildUbicacionSelector()),
                            // Expanded(child: _buildProveedorSelector()),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cantidadCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final c = _parseInt(v ?? '');
                                  if (c <= 0) return 'Cantidad inválida';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _descripcionCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Descripción',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  if ((v ?? '').trim().isEmpty) {
                                    return 'Describe el movimiento';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: ElevatedButton.icon(
                        //     onPressed: _guardando ? null : _registrarMovimiento,
                        //     icon: const Icon(Icons.save),
                        //     label: const Text('Registrar movimiento'),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _movimientos.isEmpty
                      ? const Center(child: Text('No hay movimientos.'))
                      : ListView.separated(
                          itemCount: _movimientos.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final m = _movimientos[i];
                            final isEntrada =
                                m.tipoMovimiento.toLowerCase() == 'entrada';
                            return ListTile(
                              leading: Icon(
                                isEntrada
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                              ),
                              title: Text(
                                '${m.nombreProducto ?? "Producto"} · ${m.tipoMovimiento}',
                              ),
                              subtitle: Text(
                                '${m.fecha} · ${m.descripcion}\nUsuario: ${m.nombreUsuario ?? "-"} · Proveedor: ${m.nombreProveedor ?? "-"}',
                              ),
                              trailing: Text(
                                m.cantidad.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _guardando ? null : _registrarMovimiento,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTipoMovimientoSelector() {
    return DropdownButtonFormField<int>(
      value: _tipoMovimiento,
      decoration: const InputDecoration(
        labelText: 'Tipo movimiento',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 1, child: Text('Entrada')),
        DropdownMenuItem(value: 0, child: Text('Salida')),
      ],
      onChanged: (v) => setState(() => _tipoMovimiento = v ?? 1),
    );
  }

  Widget _buildProductoSelector() {
    return DropdownButtonFormField<Producto>(
      value: _productoSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Producto',
        border: OutlineInputBorder(),
      ),
      items: _productos
          .map(
            (p) => DropdownMenuItem(
              value: p,
              child: Text(
                p.nombre,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _productoSeleccionado = v),
      validator: (_) =>
          _productoSeleccionado == null ? 'Selecciona un producto' : null,
    );
  }

  Widget _buildUbicacionSelector() {
    return DropdownButtonFormField<Ubicacion>(
      value: _ubicacionSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Ubicación',
        border: OutlineInputBorder(),
      ),
      items: _ubicaciones
          .map((u) => DropdownMenuItem(value: u, child: Text(u.nombreAlmacen)))
          .toList(),
      onChanged: (v) => setState(() => _ubicacionSeleccionada = v),
      validator: (_) =>
          _ubicacionSeleccionada == null ? 'Selecciona una ubicación' : null,
    );
  }

  Widget _buildProveedorSelector() {
    return DropdownButtonFormField<Proveedor>(
      value: _proveedorSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Proveedor (opcional)',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<Proveedor>(
          value: null,
          child: Text('Sin proveedor'),
        ),
        ..._proveedores.map(
          (p) => DropdownMenuItem(value: p, child: Text(p.nombre)),
        ),
      ],
      onChanged: (v) => setState(() => _proveedorSeleccionado = v),
    );
  }
}
