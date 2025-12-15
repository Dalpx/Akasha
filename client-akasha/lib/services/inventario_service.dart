import 'dart:convert';
import 'dart:developer'; // Importante para la función log()
import 'dart:io'; 

import 'package:akasha/models/stock_ubicacion.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/producto.dart';

class InventarioService {
  // URLs Base (Ajustadas a tu entorno local)
  final String _productoUrl = "http://localhost/akasha/server-akasha/src/producto";
  final String _stockUbicacionUrl = "http://localhost/akasha/server-akasha/src/stock";
  // Nueva URL para el Kardex
  final String _movimientoUrl = "http://localhost/akasha/server-akasha/src/movimiento"; 

  // ====== Headers (Agregado para corregir el error) ======
  Map<String, String> get _headers => const {
        HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
        HttpHeaders.acceptHeader: 'application/json',
      };

  // ====== Notificador global de cambios de inventario ======
  static final ValueNotifier<int> productosRevision = ValueNotifier<int>(0);

  static void notifyProductosChanged() {
    productosRevision.value++;
  }

  // ====== Productos ======

  Future<List<Producto>> obtenerProductos() async {
    final url = Uri.parse(_productoUrl);
    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonProducto = jsonDecode(utf8.decode(response.bodyBytes));

        final List<Producto> productos = jsonProducto
            .map((producto) => Producto.fromJson(producto as Map<String, dynamic>))
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
        headers: _headers,
        body: jsonEncode(producto.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        log("Producto creado con éxito. ID: ${response.body}");
        notifyProductosChanged();
      } else {
        log("Fallo al crear producto. Código: ${response.statusCode}. Respuesta: ${response.body}");
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
        headers: _headers,
        body: jsonEncode(producto.toJson()),
      );

      if (response.statusCode == 200) {
        log("Producto actualizado con éxito.");
        notifyProductosChanged();
      } else {
        log("Fallo al actualizar producto. Código: ${response.statusCode}. Respuesta: ${response.body}");
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
        headers: _headers,
        body: jsonEncode(<String, dynamic>{'id_producto': idProducto}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        log("Producto con ID $idProducto eliminado con éxito.");
        notifyProductosChanged();
      } else {
        log("Fallo al eliminar producto. Código: ${response.statusCode}. Respuesta: ${response.body}");
      }
    } catch (e) {
      log("Error al intentar eliminar producto: $e");
    }
  }

