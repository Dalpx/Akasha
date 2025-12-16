import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:akasha/models/compra.dart';
import 'package:akasha/models/detalle_compra.dart';
import 'package:akasha/models/venta.dart';
import 'package:akasha/models/detalle_venta.dart';

class FacturaReport extends StatelessWidget {
  final Compra? compra;
  final List<DetalleCompra>? detalles;

  final Venta? venta;
  final List<DetalleVenta>? detallesVenta;

  const FacturaReport({
    super.key,
    this.compra,
    this.detalles,
    this.venta,
    this.detallesVenta,
  }) : assert(
          (compra != null && detalles != null && venta == null && detallesVenta == null) ||
              (venta != null && detallesVenta != null && compra == null && detalles == null),
          'Debes pasar compra+detalles o venta+detallesVenta (solo uno).',
        );

  bool get _isCompra => compra != null;

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 2);

    final titulo = _isCompra ? compra!.nroComprobante : venta!.numeroComprobante;

    final pill = _isCompra
        ? _buildEstadoPill(compra!.estado)
        : _buildTipoPill('VENTA', Colors.blueGrey);

    final terceroLabel = _isCompra ? 'Proveedor:' : 'Cliente:';
    final terceroNombre = _isCompra
        ? (compra!.proveedor ?? 'Proveedor Desconocido')
        : (venta!.nombreCliente.isNotEmpty ? venta!.nombreCliente : 'Cliente Desconocido');

    final fechaValue = _isCompra ? _formatFecha(compra!.fechaHora) : _formatFecha(venta!.fecha);

    final responsableValue = _isCompra
        ? 'Usuario ${compra!.idUsuario}'
        : (venta!.registradoPor.isNotEmpty ? venta!.registradoPor : '—');

    final subtotal = _isCompra ? compra!.subtotal : venta!.subtotal;
    final impuesto = _isCompra ? compra!.impuesto : venta!.impuesto;
    final total = _isCompra ? compra!.total : venta!.total;

    return Container(
      width: 700,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF714B67),
                ),
              ),
              pill,
            ],
          ),
          const Divider(height: 30, thickness: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      terceroLabel,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      terceroNombre,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (!_isCompra && venta!.email.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        venta!.email,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField("Fecha", fechaValue),
                    const SizedBox(height: 8),
                    _buildField("Responsable", responsableValue),
                    if (!_isCompra && venta!.metodoPago.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildField("Método de pago", venta!.metodoPago),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
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
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('Ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Cant',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Precio',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Subtotal',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_isCompra)
                  ...detalles!.map((d) => _buildDetalleRowCompra(d, currencyFormat))
                else
                  ...detallesVenta!.map((d) => _buildDetalleRowVenta(d, currencyFormat)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    _buildTotalRow("Base Imponible", subtotal, currencyFormat),
                    const SizedBox(height: 8),
                    _buildTotalRow("Impuestos (16%)", impuesto, currencyFormat),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currencyFormat.format(total),
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

  Widget _buildEstadoPill(int estado) {
    final isPublicado = estado == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPublicado ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPublicado ? Colors.green : Colors.grey),
      ),
      child: Text(
        isPublicado ? 'PUBLICADO' : 'BORRADOR',
        style: TextStyle(
          color: isPublicado ? Colors.green.shade800 : Colors.black54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTipoPill(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade400),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetalleRowCompra(DetalleCompra d, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(d.nombreProducto ?? 'Producto ${d.idProducto}')),
          Expanded(
            flex: 2,
            child: Text(
              d.nombreAlmacen ?? '-',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(flex: 1, child: Text('${d.cantidad}', textAlign: TextAlign.right)),
          Expanded(
            flex: 2,
            child: Text(currencyFormat.format(d.precioUnitario), textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(d.subtotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRowVenta(DetalleVenta d, NumberFormat currencyFormat) {
    final ubicacion = d.idUbicacion == null ? '-' : 'Ubicación ${d.idUbicacion}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(d.nombreProducto ?? 'Producto ${d.idProducto}')),
          Expanded(
            flex: 2,
            child: Text(
              ubicacion,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(flex: 1, child: Text('${d.cantidad}', textAlign: TextAlign.right)),
          Expanded(
            flex: 2,
            child: Text(currencyFormat.format(d.precioUnitario), textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 2,
            child: Text(
              currencyFormat.format(d.subtotal),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(dynamic raw) {
    if (raw == null) return '-';
    try {
      if (raw is DateTime) {
        return DateFormat('dd/MM/yyyy HH:mm').format(raw);
      }
      if (raw is String) {
        final s = raw.trim();
        if (s.isEmpty) return '-';
        final dt = DateTime.tryParse(s);
        if (dt != null) return DateFormat('dd/MM/yyyy HH:mm').format(dt);
        return s;
      }
      return raw.toString();
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildField(String label, String value) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 13))),
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
