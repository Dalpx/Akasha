import 'package:akasha/models/compra.dart';
import 'package:akasha/models/detalle_venta.dart';
import 'package:akasha/models/venta.dart';
import 'package:akasha/services/compra_service.dart';
import 'package:akasha/services/venta_service.dart';
import 'package:flutter/material.dart';


/// Modelo interno para agrupar los datos del reporte
class _ReporteData {
  final List<Venta> ventas;
  final List<Compra> compras;

  final double totalVentas;
  final double totalCompras;
  final double utilidad;

  final int cantidadVentas;
  final int cantidadCompras;

  final List<_ProductoReporte> productosMasVendidos;

  _ReporteData({
    required this.ventas,
    required this.compras,
    required this.totalVentas,
    required this.totalCompras,
    required this.utilidad,
    required this.cantidadVentas,
    required this.cantidadCompras,
    required this.productosMasVendidos,
  });
}

/// Modelo interno para representar estadísticas de producto
class _ProductoReporte {
  final int idProducto;
  final String nombreProducto;
  final int cantidadVendida;
  final double totalVendido;

  _ProductoReporte({
    required this.idProducto,
    required this.nombreProducto,
    required this.cantidadVendida,
    required this.totalVendido,
  });
}

/// Pantalla de reportes que utiliza los datos de la BBDD mediante los servicios.
class ReportesPage extends StatefulWidget {
  final VentaService ventaService;
  final CompraService compraService;

