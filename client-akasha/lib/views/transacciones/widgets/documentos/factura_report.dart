import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import 'package:akasha/models/compra.dart';
import 'package:akasha/models/detalle_compra.dart';
class FacturaReport extends StatelessWidget {
  final Compra compra;
  final List<DetalleCompra> detalles;

  const FacturaReport({
    super.key,
    required this.compra,
    required this.detalles,
  });

  @override
  Widget build(BuildContext context) {
    // Si no tienes intl, puedes quitar estas líneas y usar .toStringAsFixed(2) abajo
    final currencyFormat = NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 2);
    // final dateFormat = DateFormat('dd/MM/yyyy HH:mm'); 

    return Container(
      // Simulamos el ancho de un reporte qweb
      width: 700, 
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Importante para que se ajuste al contenido
        children: [
          // --- HEADER: ESTADO Y TÍTULO ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                compra.nroComprobante,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF714B67), // Odoo Enterprise Purple
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: compra.estado == 1 ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: compra.estado == 1 ? Colors.green : Colors.grey,
                  ),
                ),
                child: Text(
                  compra.estado == 1 ? 'PUBLICADO' : 'BORRADOR',
                  style: TextStyle(
                    color: compra.estado == 1 ? Colors.green.shade800 : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 30, thickness: 1),

          // --- GRUPO DE DATOS (Form View) ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Proveedor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Proveedor:",
                      style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      compra.proveedor ?? 'Proveedor Desconocido',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Fechas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField("Fecha", compra.fechaHora),
                    const SizedBox(height: 8),
                    _buildField("Responsable", "Usuario ${compra.idUsuario}"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // --- LÍNEAS DE PEDIDO (Tree View) ---
          const Text(
            "Líneas de Factura",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Header Tabla
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: const Row(
                    children: [
                      Expanded(flex: 4, child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 1, child: Text('Cant', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Precio', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Filas
                ...detalles.map((d) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text(d.nombreProducto ?? 'Producto ${d.idProducto}')),
                        Expanded(flex: 2, child: Text(d.nombreAlmacen ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                        Expanded(flex: 1, child: Text('${d.cantidad}', textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text(currencyFormat.format(d.precioUnitario), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text(currencyFormat.format(d.subtotal), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w500))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- FOOTER TOTALES ---
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    _buildTotalRow("Base Imponible", compra.subtotal, currencyFormat),
                    const SizedBox(height: 8),
                    _buildTotalRow("Impuestos (16%)", compra.impuesto, currencyFormat),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormat.format(compra.total),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, NumberFormat format) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87)),
        Text(format.format(amount), style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}