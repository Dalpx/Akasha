import 'dart:math';

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
import 'package:flutter/material.dart';

class VentasPage extends StatefulWidget {
  final SessionManager sessionManager;

  const VentasPage({super.key, required this.sessionManager});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final _formKey = GlobalKey<FormState>();

  // Servicios
  final VentaService _ventaService = VentaService();
  final ClienteService _clienteService = ClienteService();
  final InventarioService _inventarioService = InventarioService();
  final UbicacionService _ubicacionService = UbicacionService();
  final TipoComprobanteService _tipoComprobanteService =
      TipoComprobanteService();

  // Catálogos
  List<Venta> _ventas = <Venta>[];
  List<Cliente> _clientes = <Cliente>[];
  List<Producto> _productos = <Producto>[];
  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  List<TipoComprobante> _tiposComprobante = <TipoComprobante>[];

  Cliente? _clienteSeleccionado;
  TipoComprobante? _tipoComprobanteSeleccionado;

  // Líneas de factura
  final List<_LineaVentaForm> _lineas = <_LineaVentaForm>[];

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

    final Future<List<Venta>> ventasFuture = _ventaService
        .obtenerVentas()
        .catchError((e) {
          return <Venta>[];
        });

    try {
      final resultados = await Future.wait([
        ventasFuture, 
        _clienteService.obtenerClientesActivos(),
        _inventarioService.obtenerProductos(),
        _tipoComprobanteService.obtenerTiposComprobante(),
        _ubicacionService.obtenerUbicacionesActivas(),
      ]);

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

        _inicializarLineas();
      });
    } catch (e) {
      // Este catch ahora solo capturará errores en la carga de datos esenciales
      _showMessage('Error cargando datos iniciales: $e');
    } finally {
      if (mounted) {
        setState(() => _cargandoInicial = false);
      }
    }
  }

  Future<void> _verDetalleVenta(Venta v) async {
    // Opción simple con loading rápido
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

      for (var element in detalles) {
        print(element.toString());
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // cierra loading

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
      Navigator.of(context).pop(); // cierra loading
      _showMessage('No se pudo cargar el detalle: $e');
    }
  }

  void _inicializarLineas() {
    for (final l in _lineas) {
      l.dispose();
    }
    _lineas.clear();

    final primera = _LineaVentaForm(
      producto: _productos.isNotEmpty ? _productos.first : null,
    );

    if (_ubicaciones.isNotEmpty) {
      primera.ubicacionSeleccionada = _ubicaciones.first;
    }

    _lineas.add(primera);
  }

  void _agregarLinea() {
    final linea = _LineaVentaForm(
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

  Future<void> _refrescarVentas() async {
    try {
      final ventas = await _ventaService.obtenerVentas();
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

    // Validar y construir detalles
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

      // Precio SIEMPRE desde tabla_producto
      final double precio = producto!.precioVenta;
      if (precio <= 0) {
        _showMessage(
          'El producto ${producto.nombre} tiene precio de venta inválido.',
        );
        return;
      }

      final int idUbicacion = ubicacion!.idUbicacion!;

      // // Validación de stock por ubicación seleccionada
      // try {
      //   final stockDisponible = await _inventarioService
      //       .obtenerStockPorUbicacion(producto.idProducto!, idUbicacion);

      //   if (stockDisponible < cantidad) {
      //     _showMessage(
      //       'Stock insuficiente para ${producto.nombre} en ${ubicacion.nombreAlmacen}. '
      //       'Disponible: $stockDisponible.',
      //     );
      //     return;
      //   }
      // } catch (e) {
      //   _showMessage('Error verificando stock de ${producto.nombre}: $e');
      //   return;
      // }

      final double subtotalLinea = cantidad * precio;
      subtotalTotal += subtotalLinea;

      detalles.add(
        DetalleVenta(
          idProducto: producto.idProducto!,
          cantidad: cantidad,
          precioUnitario: precio,
          subtotal: subtotalLinea,
          idUbicacion: idUbicacion,
        ),
      );
    }

    if (detalles.isEmpty) {
      _showMessage('No hay productos válidos en la venta.');
      return;
    }

    final double impuesto = subtotalTotal * 0.21; // ajustable
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
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ventas')),
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
                            _buildClienteSelector(),
                            _buildTipoComprobanteSelector(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Productos de la factura',
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
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _ventas.isEmpty
                      ? const Center(child: Text('No hay ventas registradas.'))
                      : ListView.separated(
                          itemCount: _ventas.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final v = _ventas[i];
                            return ListTile(
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
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _guardando ? null : _registrarVenta,
        tooltip: 'Agregar ventas',
        child: const Icon(Icons.add),
      ),
    );
  }

  // -------- Cabecera --------

  Widget _buildClienteSelector() {
    return DropdownButtonFormField<Cliente>(
      value: _clienteSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Cliente',
        border: OutlineInputBorder(),
      ),
      items: _clientes.map((c) {
        final label = '${c.nombre} ${c.apellido} (${c.nroDocumento})';
        return DropdownMenuItem(value: c, child: Text(label));
      }).toList(),
      onChanged: (nuevo) => setState(() => _clienteSeleccionado = nuevo),
      validator: (_) =>
          _clienteSeleccionado == null ? 'Selecciona un cliente' : null,
    );
  }

  Widget _buildTipoComprobanteSelector() {
    return DropdownButtonFormField<TipoComprobante>(
      value: _tipoComprobanteSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Método de pago / tipo comprobante',
        border: OutlineInputBorder(),
      ),
      items: _tiposComprobante.map((t) {
        return DropdownMenuItem(value: t, child: Text(t.nombre));
      }).toList(),
      onChanged: (nuevo) =>
          setState(() => _tipoComprobanteSeleccionado = nuevo),
      validator: (_) => _tipoComprobanteSeleccionado == null
          ? 'Selecciona un método de pago'
          : null,
    );
  }

  Widget _buildLineaDetalle(int index, _LineaVentaForm linea) {
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
                          linea.precioCtrl.text = nuevo.precioVenta
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
            const SizedBox(height: 8),
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
                      labelText: 'Precio unitario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: null,
                    readOnly: true,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
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

// ---------------- Clase de línea ----------------

class _LineaVentaForm {
  Producto? producto;
  Ubicacion? ubicacionSeleccionada;

  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;

  _LineaVentaForm({this.producto, int cantidadInicial = 1})
    : cantidadCtrl = TextEditingController(text: cantidadInicial.toString()),
      precioCtrl = TextEditingController() {
    if (producto != null) {
      precioCtrl.text = producto!.precioVenta.toStringAsFixed(2);
    } else {
      precioCtrl.text = '0.00';
    }
  }

  void dispose() {
    cantidadCtrl.dispose();
    precioCtrl.dispose();
  }
}
