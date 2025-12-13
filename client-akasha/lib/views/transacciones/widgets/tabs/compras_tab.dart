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
import 'package:akasha/views/transacciones/transaccion_detalles_helper.dart';
import 'package:akasha/views/transacciones/transaccion_shared.dart';
import 'package:akasha/views/transacciones/transaccion_stock_helper.dart';
import 'package:akasha/views/transacciones/widgets/documentos/factura_report.dart';
import 'package:akasha/views/transacciones/widgets/forms/linea_compra_form.dart';
import 'package:akasha/views/transacciones/widgets/logica/resumen_totales.dart';
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
  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  List<TipoComprobante> _tiposComprobante = <TipoComprobante>[];

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
    _stock = StockHelper(_inventarioService);
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
      final cantidad = parseIntSafe(l.cantidadCtrl.text);
      if (cantidad <= 0) continue;
      subtotal += cantidad * p.precioCosto;
    }
    return subtotal;
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

    final ubicacionesDisponibles =
        _stock.ubicacionesAsignadas(productoInicial?.idProducto, _ubicaciones);
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
        ? ubicacionesDisponibles.first
        : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial =
        _stock.stockEnUbicacion(productoInicial?.idProducto, ubicacionInicial);

    final primera = LineaCompraForm(
      producto: productoInicial,
      stockDisponible: stockInicial,
    );

    primera.ubicacionSeleccionada = ubicacionInicial;

    if (primera.producto != null) {
      primera.precioCtrl.text = primera.producto!.precioCosto.toStringAsFixed(2);
    }

    _watchLinea(primera);
    _lineas.add(primera);
  }

  void _agregarLinea() {
    final productoInicial = _productos.isNotEmpty ? _productos.first : null;

    final ubicacionesDisponibles =
        _stock.ubicacionesAsignadas(productoInicial?.idProducto, _ubicaciones);
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
        ? ubicacionesDisponibles.first
        : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial =
        _stock.stockEnUbicacion(productoInicial?.idProducto, ubicacionInicial);

    final linea = LineaCompraForm(
      producto: productoInicial,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    border:
                        Border(bottom: BorderSide(color: Colors.grey.shade300)),
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
                          final pdfBytes =
                              await PdfService().generarFacturaCompra(
                            c,
                            detalles,
                          );

                          final nombreLimpio =
                              limpiarNombreArchivoWindows(c.nroComprobante);
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
                    child: FacturaReport(
                      compra: c,
                      detalles: detalles,
                    ),
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

  // ---------------- UI ----------------

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
          final show =
              nombre.isEmpty ? 'Proveedor ${c.idProveedor ?? ''}' : nombre;
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
    final stockActual = _stock.stockEnUbicacion(
      linea.producto?.idProducto,
      linea.ubicacionSeleccionada,
    );
    linea.stockDisponible = stockActual;

    final ubicacionesAsignadas =
        _stock.ubicacionesAsignadas(linea.producto?.idProducto, _ubicaciones);

    if (linea.ubicacionSeleccionada != null &&
        !ubicacionesAsignadas.any(
          (u) => u.nombreAlmacen == linea.ubicacionSeleccionada!.nombreAlmacen,
        )) {
      linea.ubicacionSeleccionada =
          ubicacionesAsignadas.isNotEmpty ? ubicacionesAsignadas.first : null;
    }

    final productoSelector = DropdownButtonFormField<Producto>(
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

        await _stock.ensureLoadedForProduct(nuevo.idProducto);
        if (!mounted) return;

        setState(() {
          linea.producto = nuevo;
          linea.precioCtrl.text = nuevo.precioCosto.toStringAsFixed(2);

          final ubicacionesFiltradas =
              _stock.ubicacionesAsignadas(nuevo.idProducto, _ubicaciones);

          linea.ubicacionSeleccionada = ubicacionesFiltradas.isNotEmpty
              ? ubicacionesFiltradas.first
              : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

          linea.stockDisponible = _stock.stockEnUbicacion(
            linea.producto?.idProducto,
            linea.ubicacionSeleccionada,
          );
        });
      },
      validator: (_) => linea.producto == null ? 'Selecciona un producto' : null,
    );

    final stockBanner =
        (linea.producto != null && linea.ubicacionSeleccionada != null)
            ? StockBannerCard(
                label:
                    'Stock actual en ${linea.ubicacionSeleccionada!.nombreAlmacen}:',
                stock: linea.stockDisponible,
                background: Colors.blue.shade50,
                borderColor: Colors.blue.shade300,
                valueColor: Colors.blue.shade700,
              )
            : null;

    final cantidadField = TextFormField(
      controller: linea.cantidadCtrl,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Cantidad',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        final c = parseIntSafe(value ?? '');
        if (c <= 0) return 'Cantidad inválida';
        return null;
      },
    );

    final precioField = TextFormField(
      controller: linea.precioCtrl,
      readOnly: true,
      enabled: false,
      decoration: const InputDecoration(
        labelText: 'Precio costo',
        border: OutlineInputBorder(),
      ),
    );

    final ubicacionField = DropdownButtonFormField<Ubicacion>(
      value: linea.ubicacionSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Ubicación',
        border: OutlineInputBorder(),
      ),
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
          linea.stockDisponible =
              _stock.stockEnUbicacion(linea.producto?.idProducto, nueva);
        });
      },
      validator: (_) {
        if (_ubicaciones.isEmpty) return 'No hay almacenes';
        if (linea.ubicacionSeleccionada == null) {
          return 'Selecciona una ubicación';
        }
        return null;
      },
    );

    return LineaProductoCardBase(
      productoSelector: productoSelector,
      stockBanner: stockBanner,
      cantidadField: cantidadField,
      precioField: precioField,
      ubicacionField: ubicacionField,
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
      title: "Factura de compra",
      formKey: _formKey,
      selectors: [
        _buildProveedorSelector(),
        _buildTipoComprobanteSelector(),
      ],
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

    final historial = HistorialSectionCard<Compra>(
      title: "Historial de compras",
      items: _compras,
      emptyText: 'No hay compras registradas.',
      listKey: const PageStorageKey('compras_historial_list'),
      itemBuilder: (_, c) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${c.nroComprobante} · ${c.proveedor}'),
          subtitle:
              Text('${c.fechaHora} · Total: ${c.total.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Ver detalle',
            onPressed: () => _verDetalleCompra(c),
          ),
        );
      },
    );

    return TransaccionLayout(
      scrollKey: const PageStorageKey('compras_tab_scroll'),
      factura: factura,
      historial: historial,
    );
  }
}
