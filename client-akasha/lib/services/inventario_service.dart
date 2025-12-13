import 'dart:convert';
import 'dart:developer';

import 'package:akasha/models/stock_ubicacion.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/producto.dart';

class InventarioService {
  final String _productoUrl =
      "http://localhost/akasha/server-akasha/src/producto";

  final String _stockUbicacionUrl =
      "http://localhost/akasha/server-akasha/src/stock";

  // ====== Notificador global de cambios de inventario ======
  static final ValueNotifier<int> productosRevision = ValueNotifier<int>(0);

  static void notifyProductosChanged() {
    productosRevision.value++;
  }

  // ====== Productos ======

  Future<List<Producto>> obtenerProductos() async {
    final url = Uri.parse(_productoUrl);
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonProducto = jsonDecode(response.body);

        final List<Producto> productos = jsonProducto
            .map(
              (producto) =>
                  Producto.fromJson(producto as Map<String, dynamic>),
            )
            .where((producto) => producto.activo)
            .toList();

        return productos;
      } else {
        log("Fallo el codigo: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("El error fue en ObtenerProductos: $e");
      return [];
    }
  }

  Future<void> crearProducto(Producto producto) async {
    final url = Uri.parse(_productoUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson()),
      );

      if (response.statusCode == 201) {
        log("Producto creado con éxito. ID: ${response.body}");
        notifyProductosChanged();
      } else {
        log(
          "Fallo al crear producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar crear producto: $e");
    }
  }

  Future<void> actualizarProducto(Producto producto) async {
    final url = Uri.parse('$_productoUrl/${producto.idProducto}');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(producto.toJson()),
      );

      if (response.statusCode == 200) {
        log("Producto actualizado con éxito.");
        notifyProductosChanged();
      } else {
        log(
          "Fallo al actualizar producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar actualizar producto: $e");
    }
  }

  Future<void> eliminarProducto(int idProducto) async {
    final url = Uri.parse("$_productoUrl/$idProducto");
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'id_producto': idProducto}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        log("Producto con ID $idProducto eliminado con éxito.");
        notifyProductosChanged();
      } else {
        log(
          "Fallo al eliminar producto. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar eliminar producto: $e");
    }
  }

  Future<Producto?> buscarPorId(int idProducto) async {
    final url = Uri.parse("$_productoUrl/$idProducto");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonProducto = jsonDecode(response.body);
        return Producto.fromJson(jsonProducto);
      } else if (response.statusCode == 404) {
        log("Producto con ID $idProducto no encontrado.");
        return null;
      } else {
        log("Fallo al buscar producto por ID. Código: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      log("Error al intentar buscar producto por ID: $e");
      return null;
    }
  }

  // ====== Stock por ubicación ======

  Future<List<StockUbicacion>> obtenerStockPorUbicacionDeProducto(
    int idProducto,
  ) async {
    final url = Uri.parse("$_stockUbicacionUrl/$idProducto");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonStockUbicacion = jsonDecode(response.body);

        final List<StockUbicacion> resultado = jsonStockUbicacion
            .map(
              (stock) =>
                  StockUbicacion.fromJson(stock as Map<String, dynamic>),
            )
            .toList();

        return resultado;
      } else {
        log(
          "Fallo al obtener stock por ubicación. Código: ${response.statusCode}",
        );
        return [];
      }
    } catch (e) {
      log("Error al intentar obtener stock por ubicación: $e");
      return [];
    }
  }

  Future<int> obtenerStockTotalDeProducto(int idProducto) async {
    try {
      final List<StockUbicacion> stocks =
          await obtenerStockPorUbicacionDeProducto(idProducto);

      final int stockTotal = stocks.fold(
        0,
        (sum, item) => sum + item.cantidad,
      );

      return stockTotal;
    } catch (e) {
      log("Error al calcular el stock total: $e");
      return 0;
    }
  }

  Future<void> establecerStock(int idProducto, int idUbicacion) async {
    final url = Uri.parse(_stockUbicacionUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'id_producto': idProducto,
          'id_ubicacion': idUbicacion,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        log("Nueva instancia de ubicacion creada.");
        notifyProductosChanged();
      } else {
        log(
          "Fallo al establecer stock. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar establecer stock: $e");
    }
  }

  Future<void> eliminarInstanciaUbicacion(
    int idProducto,
    int idUbicacion,
  ) async {
    final url = Uri.parse(_stockUbicacionUrl);
    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'id_producto': idProducto,
          'id_ubicacion': idUbicacion,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        log("Instancia eliminada con éxito.");
        notifyProductosChanged();
      } else {
        log(
          "Fallo al eliminar instancia. Código: ${response.statusCode}. Respuesta: ${response.body}",
        );
      }
    } catch (e) {
      log("Error al intentar eliminar instancia: $e");
    }
  }

  // ====== REPORTE Y VALORACIÓN (NUEVO) ======

  /// Calcula el inventario valorado (Costo * Stock Total)
  /// Nota: Al no tener SQL directo, esto hace múltiples peticiones.
  /// Idealmente, crearías un endpoint '/reporte/inventario' en PHP para esto.
  Future<List<Map<String, dynamic>>> obtenerReporteSinStock() async {
    // Reutilizamos el reporte valorado ya que contiene el stock total calculado
    final reporteValorado = await obtenerReporteValorado();

    // Filtramos los productos que tienen 0 o menos en stock
    final productosSinStock = reporteValorado
        .where((item) => (item['cantidad'] as num) <= 0)
        .toList();

    return productosSinStock;
  }
  Future<List<Map<String, dynamic>>> obtenerReporteValorado() async {
    try {
      // 1. Obtenemos todos los productos activos
      final productos = await obtenerProductos();
      List<Map<String, dynamic>> reporte = [];

      // 2. Iteramos y buscamos su stock (Usamos Future.wait para hacerlo paralelo y mas rápido)
      await Future.wait(productos.map((p) async {
        if (p.idProducto != null) {
          final int stockTotal = await obtenerStockTotalDeProducto(p.idProducto!);
          
          // Calculamos valor
          final double valorTotal = p.precioCosto * stockTotal;

          reporte.add({
            'id': p.idProducto,
            'nombre': p.nombre,
            'sku': p.sku,
            'costo': p.precioCosto,
            'cantidad': stockTotal,
            'valor_total': valorTotal,
          });
        }
      }));

      // 3. Ordenamos por el que tenga más valor acumulado (Descendente)
      reporte.sort((a, b) => (b['valor_total'] as double).compareTo(a['valor_total'] as double));

      return reporte;
    } catch (e) {
      log("Error generando reporte valorado: $e");
      return [];
    }
  }
}