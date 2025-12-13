import 'package:flutter/material.dart';

import 'package:akasha/core/session_manager.dart';
import 'package:akasha/models/producto.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/models/tipo_comprobante.dart';

class OperacionCatalogos {
  final List<Producto> productos;
  final List<Ubicacion> ubicaciones;
  final List<TipoComprobante> tiposComprobante;

  const OperacionCatalogos({
    required this.productos,
    required this.ubicaciones,
    required this.tiposComprobante,
  });
}

class LineaProductoForm {
  Producto? producto;
  Ubicacion? ubicacionSeleccionada;

  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;

  final double Function(Producto) precioGetter;

  LineaProductoForm({
    required this.precioGetter,
    this.producto,
    int cantidadInicial = 1,
  })  : cantidadCtrl =
            TextEditingController(text: cantidadInicial.toString()),
        precioCtrl = TextEditingController() {
    _syncPrecio();
  }

  void setProducto(Producto? nuevo) {
    producto = nuevo;
    _syncPrecio();
  }

  void _syncPrecio() {
    if (producto != null) {
      precioCtrl.text = precioGetter(producto!).toStringAsFixed(2);
    } else {
      precioCtrl.text = '0.00';
    }
  }

  void dispose() {
    cantidadCtrl.dispose();
    precioCtrl.dispose();
  }
}

abstract class BaseOperacionTab extends StatefulWidget {
  final SessionManager sessionManager;
  final OperacionCatalogos catalogos;

  const BaseOperacionTab({
    super.key,
    required this.sessionManager,
    required this.catalogos,
  });
}

abstract class BaseOperacionTabState<W extends BaseOperacionTab>
    extends State<W> {
  final formKey = GlobalKey<FormState>();

  // Líneas compartidas
  final List<LineaProductoForm> lineas = <LineaProductoForm>[];

  // Estado compartido
  bool cargandoInicial = true;
  bool guardando = false;

  // Selección compartida
  TipoComprobante? tipoComprobanteSeleccionado;

  // Accesos a catálogos
  List<Producto> get productos => widget.catalogos.productos;
  List<Ubicacion> get ubicaciones => widget.catalogos.ubicaciones;
  List<TipoComprobante> get tiposComprobante =>
      widget.catalogos.tiposComprobante;

  /// Cada tab define cómo obtener el precio del producto
  double Function(Producto) get precioGetter;

  /// Cada tab define su tasa de impuesto
  double get impuestoRate;

  /// Etiqueta del campo precio
  String get precioLabel;

  @override
  void dispose() {
    for (final l in lineas) {
      l.dispose();
    }
    super.dispose();
  }

  void inicializarDefaultsDeCatalogos() {
    if (tiposComprobante.isNotEmpty) {
      tipoComprobanteSeleccionado ??= tiposComprobante.first;
    }
  }

  LineaProductoForm _crearLineaInicial() {
    final linea = LineaProductoForm(
      precioGetter: precioGetter,
      producto: productos.isNotEmpty ? productos.first : null,
    );

    if (ubicaciones.isNotEmpty) {
      linea.ubicacionSeleccionada = ubicaciones.first;
    }

    return linea;
  }

  void inicializarLineas() {
    for (final l in lineas) {
      l.dispose();
    }
    lineas.clear();
    lineas.add(_crearLineaInicial());
  }

  void agregarLinea() {
    setState(() => lineas.add(_crearLineaInicial()));
  }

  void eliminarLinea(int index) {
    if (lineas.length == 1) return;
    setState(() {
      final l = lineas.removeAt(index);
      l.dispose();
    });
  }

  int parseInt(String value) {
    if (value.trim().isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }

  double calcularSubtotal() {
    double subtotal = 0.0;
    for (final linea in lineas) {
      final p = linea.producto;
      if (p == null) continue;
      final c = parseInt(linea.cantidadCtrl.text);
      if (c <= 0) continue;
      subtotal += c * precioGetter(p);
    }
    return subtotal;
  }

  double calcularImpuesto(double subtotal) => subtotal * impuestoRate;

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
