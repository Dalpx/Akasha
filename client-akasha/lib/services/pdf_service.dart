import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:akasha/models/compra.dart';
import 'package:akasha/models/detalle_compra.dart';

// Definición de TipoMovimientoFiltro (dejado aquí por si no está en un archivo global)
enum TipoMovimientoFiltro {
todos,
entrada,
salida,
}

class PdfService {

// ===========================================================================
// 1. REPORTE INDIVIDUAL (Factura de Compra)
// ===========================================================================
Future<Uint8List> generarFacturaCompra(Compra compra, List<DetalleCompra> detalles) async {
 final pdf = pw.Document();

 final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 2);
 final odooPurple = PdfColor.fromInt(0xFF714B67);
 final lightGrey = PdfColor.fromInt(0xFFEEEEEE);

 pdf.addPage(
 pw.Page(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(32),
  build: (pw.Context context) {
  return pw.Column(
   crossAxisAlignment: pw.CrossAxisAlignment.start,
   children: [
   // HEADER
   pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
    pw.Text(
     compra.nroComprobante ?? 'Sin Ref',
     style: pw.TextStyle(
     fontSize: 24, fontWeight: pw.FontWeight.bold, color: odooPurple
     ),
    ),
    pw.Container(
     padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
     decoration: pw.BoxDecoration(
     border: pw.Border.all(color: PdfColors.grey),
     borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
     color: lightGrey,
     ),
     child: pw.Text(
     'COMPRA',
     style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.black),
     ),
    ),
    ],
   ),
   pw.Divider(height: 20),

   // INFO GENERAL
   pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
    pw.Expanded(
     child: pw.Column(
     crossAxisAlignment: pw.CrossAxisAlignment.start,
     children: [
      _buildPdfField("Proveedor:", compra.proveedor ?? 'Desconocido'),
     ],
     ),
    ),
    pw.Expanded(
     child: pw.Column(
     crossAxisAlignment: pw.CrossAxisAlignment.start,
     children: [
      _buildPdfField("Fecha:", compra.fechaHora.toString()),
      _buildPdfField("ID Compra:", "${compra.idCompra}"),
     ],
     ),
    ),
    ],
   ),
   pw.SizedBox(height: 20),

   // TABLA DE LÍNEAS
   pw.Text("Líneas de Factura", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
   pw.SizedBox(height: 10),

   pw.Table.fromTextArray(
    headers: ['Producto', 'Cant', 'Costo', 'Subtotal'],
    data: detalles.map((d) => [
    d.nombreProducto ?? 'Prod ${d.idProducto}',
    d.cantidad.toString(),
    currencyFormat.format(d.precioUnitario),
    currencyFormat.format(d.subtotal),
    ]).toList(),
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    headerDecoration: pw.BoxDecoration(color: odooPurple),
    rowDecoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: lightGrey, width: 0.5)),
    ),
    cellAlignments: {
    0: pw.Alignment.centerLeft,
    1: pw.Alignment.centerRight,
    2: pw.Alignment.centerRight,
    3: pw.Alignment.centerRight,
    },
    cellPadding: const pw.EdgeInsets.all(5),
   ),
   pw.SizedBox(height: 20),

   // TOTALES
   pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: [
    pw.Container(
     width: 200,
     child: pw.Column(
     children: [
      pw.Divider(),
      pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
       pw.Text("Total", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
       pw.Text(currencyFormat.format(compra.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      ],
      ),
     ],
     ),
    ),
    ],
   ),
   ],
  );
  },
 ),
 );

 return pdf.save();
}


