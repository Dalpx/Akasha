import 'package:akasha/common/custom_tile.dart';
import 'package:akasha/core/session_manager.dart';
import 'package:akasha/models/cliente.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/tipo_comprobante.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/models/venta.dart';
import 'package:akasha/services/cliente_service.dart';
import 'package:akasha/services/inventario_service.dart';
import 'package:akasha/services/tipo_comprobante_service.dart';
import 'package:akasha/services/ubicacion_service.dart';
import 'package:akasha/services/venta_service.dart';
import 'package:akasha/views/transacciones/widgets/common/linea_producto_editar.dart';
import 'package:akasha/views/transacciones/widgets/common/transaccion_dropdown.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_detalles_helper.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_shared.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_stock_helper.dart';
import 'package:akasha/views/transacciones/widgets/forms/linea_venta_form.dart';
import 'package:akasha/views/transacciones/widgets/resumen/resumen_totales.dart';
import 'package:flutter/material.dart';

class VentasTab extends StatefulWidget {
  final SessionManager sessionManager;

  const VentasTab({super.key, required this.sessionManager});

  @override
  State<VentasTab> createState() => VentasTabState();
}

class VentasTabState extends State<VentasTab> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();

  final VentaService _ventaService = VentaService();
  final ClienteService _clienteService = ClienteService();
  final InventarioService _inventarioService = InventarioService();
  final UbicacionService _ubicacionService = UbicacionService();
  final TipoComprobanteService _tipoComprobanteService =
      TipoComprobanteService();

  late final StockHelper _stock;

  List<Venta> _ventas = <Venta>[];
  List<Cliente> _clientes = <Cliente>[];
  List<Producto> _productos = <Producto>[];
  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  List<TipoComprobante> _tiposComprobante = <TipoComprobante>[];

  Cliente? _clienteSeleccionado;
  TipoComprobante? _tipoComprobanteSeleccionado;

  final List<LineaVentaForm> _lineas = <LineaVentaForm>[];

  bool _cargandoInicial = true;
  bool _guardando = false;

  ScaffoldMessengerState? _messenger;

  static const double _iva = 0.16;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';
  String? _filtroCliente;
  String? _filtroMetodoPago;
  double? _minTotal;
  double? _maxTotal;

  int _conteoFiltrado = 0;

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
    _stock = StockHelper(_inventarioService);
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    for (final l in _lineas) {
      l.dispose();
    }
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> onFabPressed() async {
    if (_guardando) return;
    await _registrarVenta();
  }

  Future<void> refreshFromExternalChange() async {
    try {
      final results = await Future.wait([
        _clienteService.obtenerClientesActivos(),
        _inventarioService.obtenerProductos(),
        _tipoComprobanteService.obtenerTiposComprobante(),
        _ubicacionService.obtenerUbicacionesActivas(),
        _ventaService.obtenerVentas().catchError((_) => <Venta>[]),
      ]);

      if (!mounted) return;

      final clientes = results[0] as List<Cliente>;
      final productos = results[1] as List<Producto>;
      final tipos = results[2] as List<TipoComprobante>;
      final ubicaciones = results[3] as List<Ubicacion>;
      final ventas = results[4] as List<Venta>;

      setState(() {
        _clientes = clientes;
        _productos = productos;
        _tiposComprobante = tipos;
        _ubicaciones = ubicaciones;
        _ventas = ventas;

        if (_clientes.isNotEmpty) {
          final exists = _clienteSeleccionado?.idCliente != null &&
              _clientes.any((c) => c.idCliente == _clienteSeleccionado!.idCliente);
          _clienteSeleccionado = exists ? _clienteSeleccionado : _clientes.first;
        } else {
          _clienteSeleccionado = null;
        }

        if (_tiposComprobante.isNotEmpty) {
          final exists = _tipoComprobanteSeleccionado?.idTipoComprobante != null &&
              _tiposComprobante.any((t) =>
                  t.idTipoComprobante ==
                  _tipoComprobanteSeleccionado!.idTipoComprobante);
          _tipoComprobanteSeleccionado =
              exists ? _tipoComprobanteSeleccionado : _tiposComprobante.first;
        } else {
          _tipoComprobanteSeleccionado = null;
        }

        if (_productos.isNotEmpty) {
          for (final l in _lineas) {
            if (l.producto?.idProducto == null ||
                !_productos.any((p) => p.idProducto == l.producto!.idProducto)) {
              l.producto = _productos.first;
              l.precioCtrl.text =
                  _productos.first.precioVenta.toStringAsFixed(2);
            }
          }
        }

        if (_ubicaciones.isNotEmpty) {
          for (final l in _lineas) {
            if (l.ubicacionSeleccionada?.idUbicacion == null ||
                !_ubicaciones.any(
                    (u) => u.idUbicacion == l.ubicacionSeleccionada!.idUbicacion)) {
              l.ubicacionSeleccionada = _ubicaciones.first;
            }
          }
        }
      });

      final ids = _lineas
          .map((l) => l.producto?.idProducto)
          .whereType<int>()
          .toSet();
      if (ids.isNotEmpty) {
        await _stock.ensureLoadedForProducts(ids);
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  void _onLineaChanged() {
    if (mounted) setState(() {});
  }

  void _watchLinea(LineaVentaForm linea) {
    linea.cantidadCtrl.addListener(_onLineaChanged);
  }

  double _calcularSubtotal() {
    double subtotal = 0.0;
    for (final l in _lineas) {
      final p = l.producto;
      if (p == null) continue;
      final cantidad = parseIntSafe(l.cantidadCtrl.text);
      if (cantidad <= 0) continue;
      subtotal += cantidad * p.precioVenta;
    }
    return subtotal;
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _cargandoInicial = true);

    final ventasFuture = _ventaService.obtenerVentas().catchError(
          (_) => <Venta>[],
        );

    try {
      final resultados = await Future.wait([
        ventasFuture,
        _clienteService.obtenerClientesActivos(),
        _inventarioService.obtenerProductos(),
        _tipoComprobanteService.obtenerTiposComprobante(),
        _ubicacionService.obtenerUbicacionesActivas(),
      ]);

      if (!mounted) return;

      setState(() {
        _ventas = resultados[0] as List<Venta>;
        _clientes = resultados[1] as List<Cliente>;
        _productos = resultados[2] as List<Producto>;
        _tiposComprobante = resultados[3] as List<TipoComprobante>;
        _ubicaciones = resultados[4] as List<Ubicacion>;

        if (_clientes.isNotEmpty) {
          _clienteSeleccionado ??= _clientes.first;
        }
        if (_tiposComprobante.isNotEmpty) {
          _tipoComprobanteSeleccionado ??= _tiposComprobante.first;
        }
      });

      if (_productos.isNotEmpty) {
        await _stock.loadForProduct(_productos.first.idProducto!);
        if (mounted) setState(() {});
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

    final ubicacionesDisponibles = _stock.ubicacionesConStock(
      productoInicial?.idProducto,
      _ubicaciones,
    );
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
        ? ubicacionesDisponibles.first
        : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial = _stock.stockEnUbicacion(
      productoInicial?.idProducto,
      ubicacionInicial,
    );

    final primera = LineaVentaForm(
      producto: productoInicial,
      stockDisponible: stockInicial,
      cantidadInicial: stockInicial > 0 ? 1 : 0,
    );

    primera.ubicacionSeleccionada = ubicacionInicial;

    if (primera.producto != null) {
      primera.precioCtrl.text =
          primera.producto!.precioVenta.toStringAsFixed(2);
    }

    _watchLinea(primera);
    _lineas.add(primera);
  }

  void _agregarLinea() {
    final productoInicial = _productos.isNotEmpty ? _productos.first : null;

    final ubicacionesDisponibles = _stock.ubicacionesConStock(
      productoInicial?.idProducto,
      _ubicaciones,
    );
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
        ? ubicacionesDisponibles.first
        : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial = _stock.stockEnUbicacion(
      productoInicial?.idProducto,
      ubicacionInicial,
    );

    final linea = LineaVentaForm(
      producto: productoInicial,
      stockDisponible: stockInicial,
      cantidadInicial: stockInicial > 0 ? 1 : 0,
    );

    linea.ubicacionSeleccionada = ubicacionInicial;

    if (linea.producto != null) {
      linea.precioCtrl.text = linea.producto!.precioVenta.toStringAsFixed(2);
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

  Future<void> _refrescarVentas() async {
    try {
      final ventas = await _ventaService.obtenerVentas();
      if (!mounted) return;
      setState(() => _ventas = ventas);
    } catch (e) {
      _showMessage('Error al refrescar ventas: $e');
    }
  }

  Future<void> _registrarVenta() async {
    if (!_formKey.currentState!.validate()) return;

    final outcome = VentaDetallesHelper.build(
      lineas: _lineas,
      clienteSeleccionado: _clienteSeleccionado,
      tipoComprobanteSeleccionado: _tipoComprobanteSeleccionado,
      hasProductos: _productos.isNotEmpty,
      hasUbicaciones: _ubicaciones.isNotEmpty,
      sessionManager: widget.sessionManager,
      stockHelper: _stock,
      iva: _iva,
      generarNroComprobante: () => generarNroComprobante('VTA'),
    );

    if (!outcome.isSuccess) {
      _showMessage(outcome.error!);
      return;
    }

    final prep = outcome.data!;

    setState(() => _guardando = true);

    try {
      final ok = await _ventaService.registrarVenta(
        cabecera: prep.cabecera,
        detalles: prep.detalles,
      );

      if (ok) {
        _showMessage('Venta registrada con éxito.');

        await _stock.ensureLoadedForProducts(prep.productIds);
        if (mounted) setState(() {});

        setState(() => _inicializarLineas());
        await _refrescarVentas();
      } else {
        _showMessage('El backend no confirmó el registro de la venta.');
      }
    } catch (e) {
      _showMessage('Error al registrar la venta: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _verDetalleVenta(Venta v) async {
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
      final detalles = await _ventaService.obtenerDetallesVenta(v.idVenta);

      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Detalle · ${v.numeroComprobante}'),
          content: SizedBox(
            width: 520,
            child: detalles.isEmpty
                ? const Text('Esta venta no tiene detalle.')
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
    if ((_filtroCliente ?? '').trim().isNotEmpty) return true;
    if ((_filtroMetodoPago ?? '').trim().isNotEmpty) return true;
    if (_minTotal != null) return true;
    if (_maxTotal != null) return true;
    return false;
  }

  List<String> _valoresUnicosCliente(List<Venta> ventas) {
    final set = <String>{};
    for (final v in ventas) {
      final c = (v.nombreCliente).trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> _valoresUnicosMetodoPago(List<Venta> ventas) {
    final set = <String>{};
    for (final v in ventas) {
      final m = (v.metodoPago).trim();
      if (m.isNotEmpty) set.add(m);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Venta> _filtrarVentas(List<Venta> ventas) {
    Iterable<Venta> res = ventas;

    if ((_filtroCliente ?? '').trim().isNotEmpty) {
      final fc = _filtroCliente!.trim();
      res = res.where((v) => v.nombreCliente.trim() == fc);
    }

    if ((_filtroMetodoPago ?? '').trim().isNotEmpty) {
      final fm = _filtroMetodoPago!.trim();
      res = res.where((v) => v.metodoPago.trim() == fm);
    }

    if (_minTotal != null) {
      final min = _minTotal!;
      res = res.where((v) => v.total >= min);
    }

    if (_maxTotal != null) {
      final max = _maxTotal!;
      res = res.where((v) => v.total <= max);
    }

    final q = _searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((v) {
        final id = '${v.idVenta}'.toLowerCase();
        final nro = (v.numeroComprobante).toLowerCase();
        final cli = (v.nombreCliente).toLowerCase();
        final fecha = (v.fecha).toIso8601String().toLowerCase();
        final total = v.total.toStringAsFixed(2).toLowerCase();
        final mp = (v.metodoPago).toLowerCase();
        return id.contains(q) ||
            nro.contains(q) ||
            cli.contains(q) ||
            fecha.contains(q) ||
            total.contains(q) ||
            mp.contains(q);
      });
    }

    return res.toList();
  }

  Future<void> _abrirFiltros() async {
    final clientes = _valoresUnicosCliente(_ventas);
    final metodos = _valoresUnicosMetodoPago(_ventas);

    String? clienteLocal = _filtroCliente;
    String? metodoLocal = _filtroMetodoPago;

    final minCtrl = TextEditingController(text: _minTotal?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _maxTotal?.toString() ?? '');

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
                      value: (clienteLocal != null && clientes.contains(clienteLocal))
                          ? clienteLocal
                          : null,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los clientes'),
                        ),
                        ...clientes.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c,
                            child: Text(c),
                          ),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => clienteLocal = v),
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: (metodoLocal != null && metodos.contains(metodoLocal))
                          ? metodoLocal
                          : null,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los métodos de pago'),
                        ),
                        ...metodos.map(
                          (m) => DropdownMenuItem<String?>(
                            value: m,
                            child: Text(m),
                          ),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => metodoLocal = v),
                      decoration: const InputDecoration(
                        labelText: 'Método de pago',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Total mín.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Total máx.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    setDialogState(() {
                      clienteLocal = null;
                      metodoLocal = null;
                      minCtrl.text = '';
                      maxCtrl.text = '';
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
                    final min = double.tryParse(minCtrl.text.trim());
                    final max = double.tryParse(maxCtrl.text.trim());

                    setState(() {
                      _filtroCliente = clienteLocal;
                      _filtroMetodoPago = metodoLocal;
                      _minTotal = min;
                      _maxTotal = max;
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

    minCtrl.dispose();
    maxCtrl.dispose();
  }

  Widget _buildClienteSelector() {
    return TransaccionDropdown<Cliente>(
      width: 260,
      labelText: 'Cliente',
      value: _clienteSeleccionado,
      items: _clientes,
      itemText: (c) => c.nombre.isEmpty ? 'Cliente ${c.idCliente ?? ''}' : c.nombre,
      onChanged: (nuevo) => setState(() => _clienteSeleccionado = nuevo),
      validator: (v) => v == null ? 'Selecciona un cliente' : null,
    );
  }

  Widget _buildTipoComprobanteSelector() {
    return TransaccionDropdown<TipoComprobante>(
      width: 260,
      labelText: 'Tipo pago / comprobante',
      value: _tipoComprobanteSeleccionado,
      items: _tiposComprobante,
      itemText: (t) => t.nombre,
      onChanged: (nuevo) => setState(() => _tipoComprobanteSeleccionado = nuevo),
      validator: (v) => v == null ? 'Selecciona un tipo de pago' : null,
    );
  }

  Widget _buildLineaDetalle(int index, LineaVentaForm linea) {
    return LineaProductoEditor<LineaVentaForm>(
      line: linea,
      productos: _productos,
      ubicaciones: _ubicaciones,
      stock: _stock,
      ubicacionesDisponibles: (idProducto, ubicaciones) =>
          _stock.ubicacionesConStock(idProducto, ubicaciones),
      fallbackToAllUbicacionesWhenEmpty: false,
      ubicacionMatches: (a, b) => a.idUbicacion == b.idUbicacion,
      precioUnitario: (p) => p.precioVenta,
      labelPrecio: 'Precio venta',
      stockLabelBuilder: (u) => 'Stock en ${u.nombreAlmacen}:',
      stockStyleBuilder: (st) => StockBannerStyle(
        background: st > 0 ? Colors.green.shade50 : Colors.red.shade50,
        borderColor: st > 0 ? Colors.green.shade300 : Colors.red.shade300,
        valueColor: st > 0 ? Colors.green.shade700 : Colors.red.shade700,
      ),
      cantidadValidator: (value, stockDisponible) {
        final c = parseIntSafe(value ?? '');
        if (c <= 0) return 'Cantidad inválida';
        if (c > stockDisponible) return 'Stock insuficiente ($stockDisponible)';
        return null;
      },
      ubicacionValidator: (value, disponibles, todas) {
        if (todas.isEmpty) return 'No hay almacenes';
        if (disponibles.isEmpty && todas.isNotEmpty) return 'Sin stock en almacenes';
        if (value == null) return 'Selecciona una ubicación';
        return null;
      },
      onAfterStockRecalc: (l, stockDisponible) {
        if (stockDisponible <= 0) {
          l.cantidadCtrl.text = '0';
        } else if (parseIntSafe(l.cantidadCtrl.text) <= 0) {
          l.cantidadCtrl.text = '1';
        }
      },
      getProducto: (l) => l.producto,
      setProducto: (l, p) => l.producto = p,
      getUbicacion: (l) => l.ubicacionSeleccionada,
      setUbicacion: (l, u) => l.ubicacionSeleccionada = u,
      cantidadCtrl: (l) => l.cantidadCtrl,
      precioCtrl: (l) => l.precioCtrl,
      getStock: (l) => l.stockDisponible,
      setStock: (l, v) => l.stockDisponible = v,
      requestRebuild: () {
        if (mounted) setState(() {});
      },
      onDelete: () => _eliminarLinea(index),
      canDelete: _lineas.length > 1,
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

    final factura = FacturaSectionCard(
      title: "Factura de venta",
      formKey: _formKey,
      selectors: [_buildClienteSelector(), _buildTipoComprobanteSelector()],
      onAddLinea: _productos.isEmpty ? null : _agregarLinea,
      lineas: List.generate(
        _lineas.length,
        (i) => _buildLineaDetalle(i, _lineas[i]),
      ),
      totales: ResumenTotales(
        subtotal: subtotal,
        impuesto: impuesto,
        total: total,
        labelImpuesto: 'IVA (16%)',
      ),
    );

    final ventasFiltradas = _filtrarVentas(_ventas);
    _syncConteo(ventasFiltradas.length);

    final historialCard = HistorialSectionCard<Venta>(
      title: "Historial de ventas",
      items: ventasFiltradas,
      emptyText: 'No hay ventas para los filtros actuales.',
      listKey: const PageStorageKey('ventas_historial_list'),
      itemBuilder: (_, v) {
        return CustomTile(
          listTile: ListTile(
            leading: Text(
              '${v.idVenta}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text('${v.numeroComprobante} · ${v.nombreCliente}'),
            subtitle: Text(
              '${v.fecha} · Total: ${v.total.toStringAsFixed(2)} · ${v.metodoPago}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Ver detalle',
              onPressed: () => _verDetalleVenta(v),
            ),
          ),
        );
      },
    );

    final historial = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: 400,
              child: SearchBar(
                controller: _searchCtrl,
                hintText: 'Buscar ventas...',
                onChanged: (value) => setState(() => _searchText = value),
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
                              color: Theme.of(context).colorScheme.onPrimary,
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
        const SizedBox(height: 12),
        historialCard,
        const SizedBox(height: 12),
        Text('Ventas encontradas ( $_conteoFiltrado )'),
      ],
    );

    return TransaccionLayout(
      scrollKey: const PageStorageKey('ventas_tab_scroll'),
      factura: factura,
      historial: historial,
    );
  }
}
