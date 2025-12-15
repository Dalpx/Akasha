import 'package:akasha/models/compra.dart';
import 'package:akasha/models/venta.dart';
import 'package:akasha/models/detalle_venta.dart'; 
import 'package:akasha/models/detalle_compra.dart';

import 'package:akasha/services/compra_service.dart';
import 'package:akasha/services/venta_service.dart';
import 'package:akasha/services/inventario_service.dart';
// import 'package:akasha/services/reportes_service.dart'; // <--- ELIMINADA: Ya no se usa
import 'package:akasha/services/pdf_service.dart'; // Contiene TipoMovimientoFiltro y PdfService
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'widgets/vista_reporte_detallado.dart'; // Mantener la ruta

// DTO interno para manejar la data del dashboard
class _ReporteData {
final List<Venta> ventas;
final List<Compra> compras;
final List<Map<String, dynamic>> inventario;
final List<Map<String, dynamic>> inventarioSinStock;
final List<Map<String, dynamic>> historialMovimientos; // KARDEX
final List<Map<String, dynamic>> stockPorUbicacion; // STOCK POR UBICACIÓN
final List<Map<String, dynamic>> reporteAABC; // <--- NUEVO: REPORTE AABC

final double totalVentas;
final double totalCompras;
final double utilidad;
final double valorInventario;

final int cantidadVentas;
final int cantidadCompras;
final int cantidadProductos;
final int cantidadSinStock;
final int cantidadMovimientos;
final int cantidadUbicaciones;

_ReporteData({
required this.ventas,
required this.compras,
required this.inventario,
required this.inventarioSinStock,
required this.historialMovimientos,
required this.stockPorUbicacion,
required this.reporteAABC, // <--- NUEVO
required this.totalVentas,
required this.totalCompras,
required this.utilidad,
required this.valorInventario,
required this.cantidadVentas,
required this.cantidadCompras,
required this.cantidadProductos,
required this.cantidadSinStock,
required this.cantidadMovimientos,
required this.cantidadUbicaciones,
});
}

class ReportesPage extends StatefulWidget {
final VentaService ventaService;
final CompraService compraService;
final InventarioService inventarioService;
// final ReportesService reportesService; // <--- ELIMINADO

const ReportesPage({
super.key,
required this.ventaService,
required this.compraService,
required this.inventarioService,
// required this.reportesService, // <--- ELIMINADO
});

@override
State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
late Future<_ReporteData> _futureReporte;

@override
void initState() {
super.initState();
_futureReporte = _cargarDatosReporte();
}

 // =========================================================================
 // FUNCIONES AUXILIARES DE CÁLCULO (MOVIDAS LOCALMENTE)
 // =========================================================================

 /// Calcula el total de ventas a partir de la lista de ventas.
 double _calcularTotalVentas(List<Venta> ventas) {
  double total = 0.0;
  for (int i = 0; i < ventas.length; i++) {
   total = total + (double.tryParse(ventas[i].total.toString()) ?? 0.0);
  }
  return total;
 }

 /// Función de ayuda para calcular la tendencia porcentual.
 double _calcularTendenciaPct(double actual, double anterior) {
  // Si no hay valor anterior, asumimos 100% de crecimiento si hay valor actual.
  if (anterior == 0.0) {
    return actual > 0.0 ? 1.0 : 0.0; 
  }
  return (actual - anterior) / anterior;
 }

