import '../models/venta.dart';

/// Servicio que calcula reportes simples a partir de los datos.
/// Por ejemplo: total de ventas, total de compras, etc.
class ReportesService {
  /// Calcula el total de ventas a partir de la lista de ventas.
  double calcularTotalVentas(List<Venta> ventas) {
    double total = 0.0;

    for (int i = 0; i < ventas.length; i++) {
      total = total + ventas[i].total;
    }

    return total;
  }
}