// ===========================================================================
// 2. REPORTE GENERAL 
// ===========================================================================
Future<Uint8List> generarReporteGeneral({
 required String titulo,
 required List<Map<String, dynamic>> datos,
 required double totalGeneral,
 bool esDinero = true, // <--- NUEVO PARÁMETRO
}) async {
 final pdf = pw.Document();
 
 // Si es dinero usamos currency ($), si no, usamos decimal pattern (1.000,00)
 final format = esDinero 
  ? NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 2)
  : NumberFormat.decimalPattern('es_VE');

 final odooPurple = PdfColor.fromInt(0xFF714B67);

 pdf.addPage(
 pw.MultiPage(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(32),
  header: (context) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
   pw.Row(
   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
   children: [
    pw.Text(titulo.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: odooPurple)),
    pw.Text("Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
   ],
   ),
   pw.Divider(),
   pw.SizedBox(height: 10),
  ],
  ),
  build: (context) => [
  pw.Table.fromTextArray(
   headers: ['Ref.', 'Fecha', 'Entidad', esDinero ? 'Total' : 'Cant.'],
   data: datos.map((d) => [
   d['ref'].toString(),
   d['fecha'].toString(),
   d['entidad'].toString(),
   // SEGURIDAD: Usar as num? ?? 0.0
   format.format(d['total'] as num? ?? 0.0),
   ]).toList(),
   headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
   headerDecoration: pw.BoxDecoration(color: odooPurple),
   rowDecoration: const pw.BoxDecoration(
   border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
   ),
   cellPadding: const pw.EdgeInsets.all(6),
   cellAlignments: {
   0: pw.Alignment.centerLeft,
   1: pw.Alignment.centerLeft,
   2: pw.Alignment.centerLeft,
   3: pw.Alignment.centerRight,
   },
  ),
  pw.SizedBox(height: 20),
  pw.Row(
   mainAxisAlignment: pw.MainAxisAlignment.end,
   children: [
   pw.Text(esDinero ? "TOTAL GENERAL: " : "TOTAL: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
   pw.Text(format.format(totalGeneral), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
   ],
  ),
  ],
 ),
 );

 return pdf.save();
}


// ===========================================================================
// 3. REPORTE SIN STOCK
// ===========================================================================
Future<Uint8List> generarReporteSinStock({
 required List<Map<String, dynamic>> datos,
 required int totalProductosAgotados,
}) async {
 final pdf = pw.Document();
 final odooAlert = PdfColor.fromInt(0xFFEE5253); 

 pdf.addPage(
 pw.MultiPage(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(32),
  header: (context) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
   pw.Text("PRODUCTOS SIN STOCK (URGENTE)", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: odooAlert)),
   pw.Text("Fecha de Generación: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
   pw.Divider(),
   pw.SizedBox(height: 10),
  ],
  ),
  build: (context) => [
  pw.Table.fromTextArray(
   headers: ['Producto', 'SKU', 'Stock Actual'],
   columnWidths: {
   0: const pw.FlexColumnWidth(4),
   1: const pw.FlexColumnWidth(2),
   2: const pw.FlexColumnWidth(1.5),
   },
   data: datos.map((d) => [
   d['nombre'].toString(),
   d['sku'].toString(),
   // SEGURIDAD: Asumimos que cantidad ya viene mapeada correctamente
   d['cantidad'].toString(),
   ]).toList(),
   headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
   headerDecoration: pw.BoxDecoration(color: odooAlert),
   rowDecoration: const pw.BoxDecoration(
   border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
   ),
   cellPadding: const pw.EdgeInsets.all(5),
   cellStyle: const pw.TextStyle(fontSize: 9),
   cellAlignments: {
   0: pw.Alignment.centerLeft,
   1: pw.Alignment.centerLeft,
   2: pw.Alignment.centerRight,
   },
  ),
  pw.SizedBox(height: 20),
  pw.Row(
   mainAxisAlignment: pw.MainAxisAlignment.end,
   children: [
   pw.Text("TOTAL PRODUCTOS AGOTADOS: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: odooAlert)),
   pw.Text(totalProductosAgotados.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: odooAlert)),
   ],
  ),
  ],
 ),
 );

 return pdf.save();
}


