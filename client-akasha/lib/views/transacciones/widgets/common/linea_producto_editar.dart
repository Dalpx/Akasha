import 'package:akasha/models/producto.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_shared.dart';
import 'package:akasha/views/transacciones/widgets/helpers/transaccion_stock_helper.dart';
import 'package:flutter/material.dart';

class StockBannerStyle {
  final Color background;
  final Color borderColor;
  final Color valueColor;

  const StockBannerStyle({
    required this.background,
    required this.borderColor,
    required this.valueColor,
  });
}

class LineaProductoEditor<TLine> extends StatelessWidget {
  final TLine line;

  final List<Producto> productos;
  final List<Ubicacion> ubicaciones;
  final StockHelper stock;

  /// Obtiene las ubicaciones permitidas para el producto:
  /// - compras: ubicacionesAsignadas(...)
  /// - ventas: ubicacionesConStock(...)
  final List<Ubicacion> Function(int? idProducto, List<Ubicacion> ubicaciones)
      ubicacionesDisponibles;

  /// Si `ubicacionesDisponibles` devuelve vacío pero hay ubicaciones globales,
  /// aquí decides si el dropdown muestra todas (compras) o ninguna (ventas).
  final bool fallbackToAllUbicacionesWhenEmpty;

  /// Cómo comparar ubicaciones para validar/ajustar selección.
  /// - compras: por nombreAlmacen
  /// - ventas: por idUbicacion
  final bool Function(Ubicacion a, Ubicacion b) ubicacionMatches;

  /// Precio unitario del producto (costo o venta)
  final double Function(Producto p) precioUnitario;
  final String labelPrecio;

  /// Texto del banner de stock (compras vs ventas)
  final String Function(Ubicacion u) stockLabelBuilder;
  final StockBannerStyle Function(int stockDisponible) stockStyleBuilder;

  /// Validación de cantidad (compras vs ventas)
  final String? Function(String? value, int stockDisponible) cantidadValidator;

  /// Validación de ubicación (compras vs ventas)
  final String? Function(
    Ubicacion? value,
    List<Ubicacion> disponibles,
    List<Ubicacion> todas,
  ) ubicacionValidator;

  /// Para ventas: ajustar cantidad cuando cambia stock (0 => "0", etc)
  final void Function(TLine line, int stockDisponible) onAfterStockRecalc;

  /// Accessors: así no dependemos de interfaces en tus Linea*Form
  final Producto? Function(TLine l) getProducto;
  final void Function(TLine l, Producto? p) setProducto;

  final Ubicacion? Function(TLine l) getUbicacion;
  final void Function(TLine l, Ubicacion? u) setUbicacion;

  final TextEditingController Function(TLine l) cantidadCtrl;
  final TextEditingController Function(TLine l) precioCtrl;

  final int Function(TLine l) getStock;
  final void Function(TLine l, int v) setStock;

  final VoidCallback requestRebuild;

  final VoidCallback onDelete;
  final bool canDelete;