  const ReportesPage({
    super.key,
    required this.ventaService,
    required this.compraService,
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

  /// Carga ventas y compras desde la API y calcula los indicadores.
  Future<_ReporteData> _cargarDatosReporte() async {
    final List<Venta> ventas = await widget.ventaService.obtenerVentas();
    final List<Compra> compras = await widget.compraService.obtenerCompras();

    // Total de ventas
    double totalVentas = 0;
    for (final venta in ventas) {
      totalVentas += double.tryParse(venta.total.toString()) ?? 0.0;
    }

    // Total de compras
    double totalCompras = 0;
    for (final compra in compras) {
      totalCompras += double.tryParse(compra.total.toString()) ?? 0.0;
    }

    // Utilidad
    final double utilidad = totalVentas - totalCompras;

    // Cantidades
    final int cantidadVentas = ventas.length;
    final int cantidadCompras = compras.length;

    // Top productos vendidos
    final List<_ProductoReporte> productosMasVendidos =
        _calcularProductosMasVendidos(ventas);

    return _ReporteData(
      ventas: ventas,
      compras: compras,
      totalVentas: totalVentas,
      totalCompras: totalCompras,
      utilidad: utilidad,
      cantidadVentas: cantidadVentas,
      cantidadCompras: cantidadCompras,
      productosMasVendidos: productosMasVendidos,
    );
  }

  /// Recorre todas las ventas y genera un ranking de productos más vendidos.
  List<_ProductoReporte> _calcularProductosMasVendidos(List<Venta> ventas) {
    final Map<int, _ProductoReporte> acumulado = {};

    for (final venta in ventas) {
      // Ajusta el nombre del campo según tu modelo:
      final List<DetalleVenta> detalles =  [];

      for (final detalle in detalles) {
        final int idProducto = detalle.idProducto;
        final String nombre = detalle.nombreProducto;
        final int cantidad = detalle.cantidad;
        final double precioUnit =
            double.tryParse(detalle.precioUnitario.toString()) ?? 0.0;
        final double totalDetalle = precioUnit * cantidad;

        if (!acumulado.containsKey(idProducto)) {
          acumulado[idProducto] = _ProductoReporte(
            idProducto: idProducto,
            nombreProducto: nombre,
            cantidadVendida: cantidad,
            totalVendido: totalDetalle,
          );
        } else {
          final actual = acumulado[idProducto]!;
          acumulado[idProducto] = _ProductoReporte(
            idProducto: idProducto,
            nombreProducto: nombre,
            cantidadVendida: actual.cantidadVendida + cantidad,
            totalVendido: actual.totalVendido + totalDetalle,
          );
        }
      }
    }

    final lista = acumulado.values.toList();

    // Ordenamos por cantidad vendida descendente
    lista.sort(
      (a, b) => b.cantidadVendida.compareTo(a.cantidadVendida),
    );

    // Devolvemos solo los primeros 5
    return lista.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: FutureBuilder<_ReporteData>(
        future: _futureReporte,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar reportes:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No hay datos para mostrar.'),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _futureReporte = _cargarDatosReporte();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Resumen general
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildResumenCard(
                        title: 'Total Ventas',
                        value:
                            '\$${data.totalVentas.toStringAsFixed(2)}',
                        // color: Colors.green,
                      ),
                      _buildResumenCard(
                        title: 'Total Compras',
                        value:
                            '\$${data.totalCompras.toStringAsFixed(2)}',
                        // color: Colors.blue,
                      ),
                      // _buildResumenCard(
                      //   title: 'Utilidad',
                      //   value:
                      //       '\$${data.utilidad.toStringAsFixed(2)}',
                      //   // color: data.utilidad >= 0
                      //   //     ? Colors.teal
                      //   //     : Colors.red,
                      // ),
                      _buildResumenCard(
                        title: 'Nº Ventas',
                        value: data.cantidadVentas.toString(),
                        // color: Colors.blue,
                      ),
                      _buildResumenCard(
                        title: 'Nº Compras',
                        value: data.cantidadCompras.toString(),
                        // color: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // // Top productos vendidos
                  // Text(
                  //   'Top productos vendidos',
                  //   style: Theme.of(context).textTheme.titleMedium,
                  // ),
                  // const SizedBox(height: 8),
                  // if (data.productosMasVendidos.isEmpty)
                  //   const Text('No hay datos de productos vendidos.')
                  // else
                  //   Card(
                  //     child: ListView.separated(
                  //       shrinkWrap: true,
                  //       physics: const NeverScrollableScrollPhysics(),
                  //       itemCount: data.productosMasVendidos.length,
                  //       separatorBuilder: (_, __) =>
                  //           const Divider(height: 1),
                  //       itemBuilder: (context, index) {
                  //         final p = data.productosMasVendidos[index];
                  //         return ListTile(
                  //           leading: CircleAvatar(
                  //             child: Text('${index + 1}'),
                  //           ),
                  //           title: Text(p.nombreProducto),
                  //           subtitle: Text(
                  //             'Cantidad: ${p.cantidadVendida}\n'
                  //             'Total vendido: \$${p.totalVendido.toStringAsFixed(2)}',
                  //           ),
                  //         );
                  //       },
                  //     ),
                  //   ),

                  const SizedBox(height: 24),

                  // Últimas ventas
                  Text(
                    'Últimas ventas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.ventas.length > 5
                          ? 5
                          : data.ventas.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final v = data.ventas[index];
                        return ListTile(
                          title: Text(
                            'Comprobante: ${v.nroComprobante}',
                          ),
                          subtitle: Text(
                            'Cliente: ${v.nombreCliente ?? '-'}\n'
                            'Fecha: ${v.fecha}',
                          ),
                          trailing: Text(
                            '\$${double.tryParse(v.total.toString())?.toStringAsFixed(2) ?? v.total.toString()}',
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Últimas compras
                  Text(
                    'Últimas compras',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.compras.length > 5
                          ? 5
                          : data.compras.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = data.compras[index];
                        return ListTile(
                          title: Text(
                            'Comprobante: ${c.numeroComprobante}',
                          ),
                          subtitle: Text(
                            'Proveedor: ${c.nombreProveedor ?? '-'}\n'
                            'Fecha: ${c.fecha}',
                          ),
                          trailing: Text(
                            '\$${double.tryParse(c.total.toString())?.toStringAsFixed(2) ?? c.total.toString()}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumenCard({
    required String title,
    required String value,
  }) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
