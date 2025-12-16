

import 'package:akasha/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

enum ClasificacionFiltro {
  todos,
  a,
  b,
  c,
}

class VistaReporteDetallado extends StatefulWidget {
 final String titulo;
 final String labelEntidad; // "Cliente", "Proveedor", "Ubicación", "Clase ABC", etc.
 final List<Map<String, dynamic>> datosIniciales;
 final bool permiteFiltrarFecha; 
 final Function(Map<String, dynamic>)? onVerDetalles; 
 
 // Para saber si mostramos $ o Cantidad simple
 final bool esValorMonetario; 

 const VistaReporteDetallado({
  super.key,
  required this.titulo,
  this.labelEntidad = "Entidad",
  required this.datosIniciales,
  this.permiteFiltrarFecha = false,
  this.onVerDetalles,
  this.esValorMonetario = true, // Por defecto es dinero (Ventas/Compras)
 });

 @override
 State<VistaReporteDetallado> createState() => _VistaReporteDetalladoState();
}

class _VistaReporteDetalladoState extends State<VistaReporteDetallado> {
 // Datos
 late List<Map<String, dynamic>> _datosFiltrados;
 
 // Controladores de Filtros
 final TextEditingController _searchController = TextEditingController();
 DateTimeRange? _rangoFechas;
 RangeValues? _rangoValores;
 
 // NUEVO: Filtro de tipo de movimiento (solo aplica a Kardex)
 TipoMovimientoFiltro _filtroTipoMovimiento = TipoMovimientoFiltro.todos;

  // NUEVO: Filtro de Clase ABC para el modal (sustituye a _clasesSeleccionadas en la lógica del modal)
  ClasificacionFiltro _filtroClasificacion = ClasificacionFiltro.todos;

 // Límites globales para el Slider
 double _minValorGlobal = 0.0;
 double _maxValorGlobal = 1000.0; 

 // Bandera para saber si estamos viendo el Kardex
 late final bool _esKardex;
 // Bandera para saber si es Stock por Ubicación
 late final bool _esStockUbicacion;
 // Bandera para saber si es Reporte AABC
 late final bool _esReporteAABC;
  
  // Getter simplificado para el reporte ABC (simplificado ya que el constructor no tiene claseFiltroKey)
 bool get _isABCReport => _esReporteAABC;


 @override
 void initState() {
  super.initState();
  _datosFiltrados = widget.datosIniciales;
  _calcularLimitesValores();
  
  final tituloLower = widget.titulo.toLowerCase();
  
  // Bandera Kardex
  _esKardex = !widget.esValorMonetario && widget.permiteFiltrarFecha && 
        (tituloLower.contains('kardex') || tituloLower.contains('movimiento'));
  
  // Bandera Stock por Ubicación
  _esStockUbicacion = !widget.esValorMonetario && !widget.permiteFiltrarFecha && 
            tituloLower.contains('stock por ubicación');
  
  // Bandera Reporte AABC
  _esReporteAABC = widget.esValorMonetario && !widget.permiteFiltrarFecha &&
          (tituloLower.contains('clasificación abc') || tituloLower.contains('aabc'));
    
    _aplicarFiltros();
 }

 @override
 void dispose() {
  _searchController.dispose();
  super.dispose();
 }

 void _calcularLimitesValores() {
  if (widget.datosIniciales.isEmpty) return;

  double min = double.infinity;
  double max = double.negativeInfinity; // Corregido a NegativeInfinity para manejar negativos

  for (var item in widget.datosIniciales) {
   // Seguridad de Nulidad
   final val = (item['total'] as num? ?? 0.0).toDouble(); 
   if (val < min) min = val;
   if (val > max) max = val;
  }

  // Si todo es 0 o si no se movió el rango
  if (min == double.infinity) min = 0.0;
  if (max == double.negativeInfinity || max <= min) max = min + 10;

  setState(() {
   _minValorGlobal = min;
   _maxValorGlobal = max; 
   _rangoValores = RangeValues(_minValorGlobal, _maxValorGlobal);
  });
 }