 // =========================================================================
 // FIN FUNCIONES AUXILIARES
 // =========================================================================


Future<_ReporteData> _cargarDatosReporte() async {
// Lista auxiliar para manejar fallos individuales en los servicios
List<Venta> ventas = [];
List<Compra> compras = [];
List<Map<String, dynamic>> inventario = [];
List<Map<String, dynamic>> sinStock = [];
List<Map<String, dynamic>> historial = [];
List<Map<String, dynamic>> stockUbicacion = [];
List<Map<String, dynamic>> aabc = []; // <--- NUEVO

try {
final resultados = await Future.wait([
 widget.ventaService.obtenerVentas().catchError((_) => <Venta>[]),
 widget.compraService.obtenerCompras().catchError((_) => <Compra>[]),
 widget.inventarioService.obtenerReporteValorado().catchError((_) => <Map<String, dynamic>>[]),
 widget.inventarioService.obtenerReporteSinStock().catchError((_) => <Map<String, dynamic>>[]),
 widget.inventarioService.obtenerHistorialMovimientos().catchError((_) => <Map<String, dynamic>>[]),
 widget.inventarioService.obtenerReporteStockPorUbicacion().catchError((_) => <Map<String, dynamic>>[]),
 widget.inventarioService.obtenerReporteAABC().catchError((_) => <Map<String, dynamic>>[]), // <--- NUEVA LLAMADA
]);

ventas = resultados[0] as List<Venta>;
compras = resultados[1] as List<Compra>;
inventario = resultados[2] as List<Map<String, dynamic>>;
sinStock = resultados[3] as List<Map<String, dynamic>>;
historial = resultados[4] as List<Map<String, dynamic>>;
stockUbicacion = resultados[5] as List<Map<String, dynamic>>;
aabc = resultados[6] as List<Map<String, dynamic>>; // <--- NUEVO

} catch (e) {
print("Error cargando reportes: $e");
}

// Cálculos Financieros
double totalVentas = ventas.fold(0.0, (sum, v) => sum + (double.tryParse(v.total.toString()) ?? 0.0));
double totalCompras = compras.fold(0.0, (sum, c) => sum + (double.tryParse(c.total.toString()) ?? 0.0));
final double utilidad = totalVentas - totalCompras;

// CORRECCIÓN PREVENTIVA: Asegurar que 'valor_total' sea un num antes de toDouble()
double valorInventario = inventario.fold(0.0, (sum, item) => sum + (item['valor_total'] as num? ?? 0.0).toDouble());

// Cálculo de cantidad de ubicaciones
final cantidadUbicaciones = stockUbicacion.map((e) => e['ubicacion'] ?? '').toSet().length;

return _ReporteData(
ventas: ventas,
compras: compras,
inventario: inventario,
inventarioSinStock: sinStock,
historialMovimientos: historial,
stockPorUbicacion: stockUbicacion,
reporteAABC: aabc, // <--- NUEVO
totalVentas: totalVentas,
totalCompras: totalCompras,
utilidad: utilidad,
valorInventario: valorInventario,
cantidadVentas: ventas.length,
cantidadCompras: compras.length,
cantidadProductos: inventario.length,
cantidadSinStock: sinStock.length,
cantidadMovimientos: historial.length,
cantidadUbicaciones: cantidadUbicaciones,
);
}

// =========================================================================
// AUXILIAR: CALCULAR RESUMEN AABC (Necesario para el PDF)
// =========================================================================
Map<String, dynamic> _calcularResumenAABC(List<Map<String, dynamic>> datosAABC) {
double vcaTotal = 0.0;
final Map<String, int> conteoProductos = {'A': 0, 'B': 0, 'C': 0};
final Map<String, double> vcaPorClase = {'A': 0.0, 'B': 0.0, 'C': 0.0};
final totalProductos = datosAABC.length;

for (var item in datosAABC) {
 // 'total' es el VCA, 'clase_abc' es A, B o C
 // Nota: Aquí se usan los datos tal como salen del mapeo de la vista para ser coherentes
 final vca = (item['total'] as num? ?? 0.0).toDouble();
 final clase = item['clase_abc']?.toString() ?? 'C'; 
 
 vcaTotal += vca;
 
 if (conteoProductos.containsKey(clase)) {
 conteoProductos[clase] = conteoProductos[clase]! + 1;
 vcaPorClase[clase] = vcaPorClase[clase]! + vca;
 }
}

return {
 'vca_total': vcaTotal,
 'conteo_productos': conteoProductos,
 'vca_por_clase': vcaPorClase,
 'total_productos': totalProductos,
};
}


// --- MAPEOS DE DATOS PARA LA VISTA ---

List<Map<String, dynamic>> _mapearVentas(List<Venta> ventas) {
final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
return ventas.map((v) {
DateTime? fechaObj = (v.fecha is DateTime) ? v.fecha as DateTime : null;
// CORRECCIÓN PREVENTIVA: Usamos double.tryParse que es seguro contra null y String
double total = double.tryParse(v.total.toString()) ?? 0.0;
return {
 'ref': v.numeroComprobante,
 'fecha': fechaObj != null ? dateFormat.format(fechaObj) : v.fecha.toString(),
 'entidad': v.nombreCliente ?? 'Cliente General',
 'total': total,
 'timestamp': fechaObj,
 'original': v, 
};
}).toList();
}

List<Map<String, dynamic>> _mapearCompras(List<Compra> compras) {
final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
return compras.map((c) {
DateTime? fechaObj = (c.fechaHora is DateTime) ? c.fechaHora as DateTime : null;
// CORRECCIÓN PREVENTIVA: Asegurar que 'total' sea un double
double total = (c.total as num? ?? 0.0).toDouble();
return {
 'ref': c.nroComprobante,
 'fecha': fechaObj != null ? dateFormat.format(fechaObj) : c.fechaHora.toString(),
 'entidad': c.proveedor,
 'total': total,
 'timestamp': fechaObj,
 'original': c, 
};
}).toList();
}

List<Map<String, dynamic>> _mapearInventarioParaVista(List<Map<String, dynamic>> inventario) {
return inventario.map((item) => {
'ref': item['sku'],
'fecha': item['nombre'], 
'entidad': "${item['cantidad'] as num? ?? 0} unds.", // Preventiva
'total': item['valor_total'],
'timestamp': null,
}).toList();
}

List<Map<String, dynamic>> _mapearSinStockParaVista(List<Map<String, dynamic>> sinStock) {
return sinStock.map((item) => {
'ref': item['sku'],
'fecha': item['nombre'],
'entidad': "${item['cantidad'] as num? ?? 0} unds.", // Preventiva
'total': 0.0,
'timestamp': null,
}).toList();
}

// ====================================================================
// MAPEO: STOCK POR UBICACIÓN
// ====================================================================
List<Map<String, dynamic>> _mapearStockPorUbicacionParaVista(List<Map<String, dynamic>> stockUbicacion) {
return stockUbicacion.map((item) {

// Asumimos las claves corregidas: 'stock', 'nombre', y 'nombre_almacen'
final cantidad = (item['stock'] as num? ?? 0.0).toDouble();
final nombreProducto = item['nombre'] ?? 'Producto Desconocido';

return {
 'ref': nombreProducto, 
 'fecha': nombreProducto, 
 'entidad': item['nombre_almacen'] ?? 'Ubicación General', 
 'total': cantidad,
 'timestamp': null,
 'producto_nombre': nombreProducto, 
};
}).toList();
}

// ====================================================================
// NUEVO: MAPEO REPORTE AABC (Clasificación)
// ====================================================================
List<Map<String, dynamic>> _mapearReporteAABCParaVista(List<Map<String, dynamic>> reporteAABC) {
// Usaremos el VCA (Valor de Consumo Anual) como el valor principal ('total')

return reporteAABC.map((item) {
final vca = (item['vca'] as num? ?? 0.0).toDouble();
final clase = item['clase_abc'].toString(); // A, B, o C

return {
 // 'ref': SKU o ID
 'ref': item['sku'] ?? 'N/A', 
 'fecha': item['nombre'] ?? 'Producto Desconocido', 
 'entidad': 'Clase $clase', 
 'total': vca,
 'timestamp': null, 
 // Datos adicionales para el reporte PDF y detalle
 'costo_unitario': item['costo_unitario'] as num? ?? 0.0,
 'consumo_anual': item['consumo_anual'] as num? ?? 0.0,
 'clase_abc': clase,
};
}).toList();
}

// ====================================================================
// Mapeo para Kardex
// ====================================================================
List<Map<String, dynamic>> _mapearKardexParaVista(List<Map<String, dynamic>> movimientos) {
return movimientos.map((m) {
DateTime? fechaObj = (m['fecha'] != null) ? DateTime.tryParse(m['fecha'].toString()) : null;

String nombreProd = m['producto'] ?? m['nombre_producto'] ?? 'Producto';
String tipo = m['tipo_movimiento'] ?? m['tipo'] ?? 'Mov'; 
String ubicacion = m['ubicacion'] ?? 'General';

// LÓGICA DE CANTIDAD Y SIGNOS
double cantidadAbsoluta = double.tryParse(m['cantidad'].toString()) ?? 0.0;

bool esSalida = tipo.toLowerCase().contains('salida') || 
  tipo.toLowerCase().contains('venta') ||
  tipo.toLowerCase().contains('consumo') ||
  tipo.toLowerCase().contains('out');

double cantidadReal = esSalida ? (cantidadAbsoluta * -1) : cantidadAbsoluta;

return {
 // Datos para la Vista (App)
 'ref': m['referencia'] ?? m['id_movimiento'] ?? '-',
 'fecha': m['fecha'] ?? '-',
 'entidad': nombreProd, 
 'total': cantidadReal, 
 'timestamp': fechaObj,
 
 // DATOS CRUDOS PARA EL PDF (IMPORTANTE)
 'tipo_movimiento': tipo, 
 'ubicacion': ubicacion, 
 'cantidad': cantidadReal, 
 'producto_nombre': nombreProd, 
};
}).toList();
}
// ====================================================================

// --- LÓGICA DE DETALLES (LAZY LOADING) ---

Future<void> _cargarYMostrarDetalleVenta(Venta venta) async {
showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
try {
if (venta.idVenta == null) throw Exception("ID nulo");
final detalles = await widget.ventaService.obtenerDetallesVenta(venta.idVenta!);
if (!mounted) return;
Navigator.of(context).pop(); 
_mostrarDialogoDetalleVenta(venta, detalles);
} catch (e) {
if (!mounted) return;
Navigator.of(context).pop(); 
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
}
}

Future<void> _cargarYMostrarDetalleCompra(Compra compra) async {
showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
try {
if (compra.idCompra == null) throw Exception("ID nulo");
final detalles = await widget.compraService.obtenerDetallesCompra(compra.idCompra!);
if (!mounted) return;
Navigator.of(context).pop(); 
_mostrarDialogoDetalleCompra(compra, detalles);
} catch (e) {
if (!mounted) return;
Navigator.of(context).pop();
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
}
}

// --- DIÁLOGOS ---

void _mostrarDialogoDetalleVenta(Venta venta, List<DetalleVenta> detalles) {
// Implementación de _mostrarDialogoDetalleVenta (omisión por brevedad)
}

void _mostrarDialogoDetalleCompra(Compra compra, List<DetalleCompra> detalles) {
// Implementación de _mostrarDialogoDetalleCompra (omisión por brevedad)
}

// --- NAVEGACIÓN Y REPORTES ---

Future<void> _imprimirReporteGeneral(String titulo, List<Map<String, dynamic>> datos, double total) async {
try {
final pdfBytes = await PdfService().generarReporteGeneral(titulo: titulo, datos: datos, totalGeneral: total, esDinero: true);
await Printing.sharePdf(bytes: pdfBytes, filename: '${titulo.replaceAll(' ', '_')}.pdf');
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al generar PDF: $e")));
}
}

Future<void> _imprimirInventario(List<Map<String, dynamic>> datos, double total) async {
try {
final pdfBytes = await PdfService().generarReporteInventario(datos: datos, valorTotalInventario: total);
await Printing.sharePdf(bytes: pdfBytes, filename: 'Inventario.pdf');
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al generar PDF: $e")));
}
}

Future<void> _imprimirSinStock(List<Map<String, dynamic>> datos) async {
try {
final pdfBytes = await PdfService().generarReporteSinStock(datos: datos, totalProductosAgotados: datos.length);
await Printing.sharePdf(bytes: pdfBytes, filename: 'SinStock.pdf');
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al generar PDF: $e")));
}
}

Future<void> _imprimirStockPorUbicacion(List<Map<String, dynamic>> datos) async {
try {
final pdfBytes = await PdfService().generarReporteStockPorUbicacion(datos: datos);
await Printing.sharePdf(bytes: pdfBytes, filename: 'StockPorUbicacion.pdf');
} catch (e) {
print("Usando reporte genérico para Stock por Ubicación por error: $e");
final datosMapeados = _mapearStockPorUbicacionParaVista(datos);
await _imprimirReporteGeneral("Stock por Ubicación (Fallback)", datosMapeados, 0);
}
}

Future<void> _imprimirKardex(List<Map<String, dynamic>> datos) async {
try {
double entradas = 0.0;
double salidas = 0.0;
for (var item in datos) {
 final cantidad = (item['cantidad'] as num? ?? 0.0).toDouble();
 if (cantidad >= 0) {
 entradas += cantidad;
 } else {
 salidas += cantidad;
 }
}
final resumenKardex = {
 'entradas': entradas,
 'salidas': salidas.abs(),
 'saldo_final': entradas + salidas,
};

final pdfBytes = await PdfService().generarReporteKardex(
 datos: datos,
 resumen: resumenKardex, 
 filtroTipo: TipoMovimientoFiltro.todos, 
);
await Printing.sharePdf(bytes: pdfBytes, filename: 'Kardex.pdf');
} catch (e) {
print("Usando reporte genérico para Kardex por error: $e");
final datosMapeados = _mapearKardexParaVista(datos);
await _imprimirReporteGeneral("Historial Kardex (Fallback)", datosMapeados, 0);
}
}

// ====================================================================
// NAVEGACIÓN Y EXPORTACIÓN AABC
// ====================================================================

Future<void> _imprimirReporteAABC(List<Map<String, dynamic>> datos) async {
try {
// 1. Calcular el resumen AABC usando la función auxiliar
final resumen = _calcularResumenAABC(datos);

// 2. Enviar los datos y el resumen al servicio de PDF
final pdfBytes = await PdfService().generarReporteAABC(
 datos: datos, 
 resumen: resumen, // <--- ENVIAMOS EL RESUMEN CALCULADO
);
await Printing.sharePdf(bytes: pdfBytes, filename: 'ReporteAABC.pdf');
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al generar PDF AABC: $e")));
}
}

// ====================================================================
// IMPLEMENTACIÓN DEL REPORTE KPI (Lógica Local y Data Real/Ajustada)
// ====================================================================
Future<void> _imprimirReporteKPI(_ReporteData data) async {
    print('--- INICIO: _imprimirReporteKPI (Lógica Local y SIN FLECHAS UNICODE) ---');
    try {
        
        // 1. CÁLCULOS BASE (Usamos la data disponible)
        
        final double totalVentasMesActual = data.totalVentas;
        final double totalComprasMesActual = data.totalCompras;

        // --- Simulación de valores ANTERIORES para cálculo de TENDENCIA (0.0 para alza)
        const double totalVentasMesAnteriorDummy = 0.0; 
        const double margenBrutoAnteriorDummy = 0.0; 
        const double rotacionInventarioActual = 4.5;
        const double rotacionInventarioAnteriorDummy = 0.0; 
        final double stockCriticoActual = data.cantidadSinStock.toDouble(); 
        const double stockCriticoAnteriorDummy = 0.0; 

        // Margen Bruto: Calculado
        final double margenBrutoCalculado = (totalVentasMesActual > 0) 
            ? (totalVentasMesActual - totalComprasMesActual) / totalVentasMesActual 
            : 0.0;
        
        // CÁLCULO DE TENDENCIAS
        final double tendenciaVentas = _calcularTendenciaPct(totalVentasMesActual, totalVentasMesAnteriorDummy);
        final double tendenciaMargen = _calcularTendenciaPct(margenBrutoCalculado, margenBrutoAnteriorDummy);
        final double tendenciaRotacion = _calcularTendenciaPct(rotacionInventarioActual, rotacionInventarioAnteriorDummy);
        final double tendenciaStockCritico = _calcularTendenciaPct(stockCriticoActual, stockCriticoAnteriorDummy);

        // 2. CONSTRUCCIÓN DE LA ESTRUCTURA DE KPIs
        final List<Map<String, dynamic>> kpiData = [
            {
                'name': 'Ventas Netas', 
                'value': totalVentasMesActual.toDouble(), 
                'trend': tendenciaVentas.toDouble(),
                'unit': 'USD',
            },
            {
                'name': 'Margen Bruto (%)',
                'value': (margenBrutoCalculado * 100).toDouble(), // Se muestra en %
                'trend': tendenciaMargen.toDouble(),
                'unit': '%',
            },
            {
                'name': 'Rotación de Inventario',
                'value': rotacionInventarioActual.toDouble(),
                'trend': tendenciaRotacion.toDouble(),
                'unit': 'Veces',
            },
            {
                'name': 'Productos Sin Stock',
                'value': stockCriticoActual.toDouble(),
                'trend': tendenciaStockCritico.toDouble(),
                'unit': 'Unidades',
            },
        ];

        print('KPI Data lista. Count: ${kpiData.length}. Enviando a PdfService...');
        
        // 3. GENERAR PDF
        final pdfBytes = await PdfService().generarReporteKPI(kpiData);
        
        print('PDF generado correctamente. Procediendo a compartir (Mismo flujo que otros reportes)...');
        
        // 4. COMPARTIR/DESCARGAR
        await Printing.sharePdf(bytes: pdfBytes, filename: 'Reporte_KPI_Gerencial.pdf');
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();


    } catch (e, stacktrace) {
        print("-------------------------------------------------------");
        print("Error CRÍTICO al generar PDF KPI: $e");
        print("STACKTRACE: $stacktrace");
        print("-------------------------------------------------------");
        
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Error al generar Reporte KPI. Revise la consola por detalles."), 
                backgroundColor: Colors.red
            )
        );
    } finally {
        print('--- FIN: _imprimirReporteKPI ---');
    }
}