// ===========================================================================
// 4. REPORTE DE STOCK POR UBICACIÓN 
// ===========================================================================
Future<Uint8List> generarReporteStockPorUbicacion({
 required List<Map<String, dynamic>> datos,
}) async {
 final pdf = pw.Document();
 final odooOrange = PdfColor.fromInt(0xFFF08544); 
 
 // Formato numérico simple para cantidades (sin $)
 final numberFormat = NumberFormat.decimalPattern('es_VE');
 
 // --- CÁLCULO DE RESUMEN ---
 double stockTotal = 0.0;
 final Map<String, double> stockPorAlmacen = {}; 

 for (var d in datos) {
  // SEGURIDAD: Usar as num? ?? 0.0
  final cantidad = (d['total'] as num? ?? 0.0).toDouble();
  final ubicacion = d['entidad'].toString();

  stockTotal += cantidad;
  
  // Sumar stock por almacén
  stockPorAlmacen.update(ubicacion, (existingCount) => existingCount + cantidad, ifAbsent: () => cantidad);
 }
 
 final numUbicaciones = stockPorAlmacen.keys.length;
 // Ordenar los almacenes alfabéticamente para el resumen
 final sortedAlmacenes = stockPorAlmacen.keys.toList()..sort();
 // --------------------------

 pdf.addPage(
 pw.MultiPage(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(32),
  header: (context) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
   pw.Text("REPORTE DE STOCK POR UBICACIÓN", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: odooOrange)),
   pw.Text("Fecha de Generación: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
   pw.Divider(),
   pw.SizedBox(height: 10),
  ],
  ),
  build: (context) => [
  pw.Table.fromTextArray(
   headers: ['Ubicación', 'Ref.', 'Producto', 'Cant.'], // 'Ref.' es el SKU
   columnWidths: {
   0: const pw.FlexColumnWidth(2), // Ubicación (entidad)
   1: const pw.FlexColumnWidth(1.5), // Ref. (ref)
   2: const pw.FlexColumnWidth(3.5), // Nombre Producto (fecha)
   3: const pw.FlexColumnWidth(1), // Cant. (total)
   },
   data: datos.map((d) => [
   d['entidad'].toString(), 
   d['ref'].toString(),  
   d['fecha'].toString(), 
   numberFormat.format(d['total'] as num? ?? 0.0),
   ]).toList(),
   headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
   headerDecoration: pw.BoxDecoration(color: odooOrange),
   rowDecoration: const pw.BoxDecoration(
   border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
   ),
   cellPadding: const pw.EdgeInsets.all(5),
   cellStyle: const pw.TextStyle(fontSize: 9),
   cellAlignments: {
   0: pw.Alignment.centerLeft,
   1: pw.Alignment.centerLeft,
   2: pw.Alignment.centerLeft,
   3: pw.Alignment.centerRight,
   },
  ),
  pw.SizedBox(height: 20),
  
  // --- FOOTER CON STOCK TOTAL ---
  pw.Row(
   mainAxisAlignment: pw.MainAxisAlignment.end,
   children: [
   pw.Container(
    width: 250, // Ampliamos un poco el contenedor para las etiquetas de almacén
    child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
     pw.Text("Cantidades por Almacén:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
     pw.SizedBox(height: 5),

     // Detalle por almacén
     ...sortedAlmacenes.map((almacen) =>
     _buildPdfSummaryRow(
      "$almacen:", 
      numberFormat.format(stockPorAlmacen[almacen]), 
      PdfColors.black,
     )
     ).toList(),

     pw.Divider(height: 10, thickness: 1, color: PdfColors.grey),
     
     _buildPdfSummaryRow("Ubicaciones Distintas:", numUbicaciones.toString(), PdfColors.black),
     
     pw.Divider(height: 10, thickness: 1.5, color: odooOrange),
     
     // Total General
     _buildPdfSummaryRow(
     "STOCK TOTAL UNIDADES:", 
     numberFormat.format(stockTotal), 
     odooOrange,
     isBold: true
     ),
    ],
    ),
   ),
   ],
  ),
  // -----------------------------------
  ],
 ),
 );

 return pdf.save();
}


