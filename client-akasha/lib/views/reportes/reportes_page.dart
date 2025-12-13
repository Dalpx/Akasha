import 'package:akasha/models/compra.dart';
import 'package:akasha/models/venta.dart';
import 'package:akasha/services/compra_service.dart';
import 'package:akasha/services/venta_service.dart';
import 'package:akasha/services/inventario_service.dart';
import 'package:akasha/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'widgets/vista_reporte_detallado.dart';

// DTO interno para manejar la data del dashboard
class _ReporteData {
  final List<Venta> ventas;
  final List<Compra> compras;
  final List<Map<String, dynamic>> inventario;
  final List<Map<String, dynamic>> inventarioSinStock; // NUEVO

  final double totalVentas;
  final double totalCompras;
  final double utilidad;
  final double valorInventario;

  final int cantidadVentas;
  final int cantidadCompras;
  final int cantidadProductos;
  final int cantidadSinStock; // NUEVO

  _ReporteData({
    required this.ventas,
    required this.compras,
    required this.inventario,
    required this.inventarioSinStock,
    required this.totalVentas,
    required this.totalCompras,
    required this.utilidad,
    required this.valorInventario,
    required this.cantidadVentas,
    required this.cantidadCompras,
    required this.cantidadProductos,
    required this.cantidadSinStock,
  });
}

class ReportesPage extends StatefulWidget {
  final VentaService ventaService;
  final CompraService compraService;
  final InventarioService inventarioService;