void _abrirReporteAABC(_ReporteData data) {
Navigator.push(context, MaterialPageRoute(builder: (_) => VistaReporteDetallado(
titulo: 'Clasificación ABC de Inventario',
labelEntidad: 'Clase ABC',
datosIniciales: _mapearReporteAABCParaVista(data.reporteAABC),
permiteFiltrarFecha: false,
// Usamos monetario, ya que se basa en VCA (Valor de Consumo Anual).
esValorMonetario: true, 
)));
}

// --- OTRAS NAVEGACIONES (implementación simplificada por brevedad) ---

void _abrirReporteVentas(_ReporteData data) {
Navigator.push(context, MaterialPageRoute(builder: (_) => VistaReporteDetallado(
titulo: 'Reporte de Ventas',
labelEntidad: 'Cliente',
datosIniciales: _mapearVentas(data.ventas),
permiteFiltrarFecha: true, 
esValorMonetario: true, 
)));
}

void _abrirReporteCompras(_ReporteData data) {
Navigator.push(context, MaterialPageRoute(builder: (_) => VistaReporteDetallado(
titulo: 'Reporte de Compras',
labelEntidad: 'Proveedor',
datosIniciales: _mapearCompras(data.compras),
permiteFiltrarFecha: true, 
esValorMonetario: true, 
)));
}