// ===========================================================================
// 5. REPORTE KARDEX (HISTORIAL DE MOVIMIENTOS)
// ===========================================================================
Future<Uint8List> generarReporteKardex({
 required List<Map<String, dynamic>> datos,
 // Nuevos parámetros para el resumen y el filtro
 required Map<String, double> resumen,
 required TipoMovimientoFiltro filtroTipo,
}) async {
 final pdf = pw.Document();
 final odooIndigo = PdfColor.fromInt(0xFF3F51B5); 
 
 // Formato numérico simple para cantidades (sin $)
 final numberFormat = NumberFormat.decimalPattern('es_VE');

 final bool mostrarEntrada = filtroTipo != TipoMovimientoFiltro.salida;
 final bool mostrarSalida = filtroTipo != TipoMovimientoFiltro.entrada;
 
 final List<String> headers = ['Fecha', 'Ref.', 'Producto', 'Ubicación', 'Tipo', 'Cant.'];

 final Map<int, pw.FlexColumnWidth> columnWidths = {
  0: const pw.FlexColumnWidth(2), 
  1: const pw.FlexColumnWidth(1.5), 
  2: const pw.FlexColumnWidth(3), 
  3: const pw.FlexColumnWidth(2), 
  4: const pw.FlexColumnWidth(1.5), // Tipo
  5: const pw.FlexColumnWidth(1), // Cant.
 };
 
 String tituloKardex = "HISTORIAL DE MOVIMIENTOS";
 if (filtroTipo != TipoMovimientoFiltro.todos) {
  tituloKardex = "KARDEX - Movimientos de ${filtroTipo == TipoMovimientoFiltro.entrada ? 'ENTRADA' : 'SALIDA'}";
 }


 pdf.addPage(
 pw.MultiPage(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(32),
  header: (context) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
   pw.Row(
   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
   children: [
    pw.Text(tituloKardex, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: odooIndigo)),
    pw.Text("Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
   ],
   ),
   pw.Divider(),
   pw.SizedBox(height: 10),
  ],
  ),
  build: (context) => [
  pw.Table.fromTextArray(
   headers: headers,
   columnWidths: columnWidths,
   data: datos.map((item) {
   // SEGURIDAD: Usar as num? ?? 0.0
   double cantidad = (item['cantidad'] as num? ?? 0.0).toDouble();
   String cantFormato = numberFormat.format(cantidad); 
   
   return [
    item['fecha'].toString(),
    item['ref'].toString(),
    item['entidad'].toString(), 
    item['ubicacion'] ?? '-',
    item['tipo_movimiento'] ?? '-',
    cantFormato,
   ];
   }).toList(),
   headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
   headerDecoration: pw.BoxDecoration(color: odooIndigo),
   rowDecoration: const pw.BoxDecoration(
   border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
   ),
   cellStyle: const pw.TextStyle(fontSize: 8),
   cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
   cellAlignments: {
   0: pw.Alignment.centerLeft,
   1: pw.Alignment.centerLeft,
   2: pw.Alignment.centerLeft,
   3: pw.Alignment.centerLeft,
   4: pw.Alignment.center,
   5: pw.Alignment.centerRight,
   },
  ),
  
  pw.SizedBox(height: 20),
  
  // --- RESUMEN DE ENTRADAS Y SALIDAS ---
  pw.Row(
   mainAxisAlignment: pw.MainAxisAlignment.end,
   children: [
   pw.Container(
    width: 200,
    child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
     if (mostrarEntrada)
     _buildKardexSummaryRow("Entradas (+):", resumen['entradas']!, numberFormat, PdfColors.green),
     
     if (mostrarSalida)
     _buildKardexSummaryRow("Salidas (-):", resumen['salidas']!, numberFormat, PdfColors.red),
     
     pw.Divider(height: 10, thickness: 1.5, color: odooIndigo),
     
     _buildKardexSummaryRow("SALDO FINAL:", resumen['saldo_final']!, numberFormat, odooIndigo, isTotal: true),
    ],
    ),
   ),
   ],
  ),
  ],
 ),
 );

 return pdf.save();
}

