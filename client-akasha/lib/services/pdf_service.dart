import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:akasha/models/compra.dart';
import 'package:akasha/models/detalle_compra.dart';

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
                    compra.nroComprobante,
                    style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold, color: odooPurple
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                      color: compra.estado == 1 ? PdfColors.green100 : lightGrey,
                    ),
                    child: pw.Text(
                      compra.estado == 1 ? 'PUBLICADO' : 'BORRADOR',
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
                        pw.Text("Proveedor:", style: pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                        pw.Text(compra.proveedor, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfField("Fecha:", compra.fechaHora),
                        _buildPdfField("Responsable:", "Usuario ${compra.idUsuario}"),
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
                headers: ['Producto', 'Ubicación', 'Cant', 'Precio', 'Subtotal'],
                data: detalles.map((d) => [
                  d.nombreProducto ?? 'Prod ${d.idProducto}',
                  d.nombreAlmacen ?? '-',
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
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
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
                        _buildPdfTotalRow("Base Imponible", currencyFormat.format(compra.subtotal)),
                        pw.SizedBox(height: 5),
                        _buildPdfTotalRow("Impuestos", currencyFormat.format(compra.impuesto)),
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
  // 2. REPORTE GENERAL (Lista de Ventas o Compras)
  // ===========================================================================
  Future<Uint8List> generarReporteGeneral({
    required String titulo,
    required List<Map<String, dynamic>> datos,
    required double totalGeneral,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 2);
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
            headers: ['Ref.', 'Fecha', 'Entidad', 'Total'],
            data: datos.map((d) => [
              d['ref'].toString(),
              d['fecha'].toString(),
              d['entidad'].toString(),
              currencyFormat.format(d['total']),
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
              pw.Text("TOTAL GENERAL: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(currencyFormat.format(totalGeneral), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }


  Future<Uint8List> generarReporteSinStock({
    required List<Map<String, dynamic>> datos,
    required int totalProductosAgotados,
  }) async {
    final pdf = pw.Document();
    // Color Rojo o Naranja para indicar una lista de "alerta" o "pendientes"
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
            // Ancho de columnas
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
            },
            data: datos.map((d) => [
              d['nombre'].toString(),
              d['sku'].toString(),
              d['cantidad'].toString(), // La cantidad debería ser 0 o negativa
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
  // 3. REPORTE DE INVENTARIO VALORADO (NUEVO)
  // ===========================================================================
  Future<Uint8List> generarReporteInventario({
    required List<Map<String, dynamic>> datos,
    required double valorTotalInventario,
  }) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 2);
    final odooTeal = PdfColor.fromInt(0xFF008784); // Color "Teal" característico de Inventario en Odoo

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
            // Ancho de columnas relativo
            columnWidths: {
              0: const pw.FlexColumnWidth(3), // Nombre más ancho
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
            },
            data: datos.map((d) => [
              d['nombre'].toString(),
              d['sku'].toString(),
              d['cantidad'].toString(),
              currencyFormat.format(d['costo']),
              currencyFormat.format(d['valor_total']),
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

  // --- HELPERS INTERNOS ---

  pw.Widget _buildPdfField(String label, String value) {
    return pw.Row(
      children: [
        pw.Text("$label ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildPdfTotalRow(String label, String amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(amount),
      ],
    );
  }
}