 // --- LÓGICA DE FILTRADO ---
 void _aplicarFiltros() {
  final textoBusqueda = _searchController.text.toLowerCase();
  
  DateTime? inicio;
  DateTime? fin;
  if (_rangoFechas != null) {
   inicio = _rangoFechas!.start;
   fin = _rangoFechas!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
  }

  setState(() {
   _datosFiltrados = widget.datosIniciales.where((item) {
    
    // 1. TEXTO
    final ref = item['ref'].toString().toLowerCase();
    final entidad = item['entidad'].toString().toLowerCase();
    final nombreProducto = item['producto_nombre']?.toString().toLowerCase() ?? ''; 
    
    bool cumpleTexto = ref.contains(textoBusqueda) || entidad.contains(textoBusqueda) || nombreProducto.contains(textoBusqueda);

    // 2. FECHA
    bool cumpleFecha = true;
    if (widget.permiteFiltrarFecha && _rangoFechas != null) {
     if (item['timestamp'] != null && item['timestamp'] is DateTime) {
      final fecha = item['timestamp'] as DateTime;
      if (fecha.isBefore(inicio!) || fecha.isAfter(fin!)) {
       cumpleFecha = false;
      }
     } else {
      cumpleFecha = false; 
     }
    }

    // 3. VALOR (Precio o Cantidad) - Slider
    bool cumpleValor = true;
    if (_rangoValores != null) {
     // Seguridad de Nulidad
     final total = (item['total'] as num? ?? 0.0).toDouble();
     if (total < _rangoValores!.start || total > _rangoValores!.end) {
      cumpleValor = false;
     }
    }

    // 4. TIPO DE MOVIMIENTO (Solo si es Kardex)
    bool cumpleTipoMovimiento = true;
    if (_esKardex) {
     // Seguridad de Nulidad
     final valor = (item['total'] as num? ?? 0.0).toDouble(); 

     if (_filtroTipoMovimiento == TipoMovimientoFiltro.entrada) {
      cumpleTipoMovimiento = valor >= 0; 
     } else if (_filtroTipoMovimiento == TipoMovimientoFiltro.salida) {
      cumpleTipoMovimiento = valor < 0; 
     }
    }
        
        // 5. NUEVO: FILTRO DE CLASIFICACIÓN (Solo si es Reporte AABC)
        bool cumpleClasificacion = true;
        if (_isABCReport && _filtroClasificacion != ClasificacionFiltro.todos) {
            final String claseProducto = item['clase_abc']?.toString().toLowerCase() ?? ''; 
            final filtro = _filtroClasificacion.toString().split('.').last; // 'a', 'b', 'c'
            cumpleClasificacion = claseProducto == filtro;
        }


        return cumpleTexto && cumpleFecha && cumpleValor && cumpleTipoMovimiento && cumpleClasificacion;
   }).toList();
  });
 }

 // --- CÁLCULO DE RESUMENES (KARDEX, STOCK, AABC) ---
 
 Map<String, double> get _resumenKardex {
  double entradas = 0.0;
  double salidas = 0.0;
  double saldoFinal = 0.0;

  for (var item in _datosFiltrados) {
   // Seguridad de Nulidad
   final cantidad = (item['total'] as num? ?? 0.0).toDouble();

   if (cantidad >= 0) {
    entradas += cantidad;
   } else {
    salidas += cantidad; 
   }
   saldoFinal += cantidad;
  }

  return {
   'entradas': entradas,
   'salidas': salidas.abs(), 
   'saldo_final': saldoFinal,
  };
 }

 // --- CÁLCULO DE RESUMEN STOCK POR UBICACIÓN ---
 Map<String, dynamic> get _resumenStockPorUbicacion {
   double stockTotal = 0.0;
   final Map<String, double> stockPorAlmacen = {};

   for (var item in _datosFiltrados) {
     final cantidad = (item['total'] as num? ?? 0.0).toDouble();
     final ubicacion = item['entidad'].toString();
     
     stockTotal += cantidad;
     
     stockPorAlmacen.update(ubicacion, (existingCount) => existingCount + cantidad, ifAbsent: () => cantidad);
   }

   return {
     'stock_total': stockTotal,
     'stock_por_almacen': stockPorAlmacen, 
     'ubicaciones_distintas': stockPorAlmacen.keys.length,
   };
 }
 