// ===========================================================================
// 6. REPORTE DE INVENTARIO VALORADO (Reinsertado)
// ===========================================================================
Future<Uint8List> generarReporteInventario({
 required List<Map<String, dynamic>> datos,
 required double valorTotalInventario,
}) async {
 final pdf = pw.Document();
 final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 2);
 final odooTeal = PdfColor.fromInt(0xFF008784); // Teal

 pdf.addPage(
 pw.MultiPage(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(32),
  header: (context) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
   pw.Row(
   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
   children: [
    pw.Text("VALORACIÓN DE INVENTARIO", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: odooTeal)),
    pw.Text("Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
   ],
   ),
   pw.Divider(),
   pw.SizedBox(height: 10),
  ],
  ),
  build: (context) => [
  pw.Table.fromTextArray(
   headers: ['Producto', 'SKU', 'Cant.', 'Costo Unit.', 'Valor Total'],
   columnWidths: {
   0: const pw.FlexColumnWidth(3),
   1: const pw.FlexColumnWidth(1.5),
   2: const pw.FlexColumnWidth(1),
   3: const pw.FlexColumnWidth(1.5),
   4: const pw.FlexColumnWidth(1.5),
   },
   data: datos.map((d) => [
   d['nombre'].toString(),
   d['sku'].toString(),
   d['cantidad'].toString(),
   // SEGURIDAD: Usar as num? ?? 0.0
   currencyFormat.format(d['costo'] as num? ?? 0.0),
   currencyFormat.format(d['valor_total'] as num? ?? 0.0),
   ]).toList(),
   headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
   headerDecoration: pw.BoxDecoration(color: odooTeal),
   rowDecoration: const pw.BoxDecoration(
   border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
   ),
   cellPadding: const pw.EdgeInsets.all(5),
   cellStyle: const pw.TextStyle(fontSize: 9),
   cellAlignments: {
   0: pw.Alignment.centerLeft,
   1: pw.Alignment.centerLeft,
   2: pw.Alignment.centerRight,
   3: pw.Alignment.centerRight,
   4: pw.Alignment.centerRight,
   },
  ),
  pw.SizedBox(height: 20),
  pw.Row(
   mainAxisAlignment: pw.MainAxisAlignment.end,
   children: [
   pw.Text("VALOR TOTAL ACTIVOS: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
   pw.Text(currencyFormat.format(valorTotalInventario), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: odooTeal)),
   ],
  ),
  ],
 ),
 );

 return pdf.save();
}