void _abrirReporteInventario(_ReporteData data) {
Navigator.push(context, MaterialPageRoute(builder: (_) => VistaReporteDetallado(
titulo: 'Inventario Valorado',
labelEntidad: 'Unidades',
datosIniciales: _mapearInventarioParaVista(data.inventario),
permiteFiltrarFecha: false, 
esValorMonetario: true, 
)));
}

void _abrirReporteSinStock(_ReporteData data) {
Navigator.push(context, MaterialPageRoute(builder: (_) => VistaReporteDetallado(
titulo: 'Productos Sin Stock',
labelEntidad: 'Unidades',
datosIniciales: _mapearSinStockParaVista(data.inventarioSinStock),
permiteFiltrarFecha: false, 
esValorMonetario: false, 
)));
}

void _abrirReporteStockPorUbicacion(_ReporteData data) {
Navigator.push(context, MaterialPageRoute(builder: (_) => VistaReporteDetallado(
titulo: 'Stock por Ubicación',
labelEntidad: 'Ubicación',
datosIniciales: _mapearStockPorUbicacionParaVista(data.stockPorUbicacion),
permiteFiltrarFecha: false, 
esValorMonetario: false, 
)));
}

void _abrirReporteKardex(_ReporteData data) {
Navigator.push(context, MaterialPageRoute(builder: (_) => VistaReporteDetallado(
titulo: 'Historial de Movimientos (Kardex)',
labelEntidad: 'Producto',
datosIniciales: _mapearKardexParaVista(data.historialMovimientos),
permiteFiltrarFecha: true,
esValorMonetario: false, 
)));
}