  Future<Producto?> buscarPorId(int idProducto) async {
    final url = Uri.parse("$_productoUrl/$idProducto");
    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonProducto = jsonDecode(utf8.decode(response.bodyBytes));
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

  Future<List<StockUbicacion>> obtenerStockPorUbicacionDeProducto(int idProducto) async {
    final url = Uri.parse("$_stockUbicacionUrl/$idProducto");

    try {
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonStockUbicacion = jsonDecode(utf8.decode(response.bodyBytes));

        final List<StockUbicacion> resultado = jsonStockUbicacion
            .map((stock) => StockUbicacion.fromJson(stock as Map<String, dynamic>))
            .toList();

        return resultado;
      } else {
        print("Fallo al obtener stock por ubicación. Código: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error al intentar obtener stock por ubicación: $e");
      return [];
    }
  }

  Future<int> obtenerStockTotalDeProducto(int idProducto) async {
    try {
      final List<StockUbicacion> stocks = await obtenerStockPorUbicacionDeProducto(idProducto);

      final int stockTotal = stocks.fold(0, (sum, item) => sum + item.cantidad);

      return stockTotal;
    } catch (e) {
      print("Error al calcular el stock total: $e");
      return 0;
    }
  }

  Future<void> establecerStock(int idProducto, int idUbicacion) async {
    final url = Uri.parse(_stockUbicacionUrl);

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(<String, dynamic>{
          'id_producto': idProducto,
          'id_ubicacion': idUbicacion,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Nueva instancia de ubicacion creada.");
        notifyProductosChanged();
      } else {
        print("Fallo al establecer stock. Código: ${response.statusCode}. Respuesta: ${response.body}");
      }
    } catch (e) {
      print("Error al intentar establecer stock: $e");
    }
  }

  Future<void> eliminarInstanciaUbicacion(int idProducto, int idUbicacion) async {
    final url = Uri.parse(_stockUbicacionUrl);
    try {
      final response = await http.delete(
        url,
        headers: _headers,
        body: jsonEncode(<String, dynamic>{
          'id_producto': idProducto,
          'id_ubicacion': idUbicacion,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("Instancia eliminada con éxito.");
        notifyProductosChanged();
      } else {
        print("Fallo al eliminar instancia. Código: ${response.statusCode}. Respuesta: ${response.body}");
      }
    } catch (e) {
      print("Error al intentar eliminar instancia: $e");
    }
  }

  // ====== REPORTE Y VALORACIÓN ======

  /// Calcula el inventario valorado (Costo * Stock Total)
  Future<List<Map<String, dynamic>>> obtenerReporteValorado() async {
    try {
      // 1. Obtenemos todos los productos activos
      final productos = await obtenerProductos();
      List<Map<String, dynamic>> reporte = [];

      // 2. Iteramos y buscamos su stock
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
      print("Error generando reporte valorado: $e");
      return [];
    }
  }

  /// Reutiliza el reporte valorado para filtrar los que tienen stock <= 0
  Future<List<Map<String, dynamic>>> obtenerReporteSinStock() async {
    final reporteValorado = await obtenerReporteValorado();

    final productosSinStock = reporteValorado
        .where((item) => (item['cantidad'] as num) <= 0)
        .toList();

    return productosSinStock;
  }
  
  // =========================================================================
  // Obtiene el Reporte de Stock por Ubicación (Supervisor)
  // =========================================================================
  /// Obtiene un listado del stock total agrupado por producto y ubicación.
  Future<List<Map<String, dynamic>>> obtenerReporteStockPorUbicacion() async {
    // Usamos el endpoint que devuelve la lista con 'nombre', 'nombre_almacen', 'stock'
    final url = Uri.parse('$_stockUbicacionUrl/reporte_completo'); 
    
    try {
      final response = await http.get(url, headers: _headers); 
      
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
      print("Fallo al obtener reporte de stock por ubicación. Código: ${response.statusCode}");
      return [];
    } catch (e) {
      print("Error obteniendo reporte de stock por ubicación: $e");
      return [];
    }
  }

  /// Obtiene el Historial de Movimientos (Kardex)
  Future<List<Map<String, dynamic>>> obtenerHistorialMovimientos() async {
    final url = Uri.parse(_movimientoUrl); 
    
    try {
      final response = await http.get(url, headers: _headers); 
      
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
      return [];
    } catch (e) {
      print("Error obteniendo kardex: $e");
      return [];
    }
  }

  // =========================================================================
  // REPORTE AABC (Clasificación Pareto) - CON DEBUGGING DE VCA
  // =========================================================================

  /// Calcula el Valor de Consumo Anual (VCA) y clasifica los productos en A, B o C.
  Future<List<Map<String, dynamic>>> obtenerReporteAABC() async {
    try {
      // 1. Obtener datos de costos (Reporte Valorado) y movimientos (Kardex)
      final Future<List<Map<String, dynamic>>> valoradoFuture = obtenerReporteValorado();
      final Future<List<Map<String, dynamic>>> movimientosFuture = obtenerHistorialMovimientos();

      final results = await Future.wait([valoradoFuture, movimientosFuture]);
      final List<Map<String, dynamic>> inventarioValorado = results[0];
      final List<Map<String, dynamic>> historialMovimientos = results[1];

      // Mapeo SKU -> Producto (para acceder rápido al costo)
      final Map<String, Map<String, dynamic>> productosMapBySku = {
        for (var item in inventarioValorado) 
          item['sku'].toString(): item
      };
      
      // NUEVO MAPEO: Nombre -> SKU (Para el fallback de vinculación)
      final Map<String, String> skuByProductName = {
        for (var item in inventarioValorado)
          (item['nombre']?.toString() ?? ''): item['sku'].toString()
      };
      
      print('--- Mapeo de productos cargado (${productosMapBySku.length} SKUs) ---');


      // 2. Calcular Consumo Anual (solo salidas, es decir, valor absoluto de las cantidades de movimientos)
      final Map<String, double> consumoAnualPorSKU = {};
      
      // >>> INICIO DEBUGGING CONSUMO ANUAL (MODIFICADO PARA USAR NOMBRE) <<<
      print('--- INICIANDO DEBUGGING DE CONSUMO ANUAL (KARDEX) ---');

      for (var movimiento in historialMovimientos) {
        
        // 1. INTENTAR BUSCAR POR SKU O REFERENCIA DIRECTA DEL MOVIMIENTO
        String itemSku = movimiento['sku']?.toString() ?? movimiento['referencia']?.toString() ?? '';
        
        // 2. INTENTAR BUSCAR POR NOMBRE DEL PRODUCTO (Fallback de la vinculación)
        if (itemSku.isEmpty) {
            // Buscamos el nombre del producto en el movimiento (pueden ser claves como 'entidad', 'producto' o 'nombre_producto')
            final nombreMovimiento = movimiento['entidad']?.toString() ?? movimiento['producto']?.toString() ?? movimiento['nombre_producto']?.toString() ?? '';
            
            if (nombreMovimiento.isNotEmpty) {
                // Buscamos el SKU en el mapa por nombre
                itemSku = skuByProductName[nombreMovimiento] ?? '';
                if (itemSku.isNotEmpty) {
                    print('DEBUG: Vinculado por NOMBRE: $nombreMovimiento -> SKU: $itemSku');
                }
            }
        }
        
        // 3. INTENTAR BUSCAR POR ID DE PRODUCTO (si el SKU sigue vacío)
        if (itemSku.isEmpty && movimiento.containsKey('id_producto')) {
             final idProducto = movimiento['id_producto'];
             final productoConId = inventarioValorado.firstWhere(
                (p) => p['id'] == idProducto,
                orElse: () => <String, dynamic>{}
            );
            itemSku = productoConId['sku']?.toString() ?? '';
             if (itemSku.isNotEmpty) {
                print('DEBUG: Vinculado por ID: $idProducto -> SKU: $itemSku');
            }
        }
        
        // --- Verificación de Consumo y Aplicación ---
        final cantidadMovimiento = (movimiento['cantidad'] as num? ?? 0.0).toDouble();
        final cantidadConsumida = cantidadMovimiento.abs(); // Usamos absoluto para la suma de consumo

        print('Movimiento ID: ${movimiento['id_movimiento']} | SKU Determinado: $itemSku');
        print('Cantidad original: $cantidadMovimiento | Consumo: $cantidadConsumida | Tipo: ${movimiento['tipo_movimiento']}');
        
        if (itemSku.isNotEmpty) {
          // Si el SKU se encontró, actualizamos el consumo anual sumando el valor absoluto de la cantidad.
          consumoAnualPorSKU.update(itemSku, (value) => value + cantidadConsumida, ifAbsent: () => cantidadConsumida);
        } else {
            print('ADVERTENCIA: Movimiento ID ${movimiento['id_movimiento']} NO pudo ser vinculado a un SKU y fue ignorado.');
        }
      }
      print('--- FIN DEBUGGING DE CONSUMO ANUAL ---');
      // >>> FIN DEBUGGING CONSUMO ANUAL <<<


      // 3. Calcular VCA y generar la lista preliminar del reporte
      List<Map<String, dynamic>> reportePreliminar = [];
      double vcaTotalAcumulado = 0.0;
      
      for (var producto in inventarioValorado) {
        final sku = producto['sku'].toString();
        // Aseguramos que el costo sea double y manejamos null/cero 
        final costoUnitario = (producto['costo'] as double? ?? 0.0); 
        final consumoAnual = consumoAnualPorSKU[sku] ?? 0.0;

        // ** <<< INICIO DEBUGGING VCA >>> **
        print('--- Producto: ${producto['nombre']} (SKU: $sku) ---');
        print('Costo Unitario (Base para VCA): $costoUnitario');
        print('Consumo Anual (Demanda de Kardex): $consumoAnual');
        
        final vca = costoUnitario * consumoAnual; // Fórmula VCA
        
        print('VCA Calculado: $vca');
        print('----------------------------------------------------');
        // ** <<< FIN DEBUGGING VCA >>> **

        vcaTotalAcumulado += vca;

        reportePreliminar.add({
          'sku': sku,
          'nombre': producto['nombre'],
          'costo_unitario': costoUnitario,
          'consumo_anual': consumoAnual,
          'vca': vca,
          'clase_abc': 'C', // Inicializamos en C
        });
      }
      
      // 4. Clasificación ABC (A: 80%, B: 15%, C: 5%)
      reportePreliminar.sort((a, b) => (b['vca'] as double).compareTo(a['vca'] as double));
      
      double acumulado = 0.0;
      for (var item in reportePreliminar) {
        final double vca = item['vca'] as double;
        acumulado += vca;
        
        // Evitar división por cero si no hay VCA Total
        if (vcaTotalAcumulado > 0) {
            final porcentajeAcumulado = (acumulado / vcaTotalAcumulado) * 100;

            if (porcentajeAcumulado <= 80.0) { // Clase A (Primer 80% del valor total)
              item['clase_abc'] = 'A';
            } else if (porcentajeAcumulado <= 95.0) { // Clase B (80% al 95% del valor total)
              item['clase_abc'] = 'B';
            } else { // Clase C (Restante 5% del valor total)
              item['clase_abc'] = 'C';
            }
        } else {
             // Si el VCA Total es cero, todos quedan como Clase C (o la clase inicial)
             item['clase_abc'] = 'C'; 
        }
      }

      return reportePreliminar;

    } catch (e) {
      print("Error generando reporte AABC: $e");
      return [];
    }
  }

}