// ===========================================================================
// 7. NUEVO: REPORTE AABC (Clasificación Pareto)
// ===========================================================================
Future<Uint8List> generarReporteAABC({
 required List<Map<String, dynamic>> datos,
 required Map<String, dynamic> resumen,
}) async {
 final pdf = pw.Document();
 final odooPurple = PdfColor.fromInt(0xFF714B67); // Color para el reporte ABC
 final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 2);
 
 // Extracción de datos del resumen
 final vcaTotal = resumen['vca_total'] as double;
 final conteo = resumen['conteo_productos'] as Map<String, int>;
 final vcaPorClase = resumen['vca_por_clase'] as Map<String, double>;
 final totalProductos = resumen['total_productos'] as int;


 pdf.addPage(
 pw.MultiPage(
  pageFormat: PdfPageFormat.a4,
  margin: const pw.EdgeInsets.all(32),
  header: (context) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
   pw.Text("CLASIFICACIÓN ABC DE INVENTARIO (PARETO)", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: odooPurple)),
   pw.Text("Fecha de Clasificación: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
   pw.Divider(),
   pw.SizedBox(height: 10),
  ],
  ),
  build: (context) => [
  
  // --- TABLA DE DATOS DETALLADA ---
  pw.Table.fromTextArray(
   headers: ['SKU', 'Producto', 'Clase', 'Costo Unit.', 'Consumo Anual', 'VCA (Total)'],
   columnWidths: {
   0: const pw.FlexColumnWidth(1.5), // SKU
   1: const pw.FlexColumnWidth(3), // Producto (fecha)
   2: const pw.FlexColumnWidth(1), // Clase (entidad)
   3: const pw.FlexColumnWidth(1.5), // Costo Unitario
   4: const pw.FlexColumnWidth(1.5), // Consumo Anual
   5: const pw.FlexColumnWidth(1.5), // VCA
   },
   data: datos.map((d) {
    final clase = d['clase_abc']?.toString() ?? 'C';
    return [
    d['ref'].toString(),
    d['fecha'].toString(),
    clase,
    currencyFormat.format(d['costo_unitario'] as num? ?? 0.0),
    (d['consumo_anual'] as num? ?? 0.0).toStringAsFixed(0),
    currencyFormat.format(d['total'] as num? ?? 0.0), // 'total' es el VCA
    ];
   }).toList(),
   headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
   headerDecoration: pw.BoxDecoration(color: odooPurple),
   rowDecoration: const pw.BoxDecoration(
   border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
   ),
   cellPadding: const pw.EdgeInsets.all(5),
   cellStyle: const pw.TextStyle(fontSize: 8),
   cellAlignments: {
   0: pw.Alignment.centerLeft,
   1: pw.Alignment.centerLeft,
   2: pw.Alignment.center,
   3: pw.Alignment.centerRight,
   4: pw.Alignment.centerRight,
   5: pw.Alignment.centerRight,
   },
  ),
  
  pw.SizedBox(height: 20),
  
  // --- FOOTER CONSOLIDADO (Resumen de Clases + Total General) ---
  pw.Row(
   mainAxisAlignment: pw.MainAxisAlignment.end,
   children: [
   pw.Container(
    width: 350, // Más ancho para acomodar la información de porcentaje
    child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
     pw.Text("Resumen de Clasificación ABC", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: odooPurple)),
     pw.SizedBox(height: 5),

     // Fila de encabezado para el resumen
     _buildPdfAABCSummaryHeader(),
     
     // Detalle por Clase A, B, C
     ...['A', 'B', 'C'].map((clase) {
      final vcaClase = vcaPorClase[clase] ?? 0.0;
      final conteoClase = conteo[clase] ?? 0;
      final color = _getColorForClassPdf(clase);
      
      final pctProductos = totalProductos > 0 ? (conteoClase / totalProductos) * 100 : 0.0;
      final pctVCA = vcaTotal > 0 ? (vcaClase / vcaTotal) * 100 : 0.0;

      return _buildPdfAABCSummaryRow(
       'Clase $clase',
       '${pctProductos.toStringAsFixed(1)}%', 
       '${pctVCA.toStringAsFixed(1)}%',
       currencyFormat.format(vcaClase),
       color,
       isSummary: true // Usamos el helper para filas de resumen
      );
     }).toList(),

     pw.Divider(height: 10, thickness: 1.5, color: odooPurple),

     // Total General
     _buildPdfSummaryRow(
     "VCA TOTAL GENERAL:", 
     currencyFormat.format(vcaTotal), 
     odooPurple, 
     isBold: true
     ),
    ],
    ),
   ),
   ],
  ),
  ],
 ),
 );

 return pdf.save();
}


