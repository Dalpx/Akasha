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
import 'package:akasha/views/transacciones/transaccion_detalles_helper.dart';
import 'package:akasha/views/transacciones/transaccion_shared.dart';
import 'package:akasha/views/transacciones/transaccion_stock_helper.dart';
import 'package:akasha/views/transacciones/widgets/forms/linea_venta_form.dart';
import 'package:akasha/views/transacciones/widgets/logica/resumen_totales.dart';
import 'package:flutter/material.dart';

class VentasTab extends StatefulWidget {
  final SessionManager sessionManager;

  const VentasTab({super.key, required this.sessionManager});

  @override
  State<VentasTab> createState() => VentasTabState();
}

class VentasTabState extends State<VentasTab>
    with AutomaticKeepAliveClientMixin {
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
              _clientes.any(
                (c) => c.idCliente == _clienteSeleccionado!.idCliente,
              );
          _clienteSeleccionado = exists ? _clienteSeleccionado : _clientes.first;
        } else {
          _clienteSeleccionado = null;
        }

        if (_tiposComprobante.isNotEmpty) {
          final exists =
              _tipoComprobanteSeleccionado?.idTipoComprobante != null &&
                  _tiposComprobante.any(
                    (t) =>
                        t.idTipoComprobante ==
                        _tipoComprobanteSeleccionado!.idTipoComprobante,
                  );
          _tipoComprobanteSeleccionado =
              exists ? _tipoComprobanteSeleccionado : _tiposComprobante.first;
        } else {
          _tipoComprobanteSeleccionado = null;
        }

        if (_productos.isNotEmpty) {
          for (final l in _lineas) {
            if (l.producto?.idProducto == null ||
                !_productos.any(
                  (p) => p.idProducto == l.producto!.idProducto,
                )) {
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
                  (u) => u.idUbicacion == l.ubicacionSeleccionada!.idUbicacion,
                )) {
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

    final ubicacionesDisponibles =
        _stock.ubicacionesConStock(productoInicial?.idProducto, _ubicaciones);
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
        ? ubicacionesDisponibles.first
        : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial =
        _stock.stockEnUbicacion(productoInicial?.idProducto, ubicacionInicial);

    final primera = LineaVentaForm(
      producto: productoInicial,
      stockDisponible: stockInicial,
      cantidadInicial: stockInicial > 0 ? 1 : 0,
    );

    primera.ubicacionSeleccionada = ubicacionInicial;

    if (primera.producto != null) {
      primera.precioCtrl.text = primera.producto!.precioVenta.toStringAsFixed(2);
    }

    _watchLinea(primera);
    _lineas.add(primera);
  }

  void _agregarLinea() {
    final productoInicial = _productos.isNotEmpty ? _productos.first : null;

    final ubicacionesDisponibles =
        _stock.ubicacionesConStock(productoInicial?.idProducto, _ubicaciones);
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
        ? ubicacionesDisponibles.first
        : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial =
        _stock.stockEnUbicacion(productoInicial?.idProducto, ubicacionInicial);

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

  // ---------------- UI ----------------

  Widget _buildClienteSelector() {
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<Cliente>(
        value: _clienteSeleccionado,
        decoration: const InputDecoration(
          labelText: 'Cliente',
          border: OutlineInputBorder(),
        ),
        items: _clientes.map((c) {
          final nombre = c.nombre;
          final show = nombre.isEmpty ? 'Cliente ${c.idCliente ?? ''}' : nombre;
          return DropdownMenuItem(value: c, child: Text(show));
        }).toList(),
        onChanged: (nuevo) => setState(() => _clienteSeleccionado = nuevo),
        validator: (_) =>
            _clienteSeleccionado == null ? 'Selecciona un cliente' : null,
      ),
    );
  }

  Widget _buildTipoComprobanteSelector() {
    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<TipoComprobante>(
        value: _tipoComprobanteSeleccionado,
        decoration: const InputDecoration(
          labelText: 'Tipo pago / comprobante',
          border: OutlineInputBorder(),
        ),
        items: _tiposComprobante.map((t) {
          return DropdownMenuItem(value: t, child: Text(t.nombre));
        }).toList(),
        onChanged: (nuevo) =>
            setState(() => _tipoComprobanteSeleccionado = nuevo),
        validator: (_) => _tipoComprobanteSeleccionado == null
            ? 'Selecciona un tipo de pago'
            : null,
      ),
    );
  }

  Widget _buildLineaDetalle(int index, LineaVentaForm linea) {
    final stockActual = _stock.stockEnUbicacion(
      linea.producto?.idProducto,
      linea.ubicacionSeleccionada,
    );
    linea.stockDisponible = stockActual;

    final ubicacionesConStock =
        _stock.ubicacionesConStock(linea.producto?.idProducto, _ubicaciones);

    if (linea.ubicacionSeleccionada != null &&
        !ubicacionesConStock.any(
          (u) => u.idUbicacion == linea.ubicacionSeleccionada!.idUbicacion,
        )) {
      linea.ubicacionSeleccionada =
          ubicacionesConStock.isNotEmpty ? ubicacionesConStock.first : null;

      linea.stockDisponible = _stock.stockEnUbicacion(
        linea.producto?.idProducto,
        linea.ubicacionSeleccionada,
      );
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
          linea.precioCtrl.text = nuevo.precioVenta.toStringAsFixed(2);

          final ubicacionesFiltradas =
              _stock.ubicacionesConStock(nuevo.idProducto, _ubicaciones);

          linea.ubicacionSeleccionada =
              ubicacionesFiltradas.isNotEmpty ? ubicacionesFiltradas.first : null;

          linea.stockDisponible = _stock.stockEnUbicacion(
            linea.producto?.idProducto,
            linea.ubicacionSeleccionada,
          );

          if (linea.stockDisponible <= 0) {
            linea.cantidadCtrl.text = '0';
          } else if (parseIntSafe(linea.cantidadCtrl.text) <= 0) {
            linea.cantidadCtrl.text = '1';
          }
        });
      },
      validator: (_) => linea.producto == null ? 'Selecciona un producto' : null,
    );

    final stockBanner =
        (linea.producto != null && linea.ubicacionSeleccionada != null)
            ? StockBannerCard(
                label: 'Stock en ${linea.ubicacionSeleccionada!.nombreAlmacen}:',
                stock: linea.stockDisponible,
                background: linea.stockDisponible > 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderColor: linea.stockDisponible > 0
                    ? Colors.green.shade300
                    : Colors.red.shade300,
                valueColor: linea.stockDisponible > 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
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
        if (c > linea.stockDisponible) {
          return 'Stock insuficiente (${linea.stockDisponible})';
        }
        return null;
      },
    );

    final precioField = TextFormField(
      controller: linea.precioCtrl,
      readOnly: true,
      enabled: false,
      decoration: const InputDecoration(
        labelText: 'Precio venta',
        border: OutlineInputBorder(),
      ),
    );

    final ubicacionField = DropdownButtonFormField<Ubicacion>(
      value: linea.ubicacionSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Ubicación',
        border: OutlineInputBorder(),
      ),
      items: ubicacionesConStock.map((u) {
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
          if (linea.stockDisponible <= 0) {
            linea.cantidadCtrl.text = '0';
          }
        });
      },
      validator: (_) {
        if (_ubicaciones.isEmpty) return 'No hay almacenes';
        if (ubicacionesConStock.isEmpty && _ubicaciones.isNotEmpty) {
          return 'Sin stock en almacenes';
        }
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
      title: "Factura de venta",
      formKey: _formKey,
      selectors: [
        _buildClienteSelector(),
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

    final historial = HistorialSectionCard<Venta>(
      title: "Historial de ventas",
      items: _ventas,
      emptyText: 'No hay ventas registradas.',
      listKey: const PageStorageKey('ventas_historial_list'),
      itemBuilder: (_, v) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${v.numeroComprobante} · ${v.nombreCliente}'),
          subtitle: Text(
            '${v.fecha} · Total: ${v.total.toStringAsFixed(2)} · ${v.metodoPago}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Ver detalle',
            onPressed: () => _verDetalleVenta(v),
          ),
        );
      },
    );

    return TransaccionLayout(
      scrollKey: const PageStorageKey('ventas_tab_scroll'),
      factura: factura,
      historial: historial,
    );
  }
}
