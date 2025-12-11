import 'dart:math';

import 'package:akasha/core/constants.dart';
import 'package:akasha/core/session_manager.dart';
import 'package:akasha/models/cliente.dart';
import 'package:akasha/models/detalle_venta.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/tipo_comprobante.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/models/venta.dart';
import 'package:akasha/services/cliente_service.dart';
import 'package:akasha/services/inventario_service.dart';
import 'package:akasha/services/tipo_comprobante_service.dart';
import 'package:akasha/services/ubicacion_service.dart';
import 'package:akasha/services/venta_service.dart';
import 'package:akasha/widgets/transacciones/forms/linea_venta_form.dart';
import 'package:akasha/widgets/transacciones/logica/resumen_totales.dart';
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

  static const double _iva = 0.16;

  @override
  bool get wantKeepAlive => true;

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

      final prevClienteId = _clienteSeleccionado?.idCliente;
      final prevTipoId = _tipoComprobanteSeleccionado?.idTipoComprobante;

      setState(() {
        _clientes = clientes;
        _productos = productos;
        _tiposComprobante = tipos;
        _ubicaciones = ubicaciones;
        _ventas = ventas;

        _clienteSeleccionado = _clientes.isEmpty
            ? null
            : _clientes.firstWhereOrNull(
                  (c) => c.idCliente == prevClienteId,
                ) ??
                _clientes.first;

        _tipoComprobanteSeleccionado = _tiposComprobante.isEmpty
            ? null
            : _tiposComprobante.firstWhereOrNull(
                  (t) => t.idTipoComprobante == prevTipoId,
                ) ??
                _tiposComprobante.first;

        for (final l in _lineas) {
          final pid = l.producto?.idProducto;
          l.producto = _productos.isEmpty
              ? null
              : _productos.firstWhereOrNull((p) => p.idProducto == pid) ??
                  _productos.first;

          if (l.producto != null) {
            l.precioCtrl.text = l.producto!.precioVenta.toStringAsFixed(2);
          } else {
            l.precioCtrl.text = '0.00';
          }

          final uid = l.ubicacionSeleccionada?.idUbicacion;
          l.ubicacionSeleccionada = _ubicaciones.isEmpty
              ? null
              : _ubicaciones.firstWhereOrNull((u) => u.idUbicacion == uid) ??
                  _ubicaciones.first;
        }

        if (_lineas.isEmpty) {
          _inicializarLineas();
        }
      });
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
      final cantidad = _parseInt(l.cantidadCtrl.text);
      if (cantidad <= 0) continue;
      subtotal += cantidad * p.precioVenta;
    }
    return subtotal;
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() => _cargandoInicial = true);

    final ventasFuture =
        _ventaService.obtenerVentas().catchError((_) => <Venta>[]);

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

        _clienteSeleccionado =
            _clientes.isNotEmpty ? _clientes.first : null;
        _tipoComprobanteSeleccionado =
            _tiposComprobante.isNotEmpty ? _tiposComprobante.first : null;

        _inicializarLineas();
      });
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

    final primera = LineaVentaForm(
      producto: _productos.isNotEmpty ? _productos.first : null,
    );

    if (_ubicaciones.isNotEmpty) {
      primera.ubicacionSeleccionada = _ubicaciones.first;
    }

    if (primera.producto != null) {
      primera.precioCtrl.text =
          primera.producto!.precioVenta.toStringAsFixed(2);
    }

    _watchLinea(primera);
    _lineas.add(primera);
  }

  void _agregarLinea() {
    final linea = LineaVentaForm(
      producto: _productos.isNotEmpty ? _productos.first : null,
    );

    if (_ubicaciones.isNotEmpty) {
      linea.ubicacionSeleccionada = _ubicaciones.first;
    }

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
    return 'VTA-$s1-$s2';
  }

  Future<void> _registrarVenta() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteSeleccionado?.idCliente == null) {
      _showMessage('Debes seleccionar un cliente válido.');
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

    final List<DetalleVenta> detalles = <DetalleVenta>[];
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

      final double precio = producto!.precioVenta;
      if (precio <= 0) {
        _showMessage(
          'El producto ${producto.nombre} tiene precio de venta inválido.',
        );
        return;
      }

      final double subtotalLinea = cantidad * precio;
      subtotalTotal += subtotalLinea;

      detalles.add(
        DetalleVenta(
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

    final cabecera = VentaCreate(
      idCliente: _clienteSeleccionado!.idCliente!,
      idTipoComprobante: _tipoComprobanteSeleccionado!.idTipoComprobante,
      subtotal: subtotalTotal,
      impuesto: impuesto,
      total: total,
      idUsuario: usuarioActual!.idUsuario!,
      nroComprobante: _generarNroComprobante(),
    );

    setState(() => _guardando = true);

    try {
      final ok = await _ventaService.registrarVenta(
        cabecera: cabecera,
        detalles: detalles,
      );

      if (ok) {
        _showMessage('Venta registrada con éxito.');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
          "Factura de venta",
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
                      _buildClienteSelector(),
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
          "Historial de ventas",
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
              child: _ventas.isEmpty
                  ? const Center(child: Text('No hay ventas registradas.'))
                  : ListView.separated(
                      itemCount: _ventas.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final v = _ventas[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${v.numeroComprobante} · ${v.nombreCliente}',
                          ),
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

    return SingleChildScrollView(
      key: const PageStorageKey('ventas_tab_scroll'),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildFacturaSection(subtotal, impuesto, total),
          const SizedBox(height: 16),
          _buildHistorialSection(),
        ],
      ),
    );
  }

  Widget _buildClienteSelector() {
    final selectedId = _clienteSeleccionado?.idCliente;
    final safeValue = selectedId == null
        ? null
        : _clientes.firstWhereOrNull((c) => c.idCliente == selectedId);

    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<Cliente>(
        value: safeValue,
        decoration: const InputDecoration(
          labelText: 'Cliente',
          border: OutlineInputBorder(),
        ),
        items: _clientes
            .map((c) => DropdownMenuItem(value: c, child: Text(c.nombre)))
            .toList(),
        onChanged: (nuevo) => setState(() => _clienteSeleccionado = nuevo),
        validator: (_) =>
            _clienteSeleccionado == null ? 'Selecciona un cliente' : null,
      ),
    );
  }

  Widget _buildTipoComprobanteSelector() {
    final selectedId = _tipoComprobanteSeleccionado?.idTipoComprobante;
    final safeValue = selectedId == null
        ? null
        : _tiposComprobante.firstWhereOrNull(
            (t) => t.idTipoComprobante == selectedId,
          );

    return SizedBox(
      width: 260,
      child: DropdownButtonFormField<TipoComprobante>(
        value: safeValue,
        decoration: const InputDecoration(
          labelText: 'Tipo pago / comprobante',
          border: OutlineInputBorder(),
        ),
        items: _tiposComprobante
            .map((t) => DropdownMenuItem(value: t, child: Text(t.nombre)))
            .toList(),
        onChanged: (nuevo) =>
            setState(() => _tipoComprobanteSeleccionado = nuevo),
        validator: (_) => _tipoComprobanteSeleccionado == null
            ? 'Selecciona un tipo de pago'
            : null,
      ),
    );
  }

  Widget _buildLineaDetalle(int index, LineaVentaForm linea) {
    final productId = linea.producto?.idProducto;
    final safeProducto = productId == null
        ? null
        : _productos.firstWhereOrNull((p) => p.idProducto == productId);

    final ubicId = linea.ubicacionSeleccionada?.idUbicacion;
    final safeUbicacion = ubicId == null
        ? null
        : _ubicaciones.firstWhereOrNull((u) => u.idUbicacion == ubicId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Producto>(
                    value: safeProducto,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                    ),
                    items: _productos
                        .map((p) =>
                            DropdownMenuItem(value: p, child: Text(p.nombre)))
                        .toList(),
                    onChanged: (Producto? nuevo) {
                      setState(() {
                        linea.producto = nuevo;
                        if (nuevo != null) {
                          linea.precioCtrl.text =
                              nuevo.precioVenta.toStringAsFixed(2);
                        } else {
                          linea.precioCtrl.text = '0.00';
                        }
                      });
                    },
                    validator: (_) =>
                        linea.producto == null ? 'Selecciona un producto' : null,
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
            const SizedBox(height: 16),
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
                      labelText: 'Precio venta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<Ubicacion>(
                    value: safeUbicacion,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(),
                    ),
                    items: _ubicaciones
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.nombreAlmacen),
                            ))
                        .toList(),
                    onChanged: (Ubicacion? nueva) {
                      setState(() => linea.ubicacionSeleccionada = nueva);
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

extension ListX<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
