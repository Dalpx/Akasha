import 'package:akasha/common/custom_tile.dart';
import 'package:akasha/core/session_manager.dart';
import 'package:akasha/models/compra.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/proveedor.dart';
import 'package:akasha/models/tipo_comprobante.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/services/compra_service.dart';
import 'package:akasha/services/inventario_service.dart';
import 'package:akasha/services/pdf_service.dart';
import 'package:akasha/services/proveedor_service.dart';
import 'package:akasha/services/tipo_comprobante_service.dart';
import 'package:akasha/services/ubicacion_service.dart';
import 'package:akasha/views/transacciones/widgets/common/linea_producto_editar.dart';
import 'package:akasha/views/transacciones/widgets/common/transaccion_dropdown.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_detalles_helper.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_shared.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_stock_helper.dart';
import 'package:akasha/views/transacciones/widgets/documentos/factura_report.dart';
import 'package:akasha/views/transacciones/widgets/forms/linea_compra_form.dart';
import 'package:akasha/views/transacciones/widgets/resumen/resumen_totales.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

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

  late final StockHelper _stock;

  List<Compra> _compras = <Compra>[];
  List<Proveedor> _proveedores = <Proveedor>[];
  List<Producto> _productos = <Producto>[];
  List<Producto> _productosFiltrados = <Producto>[];
  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  List<TipoComprobante> _tiposComprobante = <TipoComprobante>[];

  Proveedor? _proveedorSeleccionado;
  TipoComprobante? _tipoComprobanteSeleccionado;

  final List<LineaCompraForm> _lineas = <LineaCompraForm>[];

  bool _cargandoInicial = true;
  bool _guardando = false;

  ScaffoldMessengerState? _messenger;

  static const double _iva = 0.16;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';
  String? _filtroProveedor;
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
    await _registrarCompra();
  }

  Future<void> refreshFromExternalChange() async {}

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
      final cantidad = parseIntSafe(l.cantidadCtrl.text);
      if (cantidad <= 0) continue;
      subtotal += cantidad * p.precioCosto;
    }
    return subtotal;
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _cargandoInicial = true);

    final comprasFuture = _compraService.obtenerCompras().catchError(
      (_) => <Compra>[],
    );

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

        _filtrarProductosPorProveedor();
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

  void _filtrarProductosPorProveedor() {
  if (_proveedorSeleccionado == null) {
    _productosFiltrados = [];
    return;
  }

  final nombreProveedor = _proveedorSeleccionado!.nombre.trim().toLowerCase();

  _productosFiltrados = _productos.where((p) {
    final provProducto = (p.idProveedor ?? '').trim().toLowerCase();
    return provProducto == nombreProveedor;
  }).toList();
}

  void _inicializarLineas() {
    for (final l in _lineas) {
      l.dispose();
    }
    _lineas.clear();

    final productoInicial = _productosFiltrados.isNotEmpty
        ? _productosFiltrados.first
        : null;

    final ubicacionesDisponibles = _stock.ubicacionesAsignadas(
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

    final primera = LineaCompraForm(
      producto: productoInicial,
      stockDisponible: stockInicial,
    );

    primera.ubicacionSeleccionada = ubicacionInicial;

    if (primera.producto != null) {
      primera.precioCtrl.text = primera.producto!.precioCosto.toStringAsFixed(
        2,
      );
    }

    _watchLinea(primera);
    _lineas.add(primera);
  }

  void _agregarLinea() {
    final productoInicial = _productos.isNotEmpty ? _productos.first : null;

    final ubicacionesDisponibles = _stock.ubicacionesAsignadas(
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

    final linea = LineaCompraForm(
      stockDisponible: stockInicial,
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

  Future<void> _registrarCompra() async {
    if (!_formKey.currentState!.validate()) return;

    final outcome = CompraDetallesHelper.build(
      lineas: _lineas,
      proveedorSeleccionado: _proveedorSeleccionado,
      tipoComprobanteSeleccionado: _tipoComprobanteSeleccionado,
      hasProductos: _productos.isNotEmpty,
      hasUbicaciones: _ubicaciones.isNotEmpty,
      sessionManager: widget.sessionManager,
      iva: _iva,
      generarNroComprobante: () => generarNroComprobante('CPA'),
    );

    if (!outcome.isSuccess) {
      _showMessage(outcome.error!);
      return;
    }

    final prep = outcome.data!;

    setState(() => _guardando = true);

    try {
      final ok = await _compraService.registrarCompra(
        cabecera: prep.cabecera,
        detalles: prep.detalles,
      );

      if (ok) {
        _showMessage('Compra registrada con éxito.');

        await _stock.ensureLoadedForProducts(prep.productIds);
        if (mounted) setState(() {});

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
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detalles = await _compraService.obtenerDetallesCompra(c.idCompra);

      if (!mounted) return;
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF714B67),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text("Imprimir PDF"),
                        onPressed: () async {
                          final pdfBytes = await PdfService()
                              .generarFacturaCompra(c, detalles);

                          final nombreLimpio = limpiarNombreArchivoWindows(
                            c.nroComprobante,
                          );
                          final nombreArchivo = 'Factura_$nombreLimpio.pdf';

                          await Printing.sharePdf(
                            bytes: pdfBytes,
                            filename: nombreArchivo,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(0),
                    child: FacturaReport(compra: c, detalles: detalles),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showMessage('Error: $e');
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    final messenger = _messenger ?? ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildProveedorSelector() {
    return TransaccionDropdown<Proveedor>(
      width: 260,
      labelText: 'Proveedor',
      value: _proveedorSeleccionado,
      items: _proveedores,
      itemText: (p) =>
          p.nombre.isEmpty ? 'Proveedor ${p.idProveedor ?? ''}' : p.nombre,
      onChanged: (nuevo) {
        setState(() {
          _proveedorSeleccionado = nuevo;
          _filtrarProductosPorProveedor();
          _inicializarLineas();
        });
      },
      validator: (v) => v == null ? 'Selecciona un proveedor' : null,
    );
  }

  Widget _buildTipoComprobanteSelector() {
    return TransaccionDropdown<TipoComprobante>(
      width: 260,
      labelText: 'Tipo comprobante',
      value: _tipoComprobanteSeleccionado,
      items: _tiposComprobante,
      itemText: (t) => t.nombre,
      onChanged: (nuevo) =>
          setState(() => _tipoComprobanteSeleccionado = nuevo),
      validator: (v) => v == null ? 'Selecciona un tipo de comprobante' : null,
    );
  }

  Widget _buildLineaDetalle(int index, LineaCompraForm linea) {
    return LineaProductoEditor<LineaCompraForm>(
      line: linea,
      productos: _productosFiltrados,
      ubicaciones: _ubicaciones,
      stock: _stock,
      ubicacionesDisponibles: (idProducto, ubicaciones) =>
          _stock.ubicacionesAsignadas(idProducto, ubicaciones),
      fallbackToAllUbicacionesWhenEmpty: true,
      ubicacionMatches: (a, b) => a.nombreAlmacen == b.nombreAlmacen,
      precioUnitario: (p) => p.precioCosto,
      labelPrecio: 'Precio costo',
      stockLabelBuilder: (u) => 'Stock actual en ${u.nombreAlmacen}:',
      stockStyleBuilder: (_) => StockBannerStyle(
        background: Colors.blue.shade50,
        borderColor: Colors.blue.shade300,
        valueColor: Colors.blue.shade700,
      ),
      cantidadValidator: (value, _) {
        final c = parseIntSafe(value ?? '');
        if (c <= 0) return 'Cantidad inválida';
        return null;
      },
      ubicacionValidator: (value, disponibles, todas) {
        if (todas.isEmpty) return 'No hay almacenes';
        if (value == null) return 'Selecciona una ubicación';
        return null;
      },
      onAfterStockRecalc: (_, __) {},
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
    if ((_filtroProveedor ?? '').trim().isNotEmpty) return true;
    if (_minTotal != null) return true;
    if (_maxTotal != null) return true;
    return false;
  }

  List<String> _valoresUnicosProveedor(List<Compra> compras) {
    final set = <String>{};
    for (final c in compras) {
      final v = c.proveedor.trim();
      if (v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Compra> _filtrarCompras(List<Compra> compras) {
    Iterable<Compra> res = compras;

    if ((_filtroProveedor ?? '').trim().isNotEmpty) {
      final fp = _filtroProveedor!.trim();
      res = res.where((c) => c.proveedor.trim() == fp);
    }

    if (_minTotal != null) {
      final min = _minTotal!;
      res = res.where((c) => c.total >= min);
    }

    if (_maxTotal != null) {
      final max = _maxTotal!;
      res = res.where((c) => c.total <= max);
    }

    final q = _searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((c) {
        final id = '${c.idCompra}'.toLowerCase();
        final nro = c.nroComprobante.toLowerCase();
        final prov = c.proveedor.toLowerCase();
        final fecha = c.fechaHora.toLowerCase();
        final total = c.total.toStringAsFixed(2).toLowerCase();
        return id.contains(q) ||
            nro.contains(q) ||
            prov.contains(q) ||
            fecha.contains(q) ||
            total.contains(q);
      });
    }

    return res.toList();
  }

  Future<void> _abrirFiltros() async {
    final proveedores = _valoresUnicosProveedor(_compras);

    String? proveedorLocal = _filtroProveedor;

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
                      value:
                          (proveedorLocal != null &&
                              proveedores.contains(proveedorLocal))
                          ? proveedorLocal
                          : null,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los proveedores'),
                        ),
                        ...proveedores.map(
                          (p) => DropdownMenuItem<String?>(
                            value: p,
                            child: Text(p),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setDialogState(() => proveedorLocal = v),
                      decoration: const InputDecoration(
                        labelText: 'Proveedor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                      proveedorLocal = null;
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
                      _filtroProveedor = proveedorLocal;
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
      title: "Factura de compra",
      formKey: _formKey,
      selectors: [_buildProveedorSelector(), _buildTipoComprobanteSelector()],
      onAddLinea: _productosFiltrados.isEmpty ? null : _agregarLinea,
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

    final comprasFiltradas = _filtrarCompras(_compras);
    _syncConteo(comprasFiltradas.length);

    final historialCard = HistorialSectionCard<Compra>(
      items: comprasFiltradas,
      emptyText: 'No hay compras para los filtros actuales.',
      listKey: const PageStorageKey('compras_historial_list'),
      itemBuilder: (_, c) {
        return CustomTile(
          listTile: ListTile(
            leading: Text(
              '${c.idCompra}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text('${c.nroComprobante} · ${c.proveedor}'),
            subtitle: Text(
              '${c.fechaHora} · Total: ${c.total.toStringAsFixed(2)}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Ver detalle',
              onPressed: () => _verDetalleCompra(c),
            ),
          ),
        );
      },
    );

    final historial = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Historial de compras",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            SizedBox(
              height: 40,
              width: 400,
              child: SearchBar(
                controller: _searchCtrl,
                hintText: 'Buscar compras...',
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
        Text('Compras encontradas ( $_conteoFiltrado )'),
      ],
    );

    return TransaccionLayout(
      scrollKey: const PageStorageKey('compras_tab_scroll'),
      factura: factura,
      historial: historial,
    );
  }
}
