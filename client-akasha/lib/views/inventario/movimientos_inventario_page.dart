import 'package:akasha/views/inventario/helpers/movimiento_historial_filter.dart';
import 'package:akasha/views/inventario/widgets/movimiento_page/movimiento_form_section_card.dart';
import 'package:akasha/views/inventario/widgets/movimiento_page/movimiento_historial_section.dart';
import 'package:flutter/material.dart';

import 'package:akasha/core/session_manager.dart';
import 'package:akasha/models/movimiento_inventario.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/services/inventario_service.dart';
import 'package:akasha/services/movimiento_inventario_service.dart';
import 'package:akasha/services/ubicacion_service.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_shared.dart';

import 'helpers/movimiento_dialogs.dart';
import 'helpers/movimiento_stock_helper.dart';


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

  late final MovimientoStockHelper _stock;

  List<MovimientoInventario> _movimientos = <MovimientoInventario>[];
  List<Producto> _productos = <Producto>[];
  List<Ubicacion> _ubicaciones = <Ubicacion>[];

  Producto? _productoSeleccionado;
  Ubicacion? _ubicacionSeleccionada;

  int _tipoMovimiento = 1;

  final TextEditingController _cantidadCtrl = TextEditingController(text: '1');
  final TextEditingController _descripcionCtrl = TextEditingController();

  final TextEditingController _searchCtrl = TextEditingController();
  final MovimientoHistorialFilters _histFilters = MovimientoHistorialFilters();

  bool _cargandoInicial = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _stock = MovimientoStockHelper(_inventarioService);
    _cargarDatos();
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _descripcionCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargandoInicial = true);

    final movimientosFuture = _movService
        .obtenerMovimientos()
        .catchError((_) => <MovimientoInventario>[]);

    try {
      final results = await Future.wait([
        movimientosFuture,
        _inventarioService.obtenerProductos(),
        _ubicacionService.obtenerUbicacionesActivas(),
      ]);

      if (!mounted) return;

      final movimientos = results[0] as List<MovimientoInventario>;
      final productos = results[1] as List<Producto>;
      final ubicaciones = results[2] as List<Ubicacion>;

      Producto? productoSel = _productoSeleccionado;
      if (productos.isEmpty) {
        productoSel = null;
      } else if (productoSel?.idProducto == null ||
          !productos.any((p) => p.idProducto == productoSel!.idProducto)) {
        productoSel = productos.first;
      }

      Ubicacion? ubicSel = _ubicacionSeleccionada;
      if (ubicaciones.isEmpty) {
        ubicSel = null;
      } else if (ubicSel?.idUbicacion == null ||
          !ubicaciones.any((u) => u.idUbicacion == ubicSel!.idUbicacion)) {
        ubicSel = ubicaciones.first;
      }

      setState(() {
        _movimientos = movimientos;
        _productos = productos;
        _ubicaciones = ubicaciones;
        _productoSeleccionado = productoSel;
        _ubicacionSeleccionada = ubicSel;
      });

      final idProducto = _productoSeleccionado?.idProducto;
      if (idProducto != null) {
        await _stock.ensureLoadedForProduct(idProducto);
        if (!mounted) return;
        _ajustarUbicacionSegunTipoYStock(idProducto);
      }
    } catch (e) {
      _showMessage('Error cargando datos: $e');
    } finally {
      if (mounted) setState(() => _cargandoInicial = false);
    }
  }

  void _ajustarUbicacionSegunTipoYStock(int idProducto) {
    if (_tipoMovimiento == 0) {
      final conStock = _stock.ubicacionesConStock(idProducto, _ubicaciones);

      final selectedOk = _ubicacionSeleccionada != null &&
          conStock.any((u) => u.idUbicacion == _ubicacionSeleccionada!.idUbicacion);

      setState(() {
        _ubicacionSeleccionada =
            selectedOk ? _ubicacionSeleccionada : (conStock.isNotEmpty ? conStock.first : null);
      });
    } else {
      if (_ubicacionSeleccionada == null && _ubicaciones.isNotEmpty) {
        setState(() => _ubicacionSeleccionada = _ubicaciones.first);
      }
    }
  }

  Future<void> _refrescarMovimientos() async {
    try {
      final data = await _movService
          .obtenerMovimientos()
          .catchError((_) => <MovimientoInventario>[]);
      if (!mounted) return;
      setState(() => _movimientos = data);
    } catch (e) {
      _showMessage('Error al refrescar: $e');
    }
  }

  Future<void> _registrarMovimiento() async {
    if (_guardando) return;
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

    final cantidad = parseIntSafe(_cantidadCtrl.text);
    if (cantidad <= 0) {
      _showMessage('Cantidad inválida.');
      return;
    }

    if (_tipoMovimiento == 0) {
      final stockActual =
          _stock.stockEnUbicacion(producto!.idProducto, ubicacion);
      if (cantidad > stockActual) {
        _showMessage(
          'Stock insuficiente en ${ubicacion!.nombreAlmacen}. Solo hay $stockActual unidades.',
        );
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
      if (!ok) {
        _showMessage('El backend no confirmó el registro del movimiento.');
        return;
      }

      _showMessage('Movimiento registrado.');
      _cantidadCtrl.text = '1';
      _descripcionCtrl.clear();

      await _refrescarMovimientos();

      await _stock.reloadForProduct(producto.idProducto!);
      if (!mounted) return;

      _ajustarUbicacionSegunTipoYStock(producto.idProducto!);
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

  Future<void> _onTipoMovimientoChanged(int? v) async {
    final nuevo = v ?? 1;
    setState(() => _tipoMovimiento = nuevo);

    final idProducto = _productoSeleccionado?.idProducto;
    if (idProducto == null) return;

    if (_tipoMovimiento == 0) {
      await _stock.ensureLoadedForProduct(idProducto);
      if (!mounted) return;
    }
    _ajustarUbicacionSegunTipoYStock(idProducto);
  }

  Future<void> _onProductoChanged(Producto? v) async {
    if (v == null) {
      setState(() {
        _productoSeleccionado = null;
        _ubicacionSeleccionada = null;
      });
      return;
    }

    setState(() => _productoSeleccionado = v);

    if (v.idProducto != null) {
      await _stock.ensureLoadedForProduct(v.idProducto!);
      if (!mounted) return;
      _ajustarUbicacionSegunTipoYStock(v.idProducto!);
    }
  }

  Future<void> _abrirFiltros() async {
    final tipo = await MovimientoDialogs.pickTipoMovimiento(
      context: context,
      initial: _histFilters.tipoMovimiento,
    );
    if (!mounted) return;
    setState(() => _histFilters.tipoMovimiento = tipo);
  }

  void _limpiarBusqueda() {
    _searchCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoInicial) {
      return Scaffold(
        appBar: AppBar(title: const Text('Movimientos de Inventario')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filtrados = _histFilters.apply(
      _movimientos,
      searchText: _searchCtrl.text,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de movimientos')),
      body: TransaccionLayout(
        scrollKey: const PageStorageKey('movimientos_page_scroll'),
        factura: MovimientoFormSectionCard(
          title: 'Datos del movimiento:',
          formKey: _formKey,
          productos: _productos,
          ubicaciones: _ubicaciones,
          tipoMovimiento: _tipoMovimiento,
          productoSeleccionado: _productoSeleccionado,
          ubicacionSeleccionada: _ubicacionSeleccionada,
          cantidadCtrl: _cantidadCtrl,
          descripcionCtrl: _descripcionCtrl,
          stock: _stock,
          guardando: _guardando,
          onTipoChanged: _onTipoMovimientoChanged,
          onProductoChanged: _onProductoChanged,
          onUbicacionChanged: (u) => setState(() => _ubicacionSeleccionada = u),
          onRegistrar: _registrarMovimiento,
        ),
        historial: MovimientoHistorialSection(
          title: 'Historial de movimientos',
          searchCtrl: _searchCtrl,
          hasActiveFilters: _histFilters.hasActiveFilters,
          onClearSearch: _limpiarBusqueda,
          onOpenFilters: _abrirFiltros,
          items: filtrados,
          conteo: filtrados.length,
          onSearchChanged: (_) => setState(() {}),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _guardando ? null : _registrarMovimiento,
        child: const Icon(Icons.add),
      ),
    );
  }
}
