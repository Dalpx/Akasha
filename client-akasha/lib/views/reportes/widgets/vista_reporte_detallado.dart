import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart'; // Para la acción de imprimir/compartir
import 'package:akasha/services/pdf_service.dart'; // Tu servicio de PDF

class VistaReporteDetallado extends StatelessWidget {
  final String titulo;
  final List<Map<String, dynamic>> datos;
  final double totalGeneral;

  const VistaReporteDetallado({
    super.key,
    required this.titulo,
    required this.datos,
    required this.totalGeneral,
  });

  // Función interna para imprimir desde esta vista
  Future<void> _imprimir(BuildContext context) async {
    // 1. Generar bytes usando el servicio centralizado
    final pdfBytes = await PdfService().generarReporteGeneral(
      titulo: titulo,
      datos: datos,
      totalGeneral: totalGeneral,
    );
    
    // 2. Abrir diálogo de guardar/compartir (Funciona mejor en Windows)
    await Printing.sharePdf(
      bytes: pdfBytes, 
      filename: '${titulo.replaceAll(' ', '_')}.pdf'
    );
  }

  @override
  Widget build(BuildContext context) {
    // Formateador de moneda
    final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          // BOTÓN IMPRIMIR EN EL APPBAR
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Imprimir Reporte',
            onPressed: () => _imprimir(context),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // --- TABLA DE DATOS (Con doble scroll para evitar desbordes) ---
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('Ref.', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Entidad', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: datos.map((d) {
                    return DataRow(cells: [
                      DataCell(Text(d['ref']?.toString() ?? '-')),
                      DataCell(Text(d['fecha']?.toString() ?? '-')),
                      DataCell(
                        SizedBox(
                          width: 200, // Limitamos el ancho del nombre para que no rompa la tabla
                          child: Text(
                            d['entidad']?.toString() ?? '-',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(currencyFormat.format(d['total']))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Publicado', style: TextStyle(fontSize: 10, color: Colors.green)),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
          
          // --- FOOTER DE TOTALES (Estilo Odoo) ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), 
                  blurRadius: 4, 
                  offset: const Offset(0, -2)
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registros: ${datos.length}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    const Text(
                      'Total General: ', 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(totalGeneral),
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: Color(0xFF714B67) // Odoo Purple
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}