 // =========================================================================
 // NUEVO: CÁLCULO DE RESUMEN REPORTE AABC
 // =========================================================================
 Map<String, dynamic> get _resumenAABC {
   double vcaTotal = 0.0;
   final Map<String, int> conteoProductos = {'A': 0, 'B': 0, 'C': 0};
   final Map<String, double> vcaPorClase = {'A': 0.0, 'B': 0.0, 'C': 0.0};
   final totalProductos = _datosFiltrados.length;

   for (var item in _datosFiltrados) {
     // 'total' es el VCA, 'clase_abc' es A, B o C
     final vca = (item['total'] as num? ?? 0.0).toDouble();
     final clase = item['clase_abc']?.toString() ?? 'C'; 
     
     vcaTotal += vca;
     
     if (conteoProductos.containsKey(clase)) {
       conteoProductos[clase] = conteoProductos[clase]! + 1;
       vcaPorClase[clase] = vcaPorClase[clase]! + vca;
     }
   }

   return {
     'vca_total': vcaTotal,
     'conteo_productos': conteoProductos,
     'vca_por_clase': vcaPorClase,
     'total_productos': totalProductos,
   };
 }


 // --- MODAL DE FILTROS AVANZADOS (AÑADIDOS FILTROS ABC) ---
 void _mostrarFiltrosAvanzados() {
  DateTimeRange? tempFechas = _rangoFechas;
  RangeValues tempValores = _rangoValores ?? RangeValues(_minValorGlobal, _maxValorGlobal);
  TipoMovimientoFiltro tempFiltroMovimiento = _filtroTipoMovimiento;
    ClasificacionFiltro tempFiltroClasificacion = _filtroClasificacion; // Estado temporal para ABC

  showModalBottomSheet(
   context: context,
   isScrollControlled: true,
   shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
   ),
   builder: (context) {
    return StatefulBuilder(
     builder: (BuildContext context, StateSetter setModalState) {
      final formatoValor = widget.esValorMonetario
        ? NumberFormat.currency(locale: 'es_VE', symbol: '\$', decimalDigits: 0)
        : NumberFormat.decimalPattern('es_VE'); 
      
      return Padding(
       padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 40),
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
           const Text("Filtros Avanzados", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
           TextButton(
            onPressed: () {
             setModalState(() {
              tempFechas = null;
              tempValores = RangeValues(_minValorGlobal, _maxValorGlobal);
              tempFiltroMovimiento = TipoMovimientoFiltro.todos;
                            tempFiltroClasificacion = ClasificacionFiltro.todos; // <-- RESET CLASIFICACIÓN
             });
            },
            child: const Text("Restablecer", style: TextStyle(color: Colors.red)),
           )
          ],
         ),
         const Divider(),
         
         // FILTRO POR CLASIFICACIÓN ABC (Solo si es Reporte AABC)
                  if (_isABCReport) ...[
                      const Text("Clasificación de Producto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Wrap(
                          spacing: 10,
                          children: ClasificacionFiltro.values.map((ClasificacionFiltro filter) {
                              final label = filter.toString().split('.').last.toUpperCase();
                              final isSelected = tempFiltroClasificacion == filter;
                              
                              // Obtenemos el color de la clase A, B o C
                              final color = _getColorForClass(label);

                              return ChoiceChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                      setModalState(() {
                                          tempFiltroClasificacion = selected ? filter : ClasificacionFiltro.todos;
                                      });
                                  },
                                  selectedColor: color.withOpacity(0.2),
                                  labelStyle: TextStyle(color: isSelected && filter != ClasificacionFiltro.todos ? color : Colors.black87),
                              );
                          }).toList(),
                      ),
                      const SizedBox(height: 20),
                  ],

         // FILTRO POR TIPO DE MOVIMIENTO (Solo Kardex)
         if (_esKardex) ...[
          const Text("Tipo de Movimiento", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Wrap(
           spacing: 10,
           children: TipoMovimientoFiltro.values.map((TipoMovimientoFiltro filter) {
            return ChoiceChip(
             label: Text(_getTipoMovimientoLabel(filter)),
             selected: tempFiltroMovimiento == filter,
             onSelected: (bool selected) {
              setModalState(() {
               tempFiltroMovimiento = selected ? filter : TipoMovimientoFiltro.todos;
              });
             },
             selectedColor: Colors.indigo.shade100,
             backgroundColor: Colors.grey.shade100,
            );
           }).toList(),
          ),
          const SizedBox(height: 20),
         ],

         // SECCIÓN FECHAS (Solo si permite filtrar por fecha)
         if (widget.permiteFiltrarFecha) ...[
          const Text("Rango de Fechas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          InkWell(
           onTap: () async {
            final picked = await showDateRangePicker(
             context: context,
             firstDate: DateTime(2020),
             lastDate: DateTime.now().add(const Duration(days: 365)),
             initialDateRange: tempFechas,
            );
            if (picked != null) {
             setModalState(() => tempFechas = picked);
            }
           },
           child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
             border: Border.all(color: Colors.grey.shade300),
             borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
             children: [
              const Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
              const SizedBox(width: 10),
              Text(
               tempFechas == null 
                ? "Seleccionar fechas..." 
                : "${DateFormat('dd/MM/yy').format(tempFechas!.start)} - ${DateFormat('dd/MM/yy').format(tempFechas!.end)}",
               style: const TextStyle(fontSize: 16),
              ),
             ],
            ),
           ),
          ),
          const SizedBox(height: 20),
         ],