// ===========================================================================
// 8. NUEVO: REPORTE GERENCIAL KPI (Resumen Ejecutivo)
// ===========================================================================

 // Helper para determinar el color de la tendencia (flecha o valor)
 // KPI donde un valor ALTO es BUENO (Ventas, Margen, Rotación)
 PdfColor _getTrendColor(double trend, String kpiName) {
  if (kpiName.contains('Stock Crítico') || kpiName.contains('Sin Stock')) {
   // Stock Crítico/Sin Stock: Un valor ALTO es MALO (se usa tendencia NEGATIVA para mejora)
   if (trend < 0) return PdfColors.green;
   if (trend > 0) return PdfColors.red;
  } else {
   // General: Un valor ALTO es BUENO
   if (trend > 0) return PdfColors.green;
   if (trend < 0) return PdfColors.red;
  }
  return PdfColors.black;
 }

 // Helper para generar el texto de la tendencia con flecha y color
 pw.Text _buildTrendText(double trend, String unit, String kpiName) {
  final color = _getTrendColor(trend, kpiName);
  final isMargin = unit == '%';
  String trendText;

  if (trend == 0.0) {
   trendText = 'Estable (0.00%)';
  } else {
   // CORRECCIÓN CLAVE: Reemplazamos ▲ y ▼ por (+) y (-) para evitar problemas de fuentes
   final sign = trend > 0 ? '(+)' : '(-)'; 
   final absoluteValue = trend.abs();
   final formattedPct = (absoluteValue * 100).toStringAsFixed(2);

   if (isMargin) {
     // Margen: Tendencia en puntos porcentuales (pp)
     // Nota: Asumimos que la entrada 'trend' es la diferencia absoluta si es margen, 
     // por lo que no se multiplica por 100, sino que se formatea
     trendText = '${sign}${absoluteValue.toStringAsFixed(2)} pp'; 
   } else {
     // Monetario/Unidades: Tendencia en porcentaje (%)
     trendText = '${sign}${formattedPct}%';
   }
  }

  return pw.Text(
   trendText,
   style: pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 10,
    color: color,
   ),
  );
 }

 Future<Uint8List> generarReporteKPI(List<Map<String, dynamic>> kpiData) async {
  final pdf = pw.Document();
  final odooTeal = PdfColor.fromInt(0xFF008784); // Color gerencial
  final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 2);
  final percentFormat = NumberFormat.decimalPattern('es_VE'); // Usamos decimal pattern para %

  final headers = ['INDICADOR', 'VALOR ACTUAL', 'TENDENCIA (vs. Período Ant.)'];
  
  pdf.addPage(
   pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    header: (context) => pw.Column(
     crossAxisAlignment: pw.CrossAxisAlignment.start,
     children: [
      pw.Text(
       "REPORTE GERENCIAL RESUMEN (KPI)",
       style: pw.TextStyle(
         fontSize: 20, fontWeight: pw.FontWeight.bold, color: odooTeal),
      ),
      pw.Text("Fecha de Generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      pw.Divider(),
      pw.SizedBox(height: 10),
     ],
    ),
    build: (context) => [
     pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
      columnWidths: const {
       0: pw.FlexColumnWidth(3),
       1: pw.FlexColumnWidth(2),
       2: pw.FlexColumnWidth(2),
      },
      children: [
       // Encabezado de la tabla
       pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
        children: headers
          .map((header) => pw.Padding(
             padding: const pw.EdgeInsets.all(8),
             child: pw.Text(header,
               style: pw.TextStyle(
                 fontWeight: pw.FontWeight.bold,
                 color: PdfColors.white,
                 fontSize: 10)),
            ))
          .toList(),
       ),

       // Filas de datos (Usamos un generador para insertar el widget de tendencia)
       ...kpiData.asMap().entries.map((entry) {
        final index = entry.key;
        final kpi = entry.value;

        final kpiName = kpi['name'] as String;
        final trend = kpi['trend'] as double;
        final unit = kpi['unit'] as String;
        
        // Determinar el formateo correcto para el Valor Actual
        final formattedValue = (unit == 'USD')
          ? currencyFormat.format(kpi['value'])
          : (unit == '%')
            ? '${percentFormat.format(kpi['value'] / 100)}%' // No usamos percentFormat ya que se multiplica por 100 en el ReportesPage
            : kpi['value'].toStringAsFixed(2);
        
        return pw.TableRow(
         decoration: pw.BoxDecoration(
          color: index.isOdd ? PdfColors.grey100 : PdfColors.white,
         ),
         children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(kpiName, style: const pw.TextStyle(fontSize: 10))),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(formattedValue,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
          pw.Padding(
           padding: const pw.EdgeInsets.all(8),
           // Aquí se inserta el widget de tendencia
           child: _buildTrendText(trend, unit, kpiName), 
          ),
         ],
        );
       }).toList(),
      ],
     ),
    ],
   ),
  );

  return pdf.save();
 }


