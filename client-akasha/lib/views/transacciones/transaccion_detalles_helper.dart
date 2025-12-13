import 'package:akasha/core/session_manager.dart';
import 'package:akasha/models/compra.dart';
import 'package:akasha/models/cliente.dart';
import 'package:akasha/models/detalle_compra.dart';
import 'package:akasha/models/detalle_venta.dart';
import 'package:akasha/models/proveedor.dart';
import 'package:akasha/models/tipo_comprobante.dart';
import 'package:akasha/views/transacciones/transaccion_shared.dart';
import 'package:akasha/views/transacciones/transaccion_stock_helper.dart';
import 'package:akasha/views/transacciones/widgets/forms/linea_compra_form.dart';
import 'package:akasha/views/transacciones/widgets/forms/linea_venta_form.dart';
import 'package:akasha/models/venta.dart';

class BuildOutcome<T> {
  final T? data;
  final String? error;

  const BuildOutcome.success(this.data) : error = null;
  const BuildOutcome.failure(this.error) : data = null;

  bool get isSuccess => error == null;
}

class CompraPrepared {
  final CompraCreate cabecera;
  final List<DetalleCompra> detalles;
  final double subtotal;
  final double impuesto;
  final double total;
  final Set<int> productIds;

  const CompraPrepared({
    required this.cabecera,
    required this.detalles,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.productIds,
  });
}

class VentaPrepared {
  final VentaCreate cabecera;
  final List<DetalleVenta> detalles;
  final double subtotal;
  final double impuesto;
  final double total;
  final Set<int> productIds;

  const VentaPrepared({
    required this.cabecera,
    required this.detalles,
    required this.subtotal,
    required this.impuesto,
    required this.total,
    required this.productIds,
  });
}

class CompraDetallesHelper {
  static BuildOutcome<CompraPrepared> build({
    required List<LineaCompraForm> lineas,
    required Proveedor? proveedorSeleccionado,
    required TipoComprobante? tipoComprobanteSeleccionado,
    required bool hasProductos,
    required bool hasUbicaciones,
    required SessionManager sessionManager,
    required double iva,
    required String Function() generarNroComprobante,
  }) {
    if (proveedorSeleccionado?.idProveedor == null) {
      return const BuildOutcome.failure('Debes seleccionar un proveedor válido.');
    }
    if (tipoComprobanteSeleccionado == null) {
      return const BuildOutcome.failure(
        'Debes seleccionar un tipo de comprobante.',
      );
    }
    if (!hasProductos) {
      return const BuildOutcome.failure('No hay productos disponibles.');
    }
    if (!hasUbicaciones) {
      return const BuildOutcome.failure(
        'No hay almacenes/ubicaciones disponibles.',
      );
    }
    if (lineas.isEmpty) {
      return const BuildOutcome.failure(
        'Debes agregar al menos un producto.',
      );
    }

    final usuarioActual = sessionManager.obtenerUsuarioActual();
    if (usuarioActual?.idUsuario == null) {
      return const BuildOutcome.failure(
        'No hay usuario en sesión. Vuelve a iniciar sesión.',
      );
    }

    final List<DetalleCompra> detalles = <DetalleCompra>[];
    final Set<int> productIds = <int>{};
    double subtotalTotal = 0.0;

    for (final linea in lineas) {
      final producto = linea.producto;
      if (producto?.idProducto == null) {
        return const BuildOutcome.failure(
          'Hay una línea sin producto seleccionado.',
        );
      }

      final ubicacion = linea.ubicacionSeleccionada;
      if (ubicacion?.idUbicacion == null) {
        return BuildOutcome.failure(
          'Selecciona una ubicación para ${producto!.nombre}.',
        );
      }

      final int cantidad = parseIntSafe(linea.cantidadCtrl.text);
      if (cantidad <= 0) {
        return const BuildOutcome.failure(
          'Cantidad inválida en una de las líneas.',
        );
      }

      final double precio = producto!.precioCosto;
      if (precio <= 0) {
        return BuildOutcome.failure(
          'El producto ${producto.nombre} tiene precio de costo inválido.',
        );
      }

      final double subtotalLinea = cantidad * precio;
      subtotalTotal += subtotalLinea;

      detalles.add(
        DetalleCompra(
          idProducto: producto.idProducto!,
          cantidad: cantidad,
          precioUnitario: precio,
          subtotal: subtotalLinea,
          idUbicacion: ubicacion!.idUbicacion!,
        ),
      );

      productIds.add(producto.idProducto!);
    }

    final double impuesto = subtotalTotal * iva;
    final double total = subtotalTotal + impuesto;

    final cabecera = CompraCreate(
      idProveedor: proveedorSeleccionado!.idProveedor!,
      idTipoComprobante: tipoComprobanteSeleccionado.idTipoComprobante,
      subtotal: subtotalTotal,
      impuesto: impuesto,
      total: total,
      idUsuario: usuarioActual!.idUsuario!,
      estado: 1,
      nroComprobante: generarNroComprobante(),
    );

    return BuildOutcome.success(
      CompraPrepared(
        cabecera: cabecera,
        detalles: detalles,
        subtotal: subtotalTotal,
        impuesto: impuesto,
        total: total,
        productIds: productIds,
      ),
    );
  }
}