         // SECCIÓN VALORES (Precio o Cantidad)
         Text(
          widget.esValorMonetario ? "Rango de Importe (Total)" : "Rango de Cantidad", 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
         ),
         const SizedBox(height: 30),
         RangeSlider(
          values: tempValores,
          min: _minValorGlobal,
          max: _maxValorGlobal,
          // Ajustar divisiones para rangos grandes, asegurando que sean al menos 100
          divisions: (_maxValorGlobal - _minValorGlobal).toInt().clamp(100, 500), 
          activeColor: Colors.indigo,
          inactiveColor: Colors.indigo.shade100,
          labels: RangeLabels(
           formatoValor.format(tempValores.start),
           formatoValor.format(tempValores.end),
          ),
          onChanged: (RangeValues values) {
           setModalState(() {
            tempValores = values;
           });
          },
         ),
         Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
           Text(formatoValor.format(_minValorGlobal), style: const TextStyle(fontSize: 12, color: Colors.grey)),
           Text(formatoValor.format(_maxValorGlobal), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
         ),

         const SizedBox(height: 20),
         SizedBox(
          width: double.infinity,
          child: ElevatedButton(
           style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           ),
           onPressed: () {
            setState(() {
             _rangoFechas = tempFechas;
             _rangoValores = tempValores;
             _filtroTipoMovimiento = tempFiltroMovimiento; 
                            _filtroClasificacion = tempFiltroClasificacion; // APLICAR NUEVO FILTRO ABC
            });
            _aplicarFiltros();
            Navigator.pop(context);
           },
           child: const Text("Aplicar Filtros", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
         ),
        ],
       ),
      );
     },
    );
   },
  );
 }

 String _getTipoMovimientoLabel(TipoMovimientoFiltro filter) {
  switch (filter) {
   case TipoMovimientoFiltro.todos:
    return 'Todos';
   case TipoMovimientoFiltro.entrada:
    return 'Entrada';
   case TipoMovimientoFiltro.salida:
    return 'Salida';
  }
 }

 double get _totalActual {
  // Si es Kardex, el total actual es el Saldo Final
  if (_esKardex) return _resumenKardex['saldo_final']!;
  
  // Si es AABC, es el VCA Total
  if (_esReporteAABC) return _resumenAABC['vca_total'] as double;
  
  // Si es Stock por Ubicación o cualquier otro reporte
  return _datosFiltrados.fold(0.0, (sum, item) => sum + (item['total'] as num? ?? 0.0).toDouble());
 }

 // =========================================================================
 // LOGICA DE IMPRESIÓN 
 // =========================================================================
 Future<void> _imprimirReporteActual() async {
  String tituloPdf = widget.titulo;
  if (widget.permiteFiltrarFecha && _rangoFechas != null) {
   final f = DateFormat('dd/MM/yyyy');
   tituloPdf += "\n(${f.format(_rangoFechas!.start)} - ${f.format(_rangoFechas!.end)})";
  }

  final tituloLower = widget.titulo.toLowerCase();
  
  // 1. REPORTE AABC <--- NUEVA LÓGICA DE IMPRESIÓN
  if (_esReporteAABC) {
    final pdfBytes = await PdfService().generarReporteAABC(
     datos: _datosFiltrados,
     resumen: _resumenAABC, // Pasamos el resumen calculado
    );
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Reporte_AABC.pdf');
    return;
  }

  // 2. KARDEX / MOVIMIENTOS
  if (_esKardex) {
    final pdfBytes = await PdfService().generarReporteKardex(
     datos: _datosFiltrados,
     resumen: _resumenKardex, 
     filtroTipo: _filtroTipoMovimiento, 
    );
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Kardex_Filtrado.pdf');
    return;
  }

  // 3. STOCK POR UBICACIÓN 
  if (_esStockUbicacion) {
    final pdfBytes = await PdfService().generarReporteStockPorUbicacion(
     datos: _datosFiltrados,
    );
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Stock_Por_Ubicacion.pdf');
    return;
  }
  
  // 4. SIN STOCK
  if (tituloLower.contains('sin stock') || tituloLower.contains('agotado')) {
   final datosSinStock = _datosFiltrados.map((item) => {
    'nombre': item['fecha'] ?? item['entidad'], 
    'sku': item['ref'],
    'cantidad': item['total']
    }).toList();

    final pdfBytes = await PdfService().generarReporteSinStock(
     datos: datosSinStock,
     totalProductosAgotados: _datosFiltrados.length,
    );
    await Printing.sharePdf(bytes: pdfBytes, filename: 'Sin_Stock_Filtrado.pdf');
    return;
  }


  // 5. REPORTE GENERAL (Ventas, Compras, Valorado)
  final pdfBytes = await PdfService().generarReporteGeneral(
   titulo: tituloPdf,
   datos: _datosFiltrados,
   totalGeneral: _totalActual,
   esDinero: widget.esValorMonetario,
  );
  await Printing.sharePdf(bytes: pdfBytes, filename: '${widget.titulo.replaceAll(' ', '_')}.pdf');
 }

 @override
 Widget build(BuildContext context) {
  // Formateador condicional
  final numberFormat = widget.esValorMonetario
    ? NumberFormat.currency(locale: 'es_VE', symbol: '\$')
    : NumberFormat.decimalPattern('es_VE');

  bool filtrosActivos = _rangoFechas != null || 
    (_rangoValores != null && (_rangoValores!.start != _minValorGlobal || _rangoValores!.end != _maxValorGlobal)) ||
    (_esKardex && _filtroTipoMovimiento != TipoMovimientoFiltro.todos) || 
        (_isABCReport && _filtroClasificacion != ClasificacionFiltro.todos); // NUEVO: Filtro ABC activo

  return Scaffold(
   backgroundColor: Colors.grey.shade50,
   appBar: AppBar(
    title: Text(widget.titulo, style: const TextStyle(fontSize: 18)),
    actions: [
     IconButton(
      icon: const Icon(Icons.print),
      tooltip: "Imprimir reporte actual",
      onPressed: _imprimirReporteActual,
     ),
    ],
   ),
   body: Column(
    children: [
     // BARRA DE BÚSQUEDA Y BOTÓN DE FILTROS
     Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
       children: [
        Expanded(
         child: TextField(
          controller: _searchController,
          onChanged: (val) => _aplicarFiltros(),
          decoration: InputDecoration(
           // Adaptar hint text para AABC (buscar SKU o Nombre)
           hintText: _esReporteAABC ? "Buscar SKU o Nombre..." : 
               (_esStockUbicacion ? "Buscar ubicación, producto o SKU..." : "Buscar ref. o ${widget.labelEntidad.toLowerCase()}..."),
           prefixIcon: const Icon(Icons.search, color: Colors.grey),
           isDense: true,
           filled: true,
           fillColor: Colors.grey.shade100,
           border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
           ),
          ),
         ),
        ),
        const SizedBox(width: 10),
        InkWell(
         onTap: _mostrarFiltrosAvanzados,
         child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
           color: filtrosActivos ? Colors.indigo.shade50 : Colors.grey.shade100,
           borderRadius: BorderRadius.circular(8),
           border: Border.all(
             color: filtrosActivos ? Colors.indigo : Colors.transparent
           ),
          ),
          child: Icon(
           Icons.tune,
           color: filtrosActivos ? Colors.indigo : Colors.grey.shade700,
          ),
         ),
        ),
       ],
      ),
     ),
     
     const Divider(height: 1),

     // ENCABEZADOS DE LA TABLA
     Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
       children: [
        const Expanded(flex: 2, child: Text("Ref/Producto", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text(widget.labelEntidad, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
         flex: 2, 
         child: Text(
          // Para AABC, el total es VCA
          _esReporteAABC ? "VCA" : (widget.esValorMonetario ? "Total" : "Cant."), 
          textAlign: TextAlign.right, 
          style: const TextStyle(fontWeight: FontWeight.bold)
         )
        ),
        
        if (widget.onVerDetalles != null)
         const SizedBox(width: 40, child: Text("Det.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
       ],
      ),
     ),
     
     // LISTA DE DATOS
     Expanded(
      child: _datosFiltrados.isEmpty
        ? Center(
          child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
            Icon(Icons.filter_list_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            const Text("Sin resultados para estos filtros", style: TextStyle(color: Colors.grey)),
           ],
          ),
         )
        : ListView.separated(
          itemCount: _datosFiltrados.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (context, index) {
           final item = _datosFiltrados[index];
           // Seguridad de Nulidad
           final valor = (item['total'] as num? ?? 0.0).toDouble();
           final esNegativo = valor < 0;

           return Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
             children: [
              // COL 1: Ref y Fecha/Nombre Producto
              Expanded(
               flex: 2, 
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Text(item['ref'].toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                 // Nombre del producto (ya sea de Stock Ubicación o el 'fecha' genérico)
                 Text(item['fecha'].toString(), style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                ],
               ),
              ),
              // COL 2: Entidad (Cliente, Proveedor, Ubicación, CLASE ABC)
              Expanded(
               flex: 3, 
               child: Text(
                item['entidad'].toString(),
                style: TextStyle(
                 // Colorear la clase ABC
                 fontWeight: _esReporteAABC ? FontWeight.bold : FontWeight.normal,
                 color: _esReporteAABC 
                  ? (_getColorForClass(item['clase_abc']?.toString())) 
                  : Colors.black87,
                ),
               )
              ),
              // COL 3: Total o Cantidad
              Expanded(
               flex: 2, 
               child: Text(
                numberFormat.format(valor), 
                textAlign: TextAlign.right,
                style: TextStyle(
                 fontWeight: FontWeight.bold,
                 // Color condicional: Si es ABC, siempre es el color de la clase.
                 color: _esReporteAABC 
                  ? _getColorForClass(item['clase_abc']?.toString())
                  : (esNegativo 
                    ? Colors.red 
                    : (widget.esValorMonetario ? Colors.green : Colors.black87)
                   ),
                ),
               ),
              ),
              // COL 4: Botón
              if (widget.onVerDetalles != null)
               SizedBox(
                width: 40,
                child: IconButton(
                 icon: const Icon(Icons.visibility_outlined, color: Colors.indigo),
                 padding: EdgeInsets.zero,
                 constraints: const BoxConstraints(),
                 onPressed: () => widget.onVerDetalles!(item),
                ),
               ),
             ],
            ),
           );
          },
         ),
     ),

     // PIE DE PÁGINA (TOTAL O RESUMEN)
     Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
       color: Colors.white,
       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)],
      ),
      child: _esReporteAABC
        ? _buildAABCSummary(numberFormat) // <--- NUEVO WIDGET DE RESUMEN AABC
        : (_esKardex 
          ? _buildKardexSummary(numberFormat) 
          : (_esStockUbicacion 
            ? _buildStockUbicacionSummary(numberFormat)
            : _buildGeneralSummary(numberFormat)
           )
         ), 
     ),
    ],
   ),
  );
 }
 
 // --- HELPERS PARA WIDGETS DE RESUMEN ---
 
 // Colores para la clasificación ABC
 Color _getColorForClass(String? clase) {
  switch (clase) {
   case 'A':
    return Colors.red.shade700;
   case 'B':
    return Colors.orange.shade700;
   case 'C':
    return Colors.green.shade700;
   default:
    return Colors.grey.shade700;
  }
 }


 // Total General para Ventas, Compras, Valorado, Sin Stock
 Widget _buildGeneralSummary(NumberFormat numberFormat) {
  // Para Sin Stock, mostramos el conteo de registros.
  final esReporteDeExistencias = widget.titulo.toLowerCase().contains('sin stock') || widget.titulo.toLowerCase().contains('agotado');
  
  return Row(
   mainAxisAlignment: MainAxisAlignment.spaceBetween,
   children: [
    Text(esReporteDeExistencias ? "TOTAL REGISTROS:" : "TOTAL:", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    Text(
     esReporteDeExistencias
       ? "${_datosFiltrados.length}"
       : numberFormat.format(_totalActual),
     style: TextStyle(
      fontSize: 20, 
      fontWeight: FontWeight.bold, 
      color: widget.esValorMonetario ? Colors.green : Colors.indigo
     ),
    ),
   ],
  );
 }

 // Resumen Entradas/Salidas para Kardex
 Widget _buildKardexSummary(NumberFormat numberFormat) {
  final resumen = _resumenKardex;
  final entradas = resumen['entradas']!;
  final salidas = resumen['salidas']!;
  final saldoFinal = resumen['saldo_final']!;
  
  // Usamos el formato decimal para cantidades (sin $)
  final formatCantidad = NumberFormat.decimalPattern('es_VE',);
  
  return Column(
   crossAxisAlignment: CrossAxisAlignment.end,
   children: [
    _buildSummaryRow('Entradas (+)', entradas, Colors.green, formatCantidad),
    _buildSummaryRow('Salidas (-)', salidas, Colors.red, formatCantidad),
    const Divider(),
    _buildSummaryRow('SALDO FINAL', saldoFinal, Colors.indigo, formatCantidad, isTotal: true),
    
    // Información extra sobre el filtro activo
    if (_filtroTipoMovimiento != TipoMovimientoFiltro.todos)
     Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
       'Mostrando solo: ${_getTipoMovimientoLabel(_filtroTipoMovimiento)} (${_datosFiltrados.length} reg.)',
       style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
      ),
     )
   ],
  );
 }

 // Resumen Stock por Ubicación
 Widget _buildStockUbicacionSummary(NumberFormat numberFormat) {
   final resumen = _resumenStockPorUbicacion;
   final stockTotal = resumen['stock_total'] as double;
   final stockPorAlmacen = resumen['stock_por_almacen'] as Map<String, double>;
   final numUbicaciones = resumen['ubicaciones_distintas'] as int;

   // Usamos el formato decimal para cantidades
   final formatCantidad = NumberFormat.decimalPattern('es_VE');

   // Ordenar los almacenes por nombre para una presentación limpia
   final sortedAlmacenes = stockPorAlmacen.keys.toList()..sort();

   return Column(
     crossAxisAlignment: CrossAxisAlignment.end,
     children: [
       const Text("Cantidades por Almacén:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
       const SizedBox(height: 8),

       // Detalle por almacén
       ...sortedAlmacenes.map((almacen) => 
         _buildSummaryRow(
           almacen, 
           stockPorAlmacen[almacen]!, 
           Colors.black87, // Color neutro para el detalle
           formatCantidad, 
           isTotal: false
         )
       ).toList(),

       const Divider(height: 20),
       
       _buildSummaryRow(
         'Ubicaciones Distintas:', 
         numUbicaciones, 
         Colors.indigo, 
         formatCantidad, 
         isTotal: false
       ),
       
       const Divider(),
       
       // Mostramos el Total de Unidades
       _buildSummaryRow(
         'STOCK TOTAL UNIDADES:', 
         stockTotal, 
         Colors.orange.shade700, 
         formatCantidad, 
         isTotal: true
       ),
     ],
   );
 }

 // WIDGET DE RESUMEN AABC
 Widget _buildAABCSummary(NumberFormat numberFormat) {
   final resumen = _resumenAABC;
   final vcaTotal = resumen['vca_total'] as double;
   final conteo = resumen['conteo_productos'] as Map<String, int>;
   final vcaPorClase = resumen['vca_por_clase'] as Map<String, double>;
   final totalProductos = resumen['total_productos'] as int;
   
   // La clave 'total' ya viene formateada como currency en el build principal.

   return Column(
     crossAxisAlignment: CrossAxisAlignment.end,
     children: [
       const Text("Distribución de Inventario (Clasificación Pareto):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
       const SizedBox(height: 8),

       // Detalle por Clase (A, B, C)
       ...['A', 'B', 'C'].map((clase) {
         final conteoClase = conteo[clase] ?? 0;
         final vcaClase = vcaPorClase[clase] ?? 0.0;
         final color = _getColorForClass(clase);
         
         final pctProductos = totalProductos > 0 ? (conteoClase / totalProductos) * 100 : 0.0;
         final pctVCA = vcaTotal > 0 ? (vcaClase / vcaTotal) * 100 : 0.0;

         return _buildSummaryAABCRow(
           'Clase $clase (Productos: ${pctProductos.toStringAsFixed(1)}%)', 
           vcaClase, 
           color, 
           numberFormat,
           pctVCA: pctVCA
         );
       }).toList(),
       
       const Divider(height: 20),
       
       // VCA Total General
       _buildSummaryRow(
         'VCA TOTAL ($totalProductos Productos):', 
         vcaTotal, 
         Colors.purple.shade700, 
         numberFormat, 
         isTotal: true
       ),
     ],
   );
 }
 
 // Helper específico para las filas del resumen AABC
 Widget _buildSummaryAABCRow(String label, double value, Color color, NumberFormat format, {required double pctVCA}) {
  return Padding(
   padding: const EdgeInsets.symmetric(vertical: 2.0),
   child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
     Text(
      label, 
      style: TextStyle(
       fontSize: 13, 
       color: color,
       fontWeight: FontWeight.w500
      )
     ),
     // Columna de valor con porcentaje
     Row(
      children: [
       Text(
        '${pctVCA.toStringAsFixed(1)}%', 
        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)
       ),
       const SizedBox(width: 8),
       Text(
        format.format(value),
        style: TextStyle(
         fontSize: 16, 
         fontWeight: FontWeight.bold,
         color: color,
        ),
       ),
      ],
     ),
    ],
   ),
  );
 }

 Widget _buildSummaryRow(String label, dynamic value, Color color, NumberFormat format, {bool isTotal = false}) {
  // Si es int, formateamos sin decimales (e.g., Registros/Ubicaciones)
  final valueToFormat = value is int ? value.toDouble() : value as double;

  return Padding(
   padding: const EdgeInsets.symmetric(vertical: 2.0),
   child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
     Text(
      label, 
      style: TextStyle(
       fontSize: isTotal ? 16 : 14, 
       fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
      )
     ),
     Text(
      format.format(valueToFormat),
      style: TextStyle(
       fontSize: isTotal ? 20 : 16, 
       fontWeight: FontWeight.bold,
       color: color,
      ),
     ),
    ],
   ),
  );
 }
}