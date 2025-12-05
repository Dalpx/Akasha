import 'dart:math';
import 'package:flutter/material.dart';

import '../../core/session_manager.dart';

import '../../models/producto.dart';
import '../../models/ubicacion.dart';
import '../../models/tipo_comprobante.dart';
import '../../models/proveedor.dart';
import '../../models/compra.dart';
import '../../models/detalle_compra.dart';

import '../../services/inventario_service.dart';
import '../../services/ubicacion_service.dart';
import '../../services/tipo_comprobante_service.dart';
import '../../services/proveedor_service.dart';
import '../../services/compra_service.dart';

class ComprasPage extends StatefulWidget {
  final SessionManager sessionManager;

  const ComprasPage({super.key, required this.sessionManager});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
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

  Proveedor? _proveedorSeleccionado;
  TipoComprobante? _tipoComprobanteSeleccionado;

  final List<_LineaCompraForm> _lineas = <_LineaCompraForm>[];

  bool _cargandoInicial = true;
  bool _guardando = false;

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

  Future<void> _cargarDatosIniciales() async {
    setState(() => _cargandoInicial = true);

    try {
      final resultados = await Future.wait([
        _compraService.obtenerCompras(),
        _proveedorService.obtenerProveedoresActivos(),
        _inventarioService.obtenerProductos(),
        _tipoComprobanteService.obtenerTiposComprobante(),
        _ubicacionService.obtenerUbicacionesActivas(),
      ]);

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

    final primera = _LineaCompraForm(
      producto: _productos.isNotEmpty ? _productos.first : null,
    );

    if (_ubicaciones.isNotEmpty) {
      primera.ubicacionSeleccionada = _ubicaciones.first;
    }

    _lineas.add(primera);
  }

  void _agregarLinea() {
    final linea = _LineaCompraForm(
      producto: _productos.isNotEmpty ? _productos.first : null,
    );

    if (_ubicaciones.isNotEmpty) {
      linea.ubicacionSeleccionada = _ubicaciones.first;
    }

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
      setState(() => _compras = compras);
    } catch (e) {
      _showMessage('Error al refrescar compras: $e');
    }
  }

  double _parseDouble(String value) {
    if (value.trim().isEmpty) return 0;
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
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
    return 'FC-PROV-${parte1.toString().padLeft(4, '0')}${parte2.toString().padLeft(5, '0')}';
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
          'El producto ${producto.nombre} tiene un precio costo inválido.',
        );
        return;
      }

      final double subtotalLinea = cantidad * precio;
      subtotalTotal += subtotalLinea;

      detalles.add(
        DetalleCompra(
          idProducto: producto!.idProducto!,
          cantidad: cantidad,
          precioUnitario: precio,
          subtotal: subtotalLinea,
          idUbicacion: ubicacion!.idUbicacion!, // requerido para stock +
        ),
      );
    }

    final double impuesto = subtotalTotal * 0.16;
    final double total = subtotalTotal + impuesto;

    final cabecera = CompraCreate(
      nroComprobante: _generarNroComprobante(),
      idTipoComprobante: _tipoComprobanteSeleccionado!.idTipoComprobante,
      idProveedor: _proveedorSeleccionado!.idProveedor!,
      idUsuario: usuarioActual!.idUsuario!,
      subtotal: subtotalTotal,
      impuesto: impuesto,
      total: total,
      estado: 1,
    );

    setState(() => _guardando = true);

    try {
      final ok = await _compraService.registrarCompra(
        cabecera: cabecera,
        detalles: detalles,
      );

      if (ok) {
        _showMessage('Compra registrada con éxito.');
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compras')),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Productos de la compra',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              onPressed: _agregarLinea,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar producto'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: SingleChildScrollView(
                            child: Column(
                              children: List.generate(
                                _lineas.length,
                                (i) => _buildLineaDetalle(i, _lineas[i]),
                              ),
                            ),
                          ),
                        ),

                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: ElevatedButton.icon(
                        //     onPressed: _guardando ? null : _registrarCompra,
                        //     icon: const Icon(Icons.save),
                        //     label: const Text('Registrar compra'),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _compras.isEmpty
                      ? const Center(child: Text('No hay compras registradas.'))
                      : ListView.separated(
                          itemCount: _compras.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = _compras[i];
                            return ListTile(
                              title: Text(
                                '${c.nroComprobante} · ${c.proveedor}',
                              ),
                              subtitle: Text(
                                '${c.fechaHora} · Total: ${c.total.toStringAsFixed(2)} · ${c.tipoPago}',
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
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _guardando ? null : _registrarCompra,
        tooltip: 'Añadir Producto',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProveedorSelector() {
    return DropdownButtonFormField<Proveedor>(
      value: _proveedorSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Proveedor',
        border: OutlineInputBorder(),
      ),
      items: _proveedores.map((p) {
        return DropdownMenuItem(value: p, child: Text(p.nombre));
      }).toList(),
      onChanged: (nuevo) => setState(() => _proveedorSeleccionado = nuevo),
      validator: (_) =>
          _proveedorSeleccionado == null ? 'Selecciona un proveedor' : null,
    );
  }

  Widget _buildTipoComprobanteSelector() {
    return DropdownButtonFormField<TipoComprobante>(
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
    );
  }

  Widget _buildLineaDetalle(int index, _LineaCompraForm linea) {
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
                    value: linea.producto,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                    ),
                    items: _productos.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.nombre));
                    }).toList(),
                    onChanged: (Producto? nuevo) {
                      setState(() {
                        linea.producto = nuevo;
                        if (nuevo != null) {
                          linea.precioCtrl.text = nuevo.precioCosto
                              .toStringAsFixed(2);
                        } else {
                          linea.precioCtrl.text = '0.00';
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
                    items: _ubicaciones.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(u.nombreAlmacen),
                      );
                    }).toList(),
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

class _LineaCompraForm {
  Producto? producto;
  Ubicacion? ubicacionSeleccionada;

  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;

  _LineaCompraForm({this.producto, int cantidadInicial = 1})
    : cantidadCtrl = TextEditingController(text: cantidadInicial.toString()),
      precioCtrl = TextEditingController() {
    if (producto != null) {
      precioCtrl.text = producto!.precioCosto.toStringAsFixed(2);
    } else {
      precioCtrl.text = '0.00';
    }
  }

  void dispose() {
    cantidadCtrl.dispose();
    precioCtrl.dispose();
  }
}
