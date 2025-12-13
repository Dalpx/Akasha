import 'dart:math';

import 'package:akasha/core/constants.dart';
import 'package:akasha/core/session_manager.dart';
import 'package:akasha/models/cliente.dart';
import 'package:akasha/models/detalle_venta.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/stock_ubicacion.dart'; // <--- NUEVO IMPORT
import 'package:akasha/models/tipo_comprobante.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/models/venta.dart';
import 'package:akasha/services/cliente_service.dart';
import 'package:akasha/services/inventario_service.dart';
import 'package:akasha/services/tipo_comprobante_service.dart';
import 'package:akasha/services/ubicacion_service.dart';
import 'package:akasha/services/venta_service.dart';
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

  List<Venta> _ventas = <Venta>[];
  List<Cliente> _clientes = <Cliente>[];
  List<Producto> _productos = <Producto>[];
  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  List<TipoComprobante> _tiposComprobante = <TipoComprobante>[];

  // AÑADIDO: Mapa para almacenar el stock de cada producto por sus ubicaciones
  Map<int, List<StockUbicacion>> _stocksUbicacion = {};

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
          final exists =
              _clienteSeleccionado?.idCliente != null &&
              _clientes.any(
                (c) => c.idCliente == _clienteSeleccionado!.idCliente,
              );
          _clienteSeleccionado = exists
              ? _clienteSeleccionado
              : _clientes.first;
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
          _tipoComprobanteSeleccionado = exists
              ? _tipoComprobanteSeleccionado
              : _tiposComprobante.first;
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
              l.precioCtrl.text = _productos.first.precioVenta.toStringAsFixed(
                2,
              );
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
    } catch (_) {}
  }

  void _onLineaChanged() {
    // Al cambiar la cantidad, necesitamos refrescar los totales
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

  // LÓGICA DE STOCK 1: Carga el stock de un producto específico.
  Future<void> _cargarStockProducto(int idProducto) async {
    final stock = await _inventarioService.obtenerStockPorUbicacionDeProducto(
      idProducto,
    );
    if (!mounted) return;
    setState(() {
      _stocksUbicacion[idProducto] = stock;
    });
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

      // Cargar el stock por ubicación para el primer producto ANTES de inicializar líneas
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

  // LÓGICA DE STOCK 2: Método helper para obtener el stock de un producto en una ubicación
  int _obtenerStockEnUbicacion(int? idProducto, Ubicacion? ubicacion) {
    // Si no hay producto o ubicación seleccionados, el stock es 0.
    if (idProducto == null || ubicacion == null) return 0;

    final stocks = _stocksUbicacion[idProducto] ?? [];

    // NOTA: La comparación se hace usando el nombre del almacén
    final stockItem = stocks.firstWhere(
      (s) => s.idUbicacion == ubicacion.nombreAlmacen,
      orElse: () =>
          StockUbicacion(idUbicacion: ubicacion.nombreAlmacen, cantidad: 0),
    );

    return stockItem.cantidad;
  }

  // LÓGICA DE STOCK 3: Filtra las ubicaciones donde el producto tiene stock > 0
  List<Ubicacion> _obtenerUbicacionesConStock(int? idProducto) {
    if (idProducto == null) return const <Ubicacion>[];

    final stocks = _stocksUbicacion[idProducto] ?? [];

    // Obtiene los NOMBRES de ubicación con stock > 0.
    final ubicacionesConStockNames = stocks
        .where((s) => s.cantidad > 0)
        .map((s) => s.idUbicacion)
        .toSet();

    // Filtra la lista maestra de ubicaciones por el nombre del almacén (String).
    return _ubicaciones
        .where((u) => ubicacionesConStockNames.contains(u.nombreAlmacen))
        .toList();
  }

  void _inicializarLineas() {
    for (final l in _lineas) {
      l.dispose();
    }
    _lineas.clear();

    final productoInicial = _productos.isNotEmpty ? _productos.first : null;

    // Obtener la lista de ubicaciones con stock
    final ubicacionesDisponibles = _obtenerUbicacionesConStock(
      productoInicial?.idProducto,
    );
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
        ? ubicacionesDisponibles.first
        : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial = _obtenerStockEnUbicacion(
      productoInicial?.idProducto,
      ubicacionInicial,
    );

    final primera = LineaVentaForm(
      producto: productoInicial,
      stockDisponible: stockInicial, // Asignar stock inicial
      cantidadInicial: stockInicial > 0
          ? 1
          : 0, // Inicia en 1 solo si hay stock
    );

    primera.ubicacionSeleccionada = ubicacionInicial;

    if (primera.producto != null) {
      primera.precioCtrl.text = primera.producto!.precioVenta.toStringAsFixed(
        2,
      );
    }

    _watchLinea(primera);
    _lineas.add(primera);
  }

  void _agregarLinea() {
    final productoInicial = _productos.isNotEmpty ? _productos.first : null;

    // Obtener la lista de ubicaciones con stock
    final ubicacionesDisponibles = _obtenerUbicacionesConStock(
      productoInicial?.idProducto,
    );
    final ubicacionInicial = ubicacionesDisponibles.isNotEmpty
        ? ubicacionesDisponibles.first
        : (_ubicaciones.isNotEmpty ? _ubicaciones.first : null);

    final stockInicial = _obtenerStockEnUbicacion(
      productoInicial?.idProducto,
      ubicacionInicial,
    );

    final linea = LineaVentaForm(
      producto: productoInicial,
      stockDisponible: stockInicial, // Asignar stock inicial
      cantidadInicial: stockInicial > 0
          ? 1
          : 0, // Inicia en 1 solo si hay stock
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

      // VALIDACIÓN FINAL DE STOCK
      final stockActual = _obtenerStockEnUbicacion(
        producto?.idProducto,
        ubicacion,
      );
      if (cantidad > stockActual) {
        _showMessage(
          'Stock insuficiente para ${producto?.nombre} en ${ubicacion?.nombreAlmacen}. Solo hay $stockActual unidades.',
        );
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
        // Recargar el stock después de una venta exitosa
        for (final linea in _lineas) {
          if (linea.producto?.idProducto != null) {
            // Recargar solo si el producto estaba en la venta
            final id = linea.producto!.idProducto!;
            if (detalles.any((d) => d.idProducto == id)) {
              await _cargarStockProducto(id);
            }
          }
        }
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
                        title: Text(
                          d.nombreProducto ?? 'Producto ${d.idProducto}',
                        ),
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
                      key: const PageStorageKey('ventas_historial_list'),
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

    final w = MediaQuery.of(context).size.width;
    final bool twoColumns = w >= 1100;

    final factura = _buildFacturaSection(subtotal, impuesto, total);
    final historial = _buildHistorialSection();

    if (twoColumns) {
      return SingleChildScrollView(
        key: const PageStorageKey('ventas_tab_scroll'),
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
      key: const PageStorageKey('ventas_tab_scroll'),
      padding: const EdgeInsets.all(12),
      child: Column(children: [factura, const SizedBox(height: 16), historial]),
    );
  }

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
    // 1. Recalcular y actualizar el stock disponible de la línea
    final stockActual = _obtenerStockEnUbicacion(
      linea.producto?.idProducto,
      linea.ubicacionSeleccionada,
    );
    linea.stockDisponible = stockActual;

    final ubicacionesConStock = _obtenerUbicacionesConStock(
      linea.producto?.idProducto,
    );

    if (linea.ubicacionSeleccionada != null &&
        !ubicacionesConStock.any(
          (u) => u.idUbicacion == linea.ubicacionSeleccionada!.idUbicacion,
        )) {
      linea.ubicacionSeleccionada = ubicacionesConStock.isNotEmpty
          ? ubicacionesConStock.first
          : null;

      linea.stockDisponible = _obtenerStockEnUbicacion(
        linea.producto?.idProducto,
        linea.ubicacionSeleccionada,
      );
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

                      // Cargar stock si no lo hemos hecho
                      if (!_stocksUbicacion.containsKey(nuevo.idProducto)) {
                        await _cargarStockProducto(nuevo.idProducto!);
                      }

                      if (!mounted) return;

                      setState(() {
                        linea.producto = nuevo;
                        linea.precioCtrl.text = nuevo.precioVenta
                            .toStringAsFixed(2);

                        // 1. Obtener ubicaciones con stock para el nuevo producto
                        final ubicacionesFiltradas =
                            _obtenerUbicacionesConStock(nuevo.idProducto);

                        // 2. Seleccionar la primera ubicación con stock o null
                        linea.ubicacionSeleccionada =
                            ubicacionesFiltradas.isNotEmpty
                            ? ubicacionesFiltradas.first
                            : null;

                        // 3. Recalcular y asignar stock
                        linea.stockDisponible = _obtenerStockEnUbicacion(
                          linea.producto?.idProducto,
                          linea.ubicacionSeleccionada,
                        );

                        // 4. Asegurar que la cantidad se ajuste al stock (si no hay stock, cantidad = 0)
                        if (linea.stockDisponible <= 0) {
                          linea.cantidadCtrl.text = '0';
                        } else if (_parseInt(linea.cantidadCtrl.text) <= 0) {
                          linea.cantidadCtrl.text = '1';
                        }
                      });
                    },
                    validator: (_) => linea.producto == null
                        ? 'Selecciona un producto'
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _lineas.length > 1
                      ? () => _eliminarLinea(index)
                      : null,
                  icon: const Icon(Icons.delete),
                  tooltip: 'Quitar producto',
                ),
              ],
            ),

            // CUADRO DE STOCK VISIBLE
            if (linea.producto != null && linea.ubicacionSeleccionada != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Card(
                  color: linea.stockDisponible > 0
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: linea.stockDisponible > 0
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Stock en ${linea.ubicacionSeleccionada!.nombreAlmacen}:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${linea.stockDisponible}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: linea.stockDisponible > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
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
                      // Validación de stock
                      if (c > linea.stockDisponible) {
                        return 'Stock insuficiente (${linea.stockDisponible})';
                      }
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
                    value: linea.ubicacionSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      border: OutlineInputBorder(),
                    ),
                    // Usar la lista de ubicaciones filtradas por stock
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
                        // Recalcular y actualizar stockDisponible al cambiar la ubicación
                        linea.stockDisponible = _obtenerStockEnUbicacion(
                          linea.producto?.idProducto,
                          nueva,
                        );
                        // Asegurar que la cantidad se resetee si el nuevo stock es 0 o menor
                        if (linea.stockDisponible <= 0) {
                          linea.cantidadCtrl.text = '0';
                        }
                      });
                    },
                    validator: (_) {
                      if (_ubicaciones.isEmpty) return 'No hay almacenes';
                      if (ubicacionesConStock.isEmpty &&
                          _ubicaciones.isNotEmpty) {
                        return 'Sin stock en almacenes';
                      }
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