class VentaDetallesHelper {
  static BuildOutcome<VentaPrepared> build({
    required List<LineaVentaForm> lineas,
    required Cliente? clienteSeleccionado,
    required TipoComprobante? tipoComprobanteSeleccionado,
    required bool hasProductos,
    required bool hasUbicaciones,
    required SessionManager sessionManager,
    required StockHelper stockHelper,
    required double iva,
    required String Function() generarNroComprobante,
  }) {
    if (clienteSeleccionado?.idCliente == null) {
      return const BuildOutcome.failure('Debes seleccionar un cliente válido.');
    }
    if (tipoComprobanteSeleccionado == null) {
      return const BuildOutcome.failure(
        'Debes seleccionar un tipo de comprobante.',
      );
    }
    if (!hasProductos) {
      return const BuildOutcome.failure('No hay productos disponibles.');
    }
    if (!hasUbicaciones) {
      return const BuildOutcome.failure(
        'No hay almacenes/ubicaciones disponibles.',
      );
    }
    if (lineas.isEmpty) {
      return const BuildOutcome.failure(
        'Debes agregar al menos un producto.',
      );
    }

    final usuarioActual = sessionManager.obtenerUsuarioActual();
    if (usuarioActual?.idUsuario == null) {
      return const BuildOutcome.failure(
        'No hay usuario en sesión. Vuelve a iniciar sesión.',
      );
    }

    final List<DetalleVenta> detalles = <DetalleVenta>[];
    final Set<int> productIds = <int>{};
    double subtotalTotal = 0.0;

    for (final linea in lineas) {
      final producto = linea.producto;
      if (producto?.idProducto == null) {
        return const BuildOutcome.failure(
          'Hay una línea sin producto seleccionado.',
        );
      }

      final ubicacion = linea.ubicacionSeleccionada;
      if (ubicacion?.idUbicacion == null) {
        return BuildOutcome.failure(
          'Selecciona una ubicación para ${producto!.nombre}.',
        );
      }

      final int cantidad = parseIntSafe(linea.cantidadCtrl.text);
      if (cantidad <= 0) {
        return const BuildOutcome.failure(
          'Cantidad inválida en una de las líneas.',
        );
      }

      // Validación final de stock
      final stockActual =
          stockHelper.stockEnUbicacion(producto!.idProducto, ubicacion);
      if (cantidad > stockActual) {
        return BuildOutcome.failure(
          'Stock insuficiente para ${producto.nombre} en ${ubicacion?.nombreAlmacen}. Solo hay $stockActual unidades.',
        );
      }

      final double precio = producto.precioVenta;
      if (precio <= 0) {
        return BuildOutcome.failure(
          'El producto ${producto.nombre} tiene precio de venta inválido.',
        );
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

      productIds.add(producto.idProducto!);
    }

    final double impuesto = subtotalTotal * iva;
    final double total = subtotalTotal + impuesto;

    final cabecera = VentaCreate(
      idCliente: clienteSeleccionado!.idCliente!,
      idTipoComprobante: tipoComprobanteSeleccionado.idTipoComprobante,
      subtotal: subtotalTotal,
      impuesto: impuesto,
      total: total,
      idUsuario: usuarioActual!.idUsuario!,
      nroComprobante: generarNroComprobante(),
    );

    return BuildOutcome.success(
      VentaPrepared(
        cabecera: cabecera,
        detalles: detalles,
        subtotal: subtotalTotal,
        impuesto: impuesto,
        total: total,
        productIds: productIds,
      ),
    );
  }
}