// --- HELPERS INTERNOS ---

// Colores para la clasificación ABC en PDF
PdfColor _getColorForClassPdf(String? clase) {
 switch (clase) {
 case 'A':
  return PdfColors.red700;
 case 'B':
  return PdfColors.orange700;
 case 'C':
  return PdfColors.green700;
 default:
  return PdfColors.grey700;
 }
}

// NUEVO HELPER para el encabezado del resumen
pw.Widget _buildPdfAABCSummaryHeader() {
 return pw.Padding(
 padding: const pw.EdgeInsets.symmetric(horizontal: 8.0),
 child: pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
  pw.Text('Clase', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
  pw.Text('% Prod.', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
  pw.Text('% VCA', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
  pw.Text('VCA Monetario', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
  ],
 ),
 );
}

// Helper para las filas de resumen del reporte AABC (Modificado para recibir 3 valores de porcentaje)
pw.Widget _buildPdfAABCSummaryRow(String label, String pctProd, String pctVCA, String value, PdfColor color, {bool isSummary = false}) {
 return pw.Padding(
  padding: const pw.EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
  child: pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
   // 1. Etiqueta (Clase A, B, C)
   pw.Text(
   label, 
   style: pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 10,
    color: color,
   )
   ),
   // 2. Porcentaje de Productos
   pw.Text(
   pctProd,
   style: const pw.TextStyle(
    fontSize: 10,
    color: PdfColors.black,
   ),
   ),
   // 3. Porcentaje de VCA
   pw.Text(
   pctVCA,
   style: const pw.TextStyle(
    fontSize: 10,
    color: PdfColors.black,
   ),
   ),
   // 4. Valor Monetario
   pw.Text(
   value,
   style: pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 11,
    color: color,
   ),
   ),
  ],
  ),
 );
}

pw.Widget _buildPdfField(String label, String value) {
 return pw.Row(
 children: [
  pw.Text("$label ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
  pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
 ],
 );
}

// Helper para las filas de resumen de Stock por Ubicación, Inventario Valorado y AABC (pie)
pw.Widget _buildPdfSummaryRow(String label, String value, PdfColor color, {bool isBold = false}) {
 // Note: Esta función ya es usada por el total general, por eso no la modificamos para el ABC summary
 return pw.Padding(
 padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
 child: pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
  pw.Text(
   label, 
   style: pw.TextStyle(
   fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
   fontSize: isBold ? 14 : 10, // Más grande para el total
   )
  ),
  pw.Text(
   value,
   style: pw.TextStyle(
   fontWeight: pw.FontWeight.bold,
   fontSize: isBold ? 14 : 11,
   color: color,
   ),
  ),
  ],
 ),
 );
}


// Helper específico para las filas de Kardex (reusa _buildPdfSummaryRow internamente)
pw.Widget _buildKardexSummaryRow(String label, double amount, NumberFormat format, PdfColor color, {bool isTotal = false}) {
 // Usamos el helper general adaptando los estilos y formateo
 return _buildPdfSummaryRow(
 label, 
 format.format(amount), 
 color, 
 isBold: isTotal
 );
}
}