  const ReportesPage({
    super.key,
    required this.ventaService,
    required this.compraService,
    required this.inventarioService,
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

  Future<_ReporteData> _cargarDatosReporte() async {
    // 1. Carga paralela de los 4 servicios
    final resultados = await Future.wait([
      widget.ventaService.obtenerVentas(),
      widget.compraService.obtenerCompras(),
      widget.inventarioService.obtenerReporteValorado(),
      widget.inventarioService.obtenerReporteSinStock(), // Nueva llamada
    ]);

    final ventas = resultados[0] as List<Venta>;
    final compras = resultados[1] as List<Compra>;
    final inventario = resultados[2] as List<Map<String, dynamic>>;
    final inventarioSinStock = resultados[3] as List<Map<String, dynamic>>;

    // 2. Cálculos Financieros
    double totalVentas = ventas.fold(0.0, (sum, v) => sum + (double.tryParse(v.total.toString()) ?? 0.0));
    double totalCompras = compras.fold(0.0, (sum, c) => sum + (double.tryParse(c.total.toString()) ?? 0.0));
    final double utilidad = totalVentas - totalCompras;

    // 3. Cálculo de Valoración de Inventario
    double valorInventario = inventario.fold(0.0, (sum, item) => sum + (item['valor_total'] as num).toDouble());

    return _ReporteData(
      ventas: ventas,
      compras: compras,
      inventario: inventario,
      inventarioSinStock: inventarioSinStock,
      totalVentas: totalVentas,
      totalCompras: totalCompras,
      utilidad: utilidad,
      valorInventario: valorInventario,
      cantidadVentas: ventas.length,
      cantidadCompras: compras.length,
      cantidadProductos: inventario.length,
      cantidadSinStock: inventarioSinStock.length,
    );
  }

  // --- MAPEO DE DATOS ---

  List<Map<String, dynamic>> _mapearVentas(List<Venta> ventas) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return ventas.map((v) {
      String fechaFormateada = '-';
      if (v.fecha is DateTime) {
        fechaFormateada = dateFormat.format(v.fecha as DateTime);
      } else {
        fechaFormateada = v.fecha.toString();
      }
      return {
        'ref': v.numeroComprobante,
        'fecha': fechaFormateada,
        'entidad': v.nombreCliente ?? 'Cliente General',
        'total': double.tryParse(v.total.toString()) ?? 0.0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _mapearCompras(List<Compra> compras) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return compras.map((c) {
      String fechaFormateada = '-';
      if (c.fechaHora is DateTime) {
        fechaFormateada = dateFormat.format(c.fechaHora as DateTime);
      } else {
        fechaFormateada = c.fechaHora.toString();
      }
      return {
        'ref': c.nroComprobante,
        'fecha': fechaFormateada,
        'entidad': c.proveedor,
        'total': c.total,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _mapearInventarioParaVista(List<Map<String, dynamic>> inventario) {
    return inventario.map((item) => {
      'ref': item['sku'],
      'fecha': item['nombre'],
      'entidad': "${item['cantidad']} unds.",
      'total': item['valor_total'],
    }).toList();
  }

  // NUEVO: Mapeo para productos sin stock
  List<Map<String, dynamic>> _mapearSinStockParaVista(List<Map<String, dynamic>> sinStock) {
    return sinStock.map((item) => {
      'ref': item['sku'],
      'fecha': item['nombre'],
      'entidad': "${item['cantidad']} unds.", // Aquí mostrará 0 o negativo
      'total': 0.0, // Irrelevante
    }).toList();
  }

  // --- ACCIONES (Imprimir y Navegar) ---

  Future<void> _imprimirReporteGeneral(String titulo, List<Map<String, dynamic>> datos, double total) async {
    final pdfBytes = await PdfService().generarReporteGeneral(
      titulo: titulo,
      datos: datos,
      totalGeneral: total,
    );
    await Printing.sharePdf(bytes: pdfBytes, filename: '${titulo.replaceAll(' ', '_')}.pdf');
  }

  Future<void> _imprimirInventario(List<Map<String, dynamic>> datos, double total) async {
    final pdfBytes = await PdfService().generarReporteInventario(
      datos: datos,
      valorTotalInventario: total,
    );
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Valoracion_Inventario.pdf');
  }

  // NUEVO: Imprimir Sin Stock
  Future<void> _imprimirSinStock(List<Map<String, dynamic>> datos) async {
    final pdfBytes = await PdfService().generarReporteSinStock(
      datos: datos,
      totalProductosAgotados: datos.length,
    );
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Productos_Sin_Stock.pdf');
  }

  void _abrirReporteVentas(_ReporteData data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VistaReporteDetallado(
          titulo: 'Reporte de Ventas',
          datos: _mapearVentas(data.ventas),
          totalGeneral: data.totalVentas,
        ),
      ),
    );
  }

  void _abrirReporteCompras(_ReporteData data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VistaReporteDetallado(
          titulo: 'Reporte de Compras',
          datos: _mapearCompras(data.compras),
          totalGeneral: data.totalCompras,
        ),
      ),
    );
  }

  void _abrirReporteInventario(_ReporteData data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VistaReporteDetallado(
          titulo: 'Inventario Valorado',
          datos: _mapearInventarioParaVista(data.inventario),
          totalGeneral: data.valorInventario,
        ),
      ),
    );
  }

  // NUEVO: Abrir Sin Stock
  void _abrirReporteSinStock(_ReporteData data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VistaReporteDetallado(
          titulo: 'Productos Sin Stock',
          datos: _mapearSinStockParaVista(data.inventarioSinStock),
          totalGeneral: data.cantidadSinStock.toDouble(), // Usamos conteo como total
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Tablero de Control')),
      body: FutureBuilder<_ReporteData>(
        future: _futureReporte,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Sin datos'));
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => setState(() => _futureReporte = _cargarDatosReporte()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // SECCIÓN 1: KPIs
                  const Text("Resumen Financiero", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(child: _buildKpiCard("Ingresos (Ventas)", data.totalVentas, Colors.green, Icons.trending_up, currencyFormat)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildKpiCard("Gastos (Compras)", data.totalCompras, Colors.red, Icons.trending_down, currencyFormat)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildUtilidadCard(data.utilidad, currencyFormat)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildKpiCard("Activos (Stock)", data.valorInventario, Colors.teal, Icons.inventory_2, currencyFormat)),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // SECCIÓN 2: ACCESOS A REPORTES
                  const Text("Informes Detallados", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  _buildReportButton(
                    context, 
                    title: "Reporte de Ventas",
                    subtitle: "${data.cantidadVentas} operaciones registradas",
                    icon: Icons.sell,
                    color: Colors.blue.shade700,
                    onTap: () => _abrirReporteVentas(data),
                    onPrint: () => _imprimirReporteGeneral("Reporte de Ventas", _mapearVentas(data.ventas), data.totalVentas),
                  ),
                  const SizedBox(height: 16),

                  _buildReportButton(
                    context, 
                    title: "Reporte de Compras",
                    subtitle: "${data.cantidadCompras} operaciones registradas",
                    icon: Icons.shopping_cart,
                    color: const Color(0xFF714B67),
                    onTap: () => _abrirReporteCompras(data),
                    onPrint: () => _imprimirReporteGeneral("Reporte de Compras", _mapearCompras(data.compras), data.totalCompras),
                  ),
                  const SizedBox(height: 16),

                  _buildReportButton(
                    context, 
                    title: "Valoración de Inventario",
                    subtitle: "${data.cantidadProductos} productos únicos en almacén",
                    icon: Icons.inventory,
                    color: Colors.teal,
                    onTap: () => _abrirReporteInventario(data),
                    onPrint: () => _imprimirInventario(data.inventario, data.valorInventario),
                  ),
                  const SizedBox(height: 16),

                  // NUEVO BOTÓN: PRODUCTOS SIN STOCK
                  _buildReportButton(
                    context, 
                    title: "Productos Sin Stock",
                    subtitle: "${data.cantidadSinStock} productos agotados o en negativo",
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red.shade600, // Color de alerta
                    onTap: () => _abrirReporteSinStock(data),
                    onPrint: () => _imprimirSinStock(data.inventarioSinStock),
                  ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            format.format(amount),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildUtilidadCard(double utilidad, NumberFormat format) {
    final isPositive = utilidad >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive 
            ? [Colors.teal.shade400, Colors.teal.shade700] 
            : [Colors.orange.shade400, Colors.deepOrange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: (isPositive ? Colors.teal : Colors.orange).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
            children: [
              Icon(isPositive ? Icons.thumb_up_alt : Icons.warning_amber, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text("Utilidad Neta", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            format.format(utilidad),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReportButton(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
    required VoidCallback onPrint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 5, 
            offset: const Offset(0, 2)
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color), 
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              VerticalDivider(width: 1, color: Colors.grey.shade200),
              InkWell(
                onTap: onPrint,
                child: Container(
                  width: 60,
                  alignment: Alignment.center,
                  color: Colors.grey.shade50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.print, color: Colors.grey.shade600),
                      const SizedBox(height: 4),
                      Text("PDF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}