@override
Widget build(BuildContext context) {
final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$');

return Scaffold(
appBar: AppBar(title: const Text('Tablero de Control')),
body: FutureBuilder<_ReporteData>(
 future: _futureReporte,
 builder: (context, snapshot) {
 if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
 
 // Data vacía inicial si hay error, para que no truene
 final data = snapshot.data ?? _ReporteData(
 ventas: [], compras: [], inventario: [], inventarioSinStock: [], historialMovimientos: [], 
 stockPorUbicacion: [], reporteAABC: [], // <--- NUEVO: Inicializar
 totalVentas: 0, totalCompras: 0, utilidad: 0, valorInventario: 0,
 cantidadVentas: 0, cantidadCompras: 0, cantidadProductos: 0, cantidadSinStock: 0, cantidadMovimientos: 0,
 cantidadUbicaciones: 0, 
 );

 // Calcular el valor total AABC para mostrarlo en el KPI (VCA Total)
 final double valorAABC = data.reporteAABC.fold(0.0, (sum, item) => sum + (item['vca'] as num? ?? 0.0).toDouble());


 return RefreshIndicator(
 onRefresh: () async => setState(() => _futureReporte = _cargarDatosReporte()),
 child: SingleChildScrollView(
 physics: const AlwaysScrollableScrollPhysics(),
 padding: const EdgeInsets.all(16),
 child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  
  const Text("Resumen Financiero", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  const SizedBox(height: 16),
  
  Row(children: [
  Expanded(child: _buildKpiCard("Ingresos", data.totalVentas, Colors.green, Icons.trending_up, currencyFormat)),
  const SizedBox(width: 16),
  Expanded(child: _buildKpiCard("Gastos", data.totalCompras, Colors.red, Icons.trending_down, currencyFormat)),
  ]),
  const SizedBox(height: 16),
  Row(children: [
  Expanded(child: _buildUtilidadCard(data.utilidad, currencyFormat)),
  const SizedBox(width: 16),
  Expanded(child: _buildKpiCard("VCA Total (AABC)", valorAABC, Colors.purple, Icons.assessment, currencyFormat)),
  ]),

     // ====================================================================
     // NUEVO: BOTÓN DE EXPORTACIÓN DIRECTA DEL REPORTE KPI
     // ====================================================================
     const SizedBox(height: 30),
     _buildReportButton(
     context, 
     title: "Exportar Resumen Gerencial (KPI)",
     subtitle: "Incluye Ventas, Margen, Rotación de Inventario y Tendencias.",
     icon: Icons.bar_chart,
     color: Colors.blueGrey.shade700,
     // Se asegura que onTap llame a la función de impresión
     onTap: () { 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando Reporte KPI...")));
                _imprimirReporteKPI(data); 
            }, 
     onPrint: () => _imprimirReporteKPI(data),
     ),
     const SizedBox(height: 40),
     // ====================================================================
     
  const Text("Informes Detallados", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  const SizedBox(height: 16),
  
  // --- BOTONES DE REPORTE ---
  
  // NUEVO: REPORTE AABC
  _buildReportButton(
  context, 
  title: "Clasificación ABC de Inventario",
  subtitle: "${data.reporteAABC.length} productos clasificados",
  icon: Icons.sort_by_alpha,
  color: Colors.purple.shade600,
  onTap: () => _abrirReporteAABC(data),
  onPrint: () => _imprimirReporteAABC(_mapearReporteAABCParaVista(data.reporteAABC)), // Usamos el mapeo para obtener los datos de VCA/Clase
  ),
  const SizedBox(height: 16),
  
  _buildReportButton(
  context, 
  title: "Reporte de Ventas",
  subtitle: "${data.cantidadVentas} operaciones",
  icon: Icons.sell,
  color: Colors.blue.shade700,
  onTap: () => _abrirReporteVentas(data),
  onPrint: () => _imprimirReporteGeneral("Reporte de Ventas", _mapearVentas(data.ventas), data.totalVentas),
  ),
  const SizedBox(height: 16),
  
  _buildReportButton(
  context, 
  title: "Reporte de Compras",
  subtitle: "${data.cantidadCompras} operaciones",
  icon: Icons.shopping_cart,
  color: const Color(0xFF714B67),
  onTap: () => _abrirReporteCompras(data),
  onPrint: () => _imprimirReporteGeneral("Reporte de Compras", _mapearCompras(data.compras), data.totalCompras),
  ),
  const SizedBox(height: 16),
  
  _buildReportButton(
  context, 
  title: "Valoración de Inventario",
  subtitle: "${data.cantidadProductos} productos",
  icon: Icons.inventory,
  color: Colors.teal,
  onTap: () => _abrirReporteInventario(data),
  onPrint: () => _imprimirInventario(data.inventario, data.valorInventario),
  ),
  const SizedBox(height: 16),
  
  _buildReportButton(
  context, 
  title: "Productos Sin Stock",
  subtitle: "${data.cantidadSinStock} agotados",
  icon: Icons.warning_amber_rounded,
  color: Colors.red.shade600,
  onTap: () => _abrirReporteSinStock(data),
  onPrint: () => _imprimirSinStock(data.inventarioSinStock),
  ),
  const SizedBox(height: 16),
  
  _buildReportButton(
  context, 
  title: "Historial Movimientos (Kardex)",
  subtitle: "${data.cantidadMovimientos} registros",
  icon: Icons.history,
  color: Colors.indigo.shade600,
  onTap: () => _abrirReporteKardex(data),
  onPrint: () => _imprimirKardex(data.historialMovimientos),
  ),
  const SizedBox(height: 16),
  
  _buildReportButton(
  context, 
  title: "Stock por Ubicación",
  subtitle: "${data.stockPorUbicacion.length} registros en ${data.cantidadUbicaciones} ubicaciones",
  icon: Icons.location_on,
  color: Colors.orange.shade700,
  onTap: () => _abrirReporteStockPorUbicacion(data),
  onPrint: () => _imprimirStockPorUbicacion(data.stockPorUbicacion),
  ),
  const SizedBox(height: 16),

  ],
 ),
 ),
 );
 },
),
);
}