  const LineaProductoEditor({
    super.key,
    required this.line,
    required this.productos,
    required this.ubicaciones,
    required this.stock,
    required this.ubicacionesDisponibles,
    required this.fallbackToAllUbicacionesWhenEmpty,
    required this.ubicacionMatches,
    required this.precioUnitario,
    required this.labelPrecio,
    required this.stockLabelBuilder,
    required this.stockStyleBuilder,
    required this.cantidadValidator,
    required this.ubicacionValidator,
    required this.onAfterStockRecalc,
    required this.getProducto,
    required this.setProducto,
    required this.getUbicacion,
    required this.setUbicacion,
    required this.cantidadCtrl,
    required this.precioCtrl,
    required this.getStock,
    required this.setStock,
    required this.requestRebuild,
    required this.onDelete,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Items de ubicaciones
    final producto = getProducto(line);
    final filtered = ubicacionesDisponibles(producto?.idProducto, ubicaciones);

    final items = filtered.isNotEmpty
        ? filtered
        : (fallbackToAllUbicacionesWhenEmpty ? ubicaciones : <Ubicacion>[]);

    // 2) Sanitizar ubicación seleccionada si ya no es válida
    var selectedUb = getUbicacion(line);
    if (selectedUb != null &&
        !items.any((u) => ubicacionMatches(u, selectedUb!))) {
      selectedUb = items.isNotEmpty ? items.first : null;
      setUbicacion(line, selectedUb);
    }

    // 3) Recalcular stock actual
    final stockActual = stock.stockEnUbicacion(producto?.idProducto, selectedUb);
    setStock(line, stockActual);

    // --- Widgets internos ---
    final productoSelector = DropdownButtonFormField<Producto>(
      value: producto,
      decoration: const InputDecoration(
        labelText: 'Producto',
        border: OutlineInputBorder(),
      ),
      items: productos
          .map((p) => DropdownMenuItem(value: p, child: Text(p.nombre)))
          .toList(),
      onChanged: (Producto? nuevo) async {
        if (nuevo == null) {
          setProducto(line, null);
          precioCtrl(line).text = '0.00';
          setStock(line, 0);
          setUbicacion(line, null);
          onAfterStockRecalc(line, 0);
          requestRebuild();
          return;
        }

        await stock.ensureLoadedForProduct(nuevo.idProducto);

        setProducto(line, nuevo);
        precioCtrl(line).text = precioUnitario(nuevo).toStringAsFixed(2);

        final filtered2 =
            ubicacionesDisponibles(nuevo.idProducto, ubicaciones);
        final items2 = filtered2.isNotEmpty
            ? filtered2
            : (fallbackToAllUbicacionesWhenEmpty ? ubicaciones : <Ubicacion>[]);

        final nuevaUb = items2.isNotEmpty ? items2.first : null;
        setUbicacion(line, nuevaUb);

        final stockNuevo = stock.stockEnUbicacion(nuevo.idProducto, nuevaUb);
        setStock(line, stockNuevo);
        onAfterStockRecalc(line, stockNuevo);

        requestRebuild();
      },
      validator: (_) => getProducto(line) == null ? 'Selecciona un producto' : null,
    );

    final banner = (getProducto(line) != null && getUbicacion(line) != null)
        ? () {
            final u = getUbicacion(line)!;
            final st = stockStyleBuilder(getStock(line));
            return StockBannerCard(
              label: stockLabelBuilder(u),
              stock: getStock(line),
              background: st.background,
              borderColor: st.borderColor,
              valueColor: st.valueColor,
            );
          }()
        : null;

    final cantidadField = TextFormField(
      controller: cantidadCtrl(line),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Cantidad',
        border: OutlineInputBorder(),
      ),
      validator: (value) => cantidadValidator(value, getStock(line)),
    );

    final precioField = TextFormField(
      controller: precioCtrl(line),
      readOnly: true,
      enabled: false,
      decoration: InputDecoration(
        labelText: labelPrecio,
        border: const OutlineInputBorder(),
      ),
    );

    final ubicacionField = DropdownButtonFormField<Ubicacion>(
      value: getUbicacion(line),
      decoration: const InputDecoration(
        labelText: 'Ubicación',
        border: OutlineInputBorder(),
      ),
      items: items
          .map(
            (u) => DropdownMenuItem(
              value: u,
              child: Text(u.nombreAlmacen),
            ),
          )
          .toList(),
      onChanged: (Ubicacion? nueva) {
        setUbicacion(line, nueva);
        final stockNuevo =
            stock.stockEnUbicacion(getProducto(line)?.idProducto, nueva);
        setStock(line, stockNuevo);
        onAfterStockRecalc(line, stockNuevo);
        requestRebuild();
      },
      validator: (v) => ubicacionValidator(v, items, ubicaciones),
    );

    return LineaProductoCardBase(
      productoSelector: productoSelector,
      stockBanner: banner,
      cantidadField: cantidadField,
      precioField: precioField,
      ubicacionField: ubicacionField,
      onDelete: onDelete,
      canDelete: canDelete,
    );
  }
}
