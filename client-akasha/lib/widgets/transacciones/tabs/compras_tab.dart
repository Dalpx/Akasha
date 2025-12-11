import 'dart:math';

import 'package:akasha/core/constants.dart';
import 'package:akasha/core/session_manager.dart';
import 'package:akasha/models/compra.dart';
import 'package:akasha/models/detalle_compra.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/proveedor.dart';
import 'package:akasha/models/stock_ubicacion.dart'; // IMPORTADO: Necesario para el stock
import 'package:akasha/models/tipo_comprobante.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/services/compra_service.dart';
import 'package:akasha/services/inventario_service.dart';
import 'package:akasha/services/proveedor_service.dart';
import 'package:akasha/services/tipo_comprobante_service.dart';
import 'package:akasha/services/ubicacion_service.dart';
import 'package:akasha/widgets/transacciones/forms/linea_compra_form.dart';
import 'package:akasha/widgets/transacciones/logica/resumen_totales.dart';
import 'package:flutter/material.dart';

class ComprasTab extends StatefulWidget {
  final SessionManager sessionManager;

  const ComprasTab({super.key, required this.sessionManager});

  @override
  State<ComprasTab> createState() => ComprasTabState();
}

class ComprasTabState extends State<ComprasTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  final CompraService _compraService = CompraService();
  final ProveedorService _proveedorService = ProveedorService();
  final InventarioService _inventarioService = InventarioService();
  final UbicacionService _ubicacionService = UbicacionService();
  final TipoComprobanteService _tipoComprobanteService =
      TipoComprobanteService();

  List<Compra> _compras = <Compra>[];
  List<Proveedor> _proveedores = <Proveedor>[];
  List<Producto> _productos = <Producto>[];
  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  List<TipoComprobante> _tiposComprobante = <TipoComprobante>[];

  // Mapa para almacenar el stock de cada producto por sus ubicaciones
  // Key: idProducto, Value: List<StockUbicacion>
  Map<int, List<StockUbicacion>> _stocksUbicacion = {}; 

  Proveedor? _proveedorSeleccionado;
  TipoComprobante? _tipoComprobanteSeleccionado;

  final List<LineaCompraForm> _lineas = <LineaCompraForm>[];

  bool _cargandoInicial = true;
  bool _guardando = false;

  ScaffoldMessengerState? _messenger;

  static const double _iva = 0.16;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger ??= ScaffoldMessenger.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    for (final l in _lineas) {
      l.dispose();
    }
    super.dispose();
  }

  Future<void> onFabPressed() async {
    if (_guardando) return;
    await _registrarCompra();
  }

  Future<void> refreshFromExternalChange() async {
    // Implementar si es necesario
  }

  void _onLineaChanged() {
    if (mounted) setState(() {});
  }

  void _watchLinea(LineaCompraForm linea) {
    linea.cantidadCtrl.addListener(_onLineaChanged);
  }

  double _calcularSubtotal() {
    double subtotal = 0.0;
    for (final l in _lineas) {
      final p = l.producto;
      if (p == null) continue;
      final cantidad = _parseInt(l.cantidadCtrl.text);
      if (cantidad <= 0) continue;
      subtotal += cantidad * p.precioCosto;
    }
    return subtotal;
  }

  // LÓGICA DE STOCK 1: Carga el stock de un producto específico.
  Future<void> _cargarStockProducto(int idProducto) async {
    final stock = await _inventarioService
        .obtenerStockPorUbicacionDeProducto(idProducto);
    if (!mounted) return;
    setState(() {
      _stocksUbicacion[idProducto] = stock;
    });
  }

  // LÓGICA DE STOCK 2: Método helper para obtener el stock de un producto en una ubicación (por nombre)
  int _obtenerStockEnUbicacion(int? idProducto, Ubicacion? ubicacion) {
    if (idProducto == null || ubicacion == null) return 0;
    
    final stocks = _stocksUbicacion[idProducto] ?? [];
    
    // CORRECCIÓN CLAVE: La comparación se hace usando el nombre del almacén
    final stockItem = stocks.firstWhere(
      (s) => s.idUbicacion == ubicacion.nombreAlmacen,
      orElse: () => StockUbicacion(idUbicacion: ubicacion.nombreAlmacen, cantidad: 0),
    );
    
    return stockItem.cantidad;
  }

  // LÓGICA DE STOCK 3: Filtra las ubicaciones donde el producto está ASIGNADO.
  List<Ubicacion> _obtenerUbicacionesAsignadas(int? idProducto) {
    if (idProducto == null) return _ubicaciones; 

    final stocks = _stocksUbicacion[idProducto] ?? [];
    
    // Obtiene los NOMBRES de ubicación donde el producto está asignado.
    final ubicacionesAsignadasNames =
        stocks.map((s) => s.idUbicacion).toSet();
    
    final List<Ubicacion> ubicacionesFiltradas = _ubicaciones
        .where((u) => ubicacionesAsignadasNames.contains(u.nombreAlmacen))
        .toList();

    // Si el producto no tiene NINGÚN registro de stock (es nuevo o no asignado),
    // devolvemos todas las ubicaciones para permitir la primera compra/asignación.
    if (stocks.isEmpty) {
        return _ubicaciones;
    }

    return ubicacionesFiltradas;
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _cargandoInicial = true);
    final comprasFuture =
        _compraService.obtenerCompras().catchError((_) => <Compra>[]);

    try {
      final resultados = await Future.wait([
        comprasFuture,
        _proveedorService.obtenerProveedoresActivos(),
        _inventarioService.obtenerProductos(),
        _tipoComprobanteService.obtenerTiposComprobante(),
        _ubicacionService.obtenerUbicacionesActivas(),
      ]);

      if (!mounted) return;

      setState(() {
        _compras = resultados[0] as List<Compra>;
        _proveedores = resultados[1] as List<Proveedor>;
        _productos = resultados[2] as List<Producto>;
        _tiposComprobante = resultados[3] as List<TipoComprobante>;
        _ubicaciones = resultados[4] as List<Ubicacion>;

        if (_proveedores.isNotEmpty) {
          _proveedorSeleccionado ??= _proveedores.first;
        }
        if (_tiposComprobante.isNotEmpty) {
          _tipoComprobanteSeleccionado ??= _tiposComprobante.first;
        }
      });
      
      if (_productos.isNotEmpty) {
        await _cargarStockProducto(_productos.first.idProducto!);
      }
      
      if (!mounted) return;
      _inicializarLineas();

    } catch (e) {
      _showMessage('Error cargando datos iniciales: $e');
    } finally {
      if (mounted) setState(() => _cargandoInicial = false);
    }
  }

  void _inicializarLineas() {
    for (final l in _lineas) {
      l.dispose();
    }
    _lineas.clear();

    final productoInicial = _productos.isNotEmpty ? _productos.first : null;
    
    // Usar la función de ubicaciones ASIGNADAS
    final ubicacionesDisponibles = _obtenerUbicacionesAsignadas(productoInicial?.idProducto);
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
      ? ubicacionesDisponibles.first
      : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial = _obtenerStockEnUbicacion(
      productoInicial?.idProducto,
      ubicacionInicial,
    );

    final primera = LineaCompraForm(
      producto: productoInicial,
      stockDisponible: stockInicial, // Asignar stock inicial
    );

    primera.ubicacionSeleccionada = ubicacionInicial;

    if (primera.producto != null) {
      primera.precioCtrl.text =
          primera.producto!.precioCosto.toStringAsFixed(2);
    }

    _watchLinea(primera);
    _lineas.add(primera);
  }

  void _agregarLinea() {
    final productoInicial = _productos.isNotEmpty ? _productos.first : null;

    // Usar la función de ubicaciones ASIGNADAS
    final ubicacionesDisponibles = _obtenerUbicacionesAsignadas(productoInicial?.idProducto);
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
      ? ubicacionesDisponibles.first
      : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial = _obtenerStockEnUbicacion(
      productoInicial?.idProducto,
      ubicacionInicial,
    );
    
    final linea = LineaCompraForm(
      producto: productoInicial,
      stockDisponible: stockInicial, // Asignar stock inicial
    );

    linea.ubicacionSeleccionada = ubicacionInicial;

    if (linea.producto != null) {
      linea.precioCtrl.text = linea.producto!.precioCosto.toStringAsFixed(2);
    }

    _watchLinea(linea);
    setState(() => _lineas.add(linea));
  }

  void _eliminarLinea(int index) {
    if (_lineas.length == 1) return;
    setState(() {
      final l = _lineas.removeAt(index);
      l.dispose();
    });
  }

  Future<void> _refrescarCompras() async {
    try {
      final compras = await _compraService.obtenerCompras();
      if (!mounted) return;
      setState(() => _compras = compras);
    } catch (e) {
      _showMessage('Error al refrescar compras: $e');
    }
  }

  int _parseInt(String value) {
    if (value.trim().isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  String _generarNroComprobante() {
    final ahora = DateTime.now();
    final random = Random();
    final parte1 = (ahora.millisecondsSinceEpoch ~/ 1000) % 10000;
    final parte2 = random.nextInt(100000);
    final s1 = parte1.toString().padLeft(4, '0');
    final s2 = parte2.toString().padLeft(5, '0');
    return 'CPA-$s1-$s2';
  }

  Future<void> _registrarCompra() async {
    if (!_formKey.currentState!.validate()) return;

    if (_proveedorSeleccionado?.idProveedor == null) {
      _showMessage('Debes seleccionar un proveedor válido.');
      return;
    }
    if (_tipoComprobanteSeleccionado == null) {
      _showMessage('Debes seleccionar un tipo de comprobante.');
      return;
    }
    if (_productos.isEmpty) {
      _showMessage('No hay productos disponibles.');
      return;
    }
    if (_ubicaciones.isEmpty) {
      _showMessage('No hay almacenes/ubicaciones disponibles.');
      return;
    }
    if (_lineas.isEmpty) {
      _showMessage('Debes agregar al menos un producto.');
      return;
    }

    final usuarioActual = widget.sessionManager.obtenerUsuarioActual();
    if (usuarioActual?.idUsuario == null) {
      _showMessage('No hay usuario en sesión. Vuelve a iniciar sesión.');
      return;
    }

    final List<DetalleCompra> detalles = <DetalleCompra>[];
    double subtotalTotal = 0.0;

    for (final linea in _lineas) {
      final producto = linea.producto;
      if (producto?.idProducto == null) {
        _showMessage('Hay una línea sin producto seleccionado.');
        return;
      }

      final ubicacion = linea.ubicacionSeleccionada;
      if (ubicacion?.idUbicacion == null) {
        _showMessage('Selecciona una ubicación para ${producto!.nombre}.');
        return;
      }

      final int cantidad = _parseInt(linea.cantidadCtrl.text);
      if (cantidad <= 0) {
        _showMessage('Cantidad inválida en una de las líneas.');
        return;
      }

      final double precio = producto!.precioCosto;
      if (precio <= 0) {
        _showMessage(
          'El producto ${producto.nombre} tiene precio de costo inválido.',
        );
        return;
      }

      final double subtotalLinea = cantidad * precio;
      subtotalTotal += subtotalLinea;

      detalles.add(
        DetalleCompra(
          idProducto: producto.idProducto!,
          cantidad: cantidad,
          precioUnitario: precio,
          subtotal: subtotalLinea,
          idUbicacion: ubicacion!.idUbicacion!,
        ),
      );
    }

    final double impuesto = subtotalTotal * _iva;
    final double total = subtotalTotal + impuesto;

    final cabecera = CompraCreate(
      idProveedor: _proveedorSeleccionado!.idProveedor!,
      idTipoComprobante: _tipoComprobanteSeleccionado!.idTipoComprobante,
      subtotal: subtotalTotal,
      impuesto: impuesto,
      total: total,
      idUsuario: usuarioActual!.idUsuario!,
      estado: 1,
      nroComprobante: _generarNroComprobante(),
    );

    setState(() => _guardando = true);

    try {
      final ok = await _compraService.registrarCompra(
        cabecera: cabecera,
        detalles: detalles,
      );

      if (ok) {
        _showMessage('Compra registrada con éxito.');
        // Recargar el stock después de una compra exitosa
        for(final linea in _lineas) {
          if (linea.producto?.idProducto != null) {
            final id = linea.producto!.idProducto!;
            if (detalles.any((d) => d.idProducto == id)) {
                await _cargarStockProducto(id);
            }
          }
        }
        setState(() => _inicializarLineas());
        await _refrescarCompras();
      } else {
        _showMessage('El backend no confirmó el registro de la compra.');
      }
    } catch (e) {
      _showMessage('Error al registrar la compra: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _verDetalleCompra(Compra c) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final detalles = await _compraService.obtenerDetallesCompra(c.idCompra);

      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Detalle · ${c.nroComprobante}'),
          content: SizedBox(
            width: 520,
            child: detalles.isEmpty
                ? const Text('Esta compra no tiene detalle.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: detalles.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = detalles[i];
                      return ListTile(
                        dense: true,
                        title: Text(d.nombreProducto ?? 'Producto ${d.idProducto}'),
                        subtitle: Text(
                          'Cant: ${d.cantidad} · P.U.: ${d.precioUnitario.toStringAsFixed(2)}',
                        ),
                        trailing: Text(
                          d.subtotal.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('No se pudo cargar el detalle: $e');
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    final messenger = _messenger ?? ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(msg)));
  }

  double _historialHeight(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return min(420, max(220, screenH * 0.32));
  }

  Widget _buildFacturaSection(double subtotal, double impuesto, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Factura de compra",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Card(
          color: Constants().background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Constants().border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildProveedorSelector(),
                      _buildTipoComprobanteSelector(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _productos.isEmpty ? null : _agregarLinea,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar producto'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 250,
                    child: SingleChildScrollView(
                      child: Column(
                        children: List.generate(
                          _lineas.length,
                          (i) => _buildLineaDetalle(i, _lineas[i]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ResumenTotales(
                    subtotal: subtotal,
                    impuesto: impuesto,
                    total: total,
                    labelImpuesto: 'IVA (16%)',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Historial de compras",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Card(
          color: Constants().background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Constants().border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              height: _historialHeight(context),
              width: double.infinity,
              child: _compras.isEmpty
                  ? const Center(child: Text('No hay compras registradas.'))
                  : ListView.separated(
                      key: const PageStorageKey('compras_historial_list'),
                      itemCount: _compras.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = _compras[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${c.nroComprobante} · ${c.proveedor}',
                          ),
                          subtitle: Text(
                            '${c.fechaHora} · Total: ${c.total.toStringAsFixed(2)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.receipt_long),
                            tooltip: 'Ver detalle',
                            onPressed: () => _verDetalleCompra(c),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_cargandoInicial) {
      return const Center(child: CircularProgressIndicator());
    }

    final subtotal = _calcularSubtotal();
    final impuesto = subtotal * _iva;
    final total = subtotal + impuesto;

    final w = MediaQuery.of(context).size.width;
    final bool twoColumns = w >= 1100;

    final factura = _buildFacturaSection(subtotal, impuesto, total);
    final historial = _buildHistorialSection();

    if (twoColumns) {
      return SingleChildScrollView(
        key: const PageStorageKey('compras_tab_scroll'),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: factura),
            const SizedBox(width: 16),
            Expanded(child: historial),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      key: const PageStorageKey('compras_tab_scroll'),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          factura,
          const SizedBox(height: 16),
          historial,
        ],
      ),
    );
  }

  Widget _buildProveedorSelector() {
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<Proveedor>(
        value: _proveedorSeleccionado,
        decoration: const InputDecoration(
          labelText: 'Proveedor',
          border: OutlineInputBorder(),
        ),
        items: _proveedores.map((c) {
          final nombre = c.nombre;
          final show = nombre.isEmpty ? 'Proveedor ${c.idProveedor ?? ''}' : nombre;
          return DropdownMenuItem(value: c, child: Text(show));
        }).toList(),
        onChanged: (nuevo) => setState(() => _proveedorSeleccionado = nuevo),
        validator: (_) =>
            _proveedorSeleccionado == null ? 'Selecciona un proveedor' : null,
      ),
    );
  }

  Widget _buildTipoComprobanteSelector() {
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<TipoComprobante>(
        value: _tipoComprobanteSeleccionado,
        decoration: const InputDecoration(
          labelText: 'Tipo comprobante',
          border: OutlineInputBorder(),
        ),
        items: _tiposComprobante.map((t) {
          return DropdownMenuItem(value: t, child: Text(t.nombre));
        }).toList(),
        onChanged: (nuevo) =>
            setState(() => _tipoComprobanteSeleccionado = nuevo),
        validator: (_) => _tipoComprobanteSeleccionado == null
            ? 'Selecciona un tipo de comprobante'
            : null,
      ),
    );
  }

  Widget _buildLineaDetalle(int index, LineaCompraForm linea) {
    
    // 1. Calcular y actualizar el stock disponible de la línea
    final stockActual = _obtenerStockEnUbicacion(
      linea.producto?.idProducto,
      linea.ubicacionSeleccionada,
    );
    linea.stockDisponible = stockActual; 
    
    // 2. Obtener solo las ubicaciones ASIGNADAS al producto
    final ubicacionesAsignadas =
        _obtenerUbicacionesAsignadas(linea.producto?.idProducto);
        
    // 3. Si la ubicación seleccionada ya no es válida (o se cambió el producto)
    if (linea.ubicacionSeleccionada != null &&
        !ubicacionesAsignadas.any(
          (u) => u.nombreAlmacen == linea.ubicacionSeleccionada!.nombreAlmacen, 
        )) {
      // Re-seleccionar la primera válida o nula
      linea.ubicacionSeleccionada = ubicacionesAsignadas.isNotEmpty
          ? ubicacionesAsignadas.first
          : null;
    }


    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Fila de Producto y Botón Eliminar
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Producto>(
                    value: linea.producto,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                    ),
                    items: _productos.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.nombre));
                    }).toList(),
                    onChanged: (Producto? nuevo) async {
                      if (nuevo == null) {
                        setState(() {
                          linea.producto = null;
                          linea.precioCtrl.text = '0.00';
                          linea.stockDisponible = 0;
                          linea.ubicacionSeleccionada = null;
                        });
                        return;
                      }

                      if (!_stocksUbicacion.containsKey(nuevo.idProducto)) {
                        await _cargarStockProducto(nuevo.idProducto!);
                      }
                      
                      if (!mounted) return;

                      setState(() {
                        linea.producto = nuevo;
                        linea.precioCtrl.text =
                            nuevo.precioCosto.toStringAsFixed(2);
                            
                        // Usar ubicaciones ASIGNADAS
                        final ubicacionesFiltradas =
                            _obtenerUbicacionesAsignadas(nuevo.idProducto);

                        linea.ubicacionSeleccionada = ubicacionesFiltradas.isNotEmpty
                            ? ubicacionesFiltradas.first
                            : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);
                            
                        // Recalcular stock
                        linea.stockDisponible = _obtenerStockEnUbicacion(
                          linea.producto?.idProducto,
                          linea.ubicacionSeleccionada,
                        );
                      });
                    },
                    validator: (_) => linea.producto == null
                        ? 'Selecciona un producto'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed:
                      _lineas.length > 1 ? () => _eliminarLinea(index) : null,
                  icon: const Icon(Icons.delete),
                  tooltip: 'Quitar producto',
                ),
              ],
            ),
            
            // CUADRO DE STOCK
            if (linea.producto != null && linea.ubicacionSeleccionada != null) 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  color: Colors.blue.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: Colors.blue.shade300,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock actual en ${linea.ubicacionSeleccionada!.nombreAlmacen}:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${linea.stockDisponible}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            const SizedBox(height: 16),
            
            // Fila de Cantidad, Precio y Ubicación
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: linea.cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final c = _parseInt(value ?? '');
                      if (c <= 0) return 'Cantidad inválida';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: linea.precioCtrl,
                    readOnly: true,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Precio costo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<Ubicacion>(
                    value: linea.ubicacionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(),
                    ),
                    // Usar la lista de ubicaciones ASIGNADAS/FILTRADAS
                    items: ubicacionesAsignadas.map((u) { 
                      return DropdownMenuItem(
                        value: u,
                        child: Text(u.nombreAlmacen), 
                      );
                    }).toList(),
                    onChanged: (Ubicacion? nueva) {
                      if (!mounted) return;
                      setState(() {
                        linea.ubicacionSeleccionada = nueva;
                        // Recalcular y actualizar stockDisponible al cambiar la ubicación
                        linea.stockDisponible = _obtenerStockEnUbicacion(
                          linea.producto?.idProducto,
                          nueva,
                        );
                      });
                    },
                    validator: (_) {
                      if (_ubicaciones.isEmpty) return 'No hay almacenes';
                      if (linea.ubicacionSeleccionada == null) {
                        return 'Selecciona una ubicación';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}