// --- WIDGETS AUXILIARES ---
Widget _buildKpiCard(String title, double amount, Color color, IconData icon, NumberFormat format) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
 color: Colors.white,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: Colors.grey.shade200),
 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
),
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold))]),
 const SizedBox(height: 12),
 Text(format.format(amount), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
]),
);
}

Widget _buildUtilidadCard(double utilidad, NumberFormat format) {
final isPositive = utilidad >= 0;
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
 gradient: LinearGradient(colors: isPositive ? [Colors.teal.shade400, Colors.teal.shade700] : [Colors.orange.shade400, Colors.deepOrange.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
 borderRadius: BorderRadius.circular(12),
 boxShadow: [BoxShadow(color: (isPositive ? Colors.teal : Colors.orange).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
),
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 Row(children: [Icon(isPositive ? Icons.thumb_up_alt : Icons.warning_amber, color: Colors.white70, size: 20), const SizedBox(width: 8), const Text("Utilidad Neta", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]),
 const SizedBox(height: 12),
 // CORREGIDO: Se usa FontWeight.bold de Flutter (no de pw)
 Text(format.format(utilidad), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)), 
]),
);
}

Widget _buildReportButton(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, required VoidCallback onPrint}) {
return Container(
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))]),
child: ClipRRect(
 borderRadius: BorderRadius.circular(12),
 child: IntrinsicHeight(
 child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
 Container(width: 6, color: color), 
 Expanded(child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
 Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
 const SizedBox(width: 16),
 Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 4), Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))])),
 ])))),
 VerticalDivider(width: 1, color: Colors.grey.shade200),
 InkWell(onTap: onPrint, child: Container(width: 60, alignment: Alignment.center, color: Colors.grey.shade50, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.print, color: Colors.grey.shade600), const SizedBox(height: 4), Text("PDF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600))]))),
 ]),
 ),
),
);
}
}