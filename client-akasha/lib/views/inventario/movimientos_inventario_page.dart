import 'package:flutter/material.dart';

import '../../core/session_manager.dart';

import '../../models/producto.dart';
import '../../models/ubicacion.dart';
import '../../models/proveedor.dart';
import '../../models/movimiento_inventario.dart';
import '../../models/stock_ubicacion.dart'; // <--- NUEVO IMPORT

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
  
  // AÑADIDO: Mapa para almacenar el stock de cada producto por sus ubicaciones
  Map<int, List<StockUbicacion>> _stocksUbicacion = {};

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
  
  // LÓGICA DE STOCK 1: Carga el stock de un producto específico.
  Future<void> _cargarStockProducto(int idProducto) async {
    // Asume que este método existe en InventarioService y devuelve List<StockUbicacion>
    final stock = await _inventarioService
        .obtenerStockPorUbicacionDeProducto(idProducto);
    if (!mounted) return;
    setState(() {
      _stocksUbicacion[idProducto] = stock;
    });
  }

  // LÓGICA DE STOCK 2: Método helper para obtener el stock de un producto en una ubicación
  int _obtenerStockEnUbicacion(int? idProducto, Ubicacion? ubicacion) {
    if (idProducto == null || ubicacion == null) return 0;
    
    final stocks = _stocksUbicacion[idProducto] ?? [];
    
    // NOTA: La comparación se hace usando el nombre del almacén
    final stockItem = stocks.firstWhere(
      (s) => s.idUbicacion == ubicacion.nombreAlmacen,
      orElse: () => StockUbicacion(idUbicacion: ubicacion.nombreAlmacen, cantidad: 0),
    );
    
    return stockItem.cantidad;
  }
  
  // LÓGICA DE STOCK 3: Filtra las ubicaciones donde el producto tiene stock > 0
  List<Ubicacion> _obtenerUbicacionesConStock(int? idProducto) {
    if (idProducto == null) return const <Ubicacion>[];

    final stocks = _stocksUbicacion[idProducto] ?? [];
    
    // Obtiene los NOMBRES de ubicación con stock > 0.
    final ubicacionesConStockNames =
        stocks.where((s) => s.cantidad > 0).map((s) => s.idUbicacion).toSet();
    
    // Filtra la lista maestra de ubicaciones por el nombre del almacén (String).
    return _ubicaciones
        .where((u) => ubicacionesConStockNames.contains(u.nombreAlmacen))
        .toList();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargandoInicial = true);

    final Future<List<MovimientoInventario>> movimientosFuture = _movService
      .obtenerMovimientos()
      .catchError((e) {
       print('ADVERTENCIA: Error controlado al obtener movimientos (posible 404 por lista vacía): $e'); 
       return <MovimientoInventario>[]; 
      });

    try {
     final results = await Future.wait([
      movimientosFuture,
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
     
     // NUEVO: Cargar stock inicial
     if (_productos.isNotEmpty && _productoSeleccionado != null) {
        await _cargarStockProducto(_productoSeleccionado!.idProducto!);
        
        // Ajustar ubicación inicial si es Salida y la primera ubicación no tiene stock
        if (_tipoMovimiento == 0) { // Salida
            final ubicacionesConStock = _obtenerUbicacionesConStock(_productoSeleccionado!.idProducto);
            // Si la ubicación seleccionada no está en la lista con stock, seleccionar la primera con stock.
            if (_ubicacionSeleccionada == null || 
                !ubicacionesConStock.any((u) => u.idUbicacion == _ubicacionSeleccionada!.idUbicacion)) {
                _ubicacionSeleccionada = ubicacionesConStock.isNotEmpty
                    ? ubicacionesConStock.first
                    : null;
                // Si aún es nulo, el validador lo manejará.
            }
        }
     }

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
    
    // NUEVA VALIDACIÓN DE STOCK (SOLO PARA SALIDA)
    if (_tipoMovimiento == 0) { // Salida
        final stockActual = _obtenerStockEnUbicacion(
          producto!.idProducto,
          ubicacion,
        );
        
        if (cantidad > stockActual) {
           _showMessage('Stock insuficiente en ${ubicacion!.nombreAlmacen}. Solo hay $stockActual unidades.');
           return;
        }
    }

    final mov = MovimientoCreate(
      tipoMovimiento: _tipoMovimiento,
      cantidad: cantidad,
      descripcion: _descripcionCtrl.text.trim(),
      idProducto: producto!.idProducto!,
      idUsuario: usuario!.idUsuario!,
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
        
        // NUEVO: Recargar el stock del producto que se movió.
        if (producto?.idProducto != null) {
             await _cargarStockProducto(producto!.idProducto!);
        }
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
                            _buildTipoMovimientoSelector(),
                            _buildProductoSelector(),
                            _buildUbicacionSelector(),
                          ],
                        ),
                        // NUEVO: Mostrar el stock actual de la ubicación seleccionada
                        if (_productoSeleccionado != null && _ubicacionSeleccionada != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildStockDisplay(),
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
                                  
                                  // NUEVA VALIDACIÓN: Si es salida, validar contra el stock actual
                                  if (_tipoMovimiento == 0) {
                                      final stock = _obtenerStockEnUbicacion(
                                        _productoSeleccionado!.idProducto, 
                                        _ubicacionSeleccionada
                                      );
                                      if (c > stock) {
                                          return 'Stock insuficiente ($stock)';
                                      }
                                  }
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
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color:  isEntrada ? Colors.green: Colors.red,
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
      onChanged: (v) {
        if (!mounted) return;
        setState(() {
          _tipoMovimiento = v ?? 1;
          
          // NUEVO: Ajustar la ubicación seleccionada si cambiamos a Salida
          if (_tipoMovimiento == 0 && _productoSeleccionado != null) {
              final ubicacionesConStock = _obtenerUbicacionesConStock(_productoSeleccionado!.idProducto);
              // Si la ubicación seleccionada ya no tiene stock, selecciona la primera con stock
              if (_ubicacionSeleccionada == null || 
                  !ubicacionesConStock.any((u) => u.idUbicacion == _ubicacionSeleccionada!.idUbicacion)) {
                  _ubicacionSeleccionada = ubicacionesConStock.isNotEmpty
                      ? ubicacionesConStock.first
                      : null;
              }
          } else if (_tipoMovimiento == 1 && _ubicacionSeleccionada == null) {
             // Si volvemos a Entrada, y no había ubicación seleccionada, seleccionamos la primera de la lista
             _ubicacionSeleccionada = _ubicaciones.isNotEmpty ? _ubicaciones.first : null;
          }
        });
      },
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
      onChanged: (Producto? v) async {
        if (v == null) {
            setState(() {
                _productoSeleccionado = null;
                _ubicacionSeleccionada = null;
            });
            return;
        }
        
        // NUEVO: Cargar stock si no lo hemos hecho
        if (v.idProducto != null && !_stocksUbicacion.containsKey(v.idProducto)) {
          await _cargarStockProducto(v.idProducto!);
        }

        if (!mounted) return;
        
        setState(() {
          _productoSeleccionado = v;
          
          // NUEVO: Ajustar la ubicación seleccionada basada en stock si es Salida
          if (_tipoMovimiento == 0) { // Salida
            final ubicacionesConStock = _obtenerUbicacionesConStock(v.idProducto);
            
            // Si la ubicación seleccionada no está en la lista con stock, seleccionar la primera con stock.
            if (_ubicacionSeleccionada == null || 
                !ubicacionesConStock.any((u) => u.idUbicacion == _ubicacionSeleccionada!.idUbicacion)) {
              _ubicacionSeleccionada = ubicacionesConStock.isNotEmpty
                  ? ubicacionesConStock.first
                  : null;
            }
          } else {
             // Si Entrada, asegurar que una ubicación esté seleccionada
             if (_ubicacionSeleccionada == null && _ubicaciones.isNotEmpty) {
                 _ubicacionSeleccionada = _ubicaciones.first;
             }
          }
        });
      },
      validator: (_) =>
          _productoSeleccionado == null ? 'Selecciona un producto' : null,
    );
  }

  Widget _buildUbicacionSelector() {
    final isSalida = _tipoMovimiento == 0;
    final idProducto = _productoSeleccionado?.idProducto;
    
    // Obtener la lista de ubicaciones:
    // - Si es Salida y hay un producto, se filtra por stock > 0.
    // - Si es Entrada o no hay producto, se muestran todas.
    final List<Ubicacion> ubicacionesDisponibles = isSalida && idProducto != null
        ? _obtenerUbicacionesConStock(idProducto)
        : _ubicaciones;
        
    // Mostrar el stock en el dropdown solo si estamos en modo Salida y tenemos producto
    final bool showStockInDropdown = isSalida && idProducto != null;
    
    return DropdownButtonFormField<Ubicacion>(
      value: _ubicacionSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Ubicación',
        border: OutlineInputBorder(),
      ),
      // Usar la lista filtrada o la lista completa
      items: ubicacionesDisponibles
          .map((u) {
             String displayText = u.nombreAlmacen;
             if (showStockInDropdown) {
                 final stock = _obtenerStockEnUbicacion(idProducto, u);
                 displayText = u.nombreAlmacen;
             }
             return DropdownMenuItem(value: u, child: Text(displayText));
          })
          .toList(),
      onChanged: (v) => setState(() => _ubicacionSeleccionada = v),
      validator: (_) {
        if (_ubicacionSeleccionada == null) {
            if (_ubicaciones.isEmpty) return 'No hay almacenes';
            if (isSalida && idProducto != null && ubicacionesDisponibles.isEmpty) {
                return 'Sin stock en almacenes';
            }
            return 'Selecciona una ubicación';
        }
        return null;
      },
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
  
  // NUEVO: Widget para mostrar el stock de forma destacada
  Widget _buildStockDisplay() {
    final stock = _obtenerStockEnUbicacion(
      _productoSeleccionado!.idProducto,
      _ubicacionSeleccionada,
    );
    final isSalida = _tipoMovimiento == 0;
    
    // El color es de advertencia solo para Salida si el stock es 0 o menor.
    final color = stock > 0
        ? Colors.green.shade50
        : (isSalida ? Colors.red.shade50 : Colors.blue.shade50);
        
    final borderColor = stock > 0
        ? Colors.green.shade300
        : (isSalida ? Colors.red.shade300 : Colors.blue.shade300);
        
    final textColor = stock > 0
        ? Colors.green.shade700
        : (isSalida ? Colors.red.shade700 : Colors.blue.shade700);

    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stock actual en ${_ubicacionSeleccionada!.nombreAlmacen}:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '$stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}