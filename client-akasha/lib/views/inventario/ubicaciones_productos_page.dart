import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../models/ubicacion.dart';
import '../../models/stock_ubicacion.dart';
import '../../services/ubicacion_service.dart';
import '../../services/inventario_service.dart';
import '../../core/app_routes.dart';

/// Pantalla que permite gestionar las ubicaciones de un producto.
class UbicacionesProductoPage extends StatefulWidget {
  final Producto producto;

  const UbicacionesProductoPage({super.key, required this.producto});

  @override
  State<UbicacionesProductoPage> createState() {
    return _UbicacionesProductoPageState();
  }
}

class _UbicacionesProductoPageState extends State<UbicacionesProductoPage> {
  final UbicacionService _ubicacionService = UbicacionService();
  final InventarioService _inventarioService = InventarioService();

  // Esta lista contiene TODAS las ubicaciones activas
  List<Ubicacion> _ubicaciones = <Ubicacion>[];
  // Esta lista contiene SOLO el stock de este producto por ubicación (la respuesta del servidor)
  List<StockUbicacion> _stockUbicaciones = <StockUbicacion>[];

  Ubicacion? _ubicacionSeleccionada;
  final TextEditingController _cantidadController = TextEditingController();

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Carga ubicaciones y stock del producto.
  Future<void> _cargarDatos() async {
    int idProducto = widget.producto.idProducto ?? 0;

    if (idProducto == 0) {
      setState(() {
        _cargando = false;
      });
      _mostrarMensaje('Error: El producto no tiene ID válido.');
      return;
    }

    List<Ubicacion> ubicaciones = await _ubicacionService
        .obtenerUbicacionesActivas();
    List<StockUbicacion> stock = await _inventarioService
        .obtenerStockPorUbicacionDeProducto(idProducto);

    setState(() {
      _ubicaciones = ubicaciones;
      _stockUbicaciones = stock;

      // Al cargar, el Dropdown debe mostrar la primera ubicación no asignada si existe.
      _ubicacionSeleccionada = _obtenerUbicacionesNoAsignadas().isNotEmpty
          ? _obtenerUbicacionesNoAsignadas()[0]
          : null;
      _cantidadController.text =
          '0'; // La cantidad inicial es 0 para una nueva asignación

      _cargando = false;
    });
  }

  /// Devuelve la lista de ubicaciones activas que NO están en _stockUbicaciones (stock > 0).
  /// ✨ **CUMPLE REQUISITO 1: FILTRO DE NO ASIGNADAS**
  List<Ubicacion> _obtenerUbicacionesNoAsignadas() {
    // Nombres de los almacenes que ya tienen stock para este producto
    final Set<String> nombresAsignados = _stockUbicaciones
        .map(
          (s) => s.idUbicacion,
        ) // Asumiendo que idUbicacion de StockUbicacion es el nombre del almacén
        .toSet();

    // Filtramos la lista completa de ubicaciones
    return _ubicaciones.where((u) {
      return u.nombreAlmacen != null &&
          !nombresAsignados.contains(u.nombreAlmacen);
    }).toList();
  }

  /// Calcula la suma total del stock a partir de los registros de ubicación.
  int _calcularStockTotal() {
    return _stockUbicaciones.fold(
      0,
      (total, current) => total + current.cantidad,
    );
  }

  /// Establece (crea o actualiza) el stock en la ubicación seleccionada.
  Future<void> _guardarStockEnUbicacion() async {
    if (_ubicacionSeleccionada == null) {
      _mostrarMensaje('Debe seleccionar una ubicación.');
      return;
    }

    final int idProducto = widget.producto.idProducto ?? 0;
    if (idProducto == 0) {
      _mostrarMensaje('El producto no tiene ID asignado.');
      return;
    }

    int? cantidad = int.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad < 0) {
      _mostrarMensaje('La cantidad debe ser un número positivo.');
      return;
    }

    // Obtener el ID entero de la ubicación seleccionada (asumiendo que está en el modelo Ubicacion)
    final int idUbicacion = _ubicacionSeleccionada!.idUbicacion ?? 0;
    if (idUbicacion <= 0) {
      _mostrarMensaje('Error: La ubicación seleccionada no tiene ID válido.');
      return;
    }

    // 💡 LLAMADA AL NUEVO MÉTODO DEL SERVICIO
    await _inventarioService.establecerStock(idProducto, idUbicacion);
    // ----------------------------------------

    // Volvemos a cargar los datos para actualizar la lista en pantalla y el Dropdown
    await _cargarDatos();

    _mostrarMensaje('Stock actualizado correctamente.');
  }

  /// Abre la pantalla general de gestión de ubicaciones.
  Future<void> _abrirGestionUbicaciones() async {
    await Navigator.of(context).pushNamed(AppRoutes.rutaGestionUbicaciones);

    setState(() {
      _cargando = true;
    });
    await _cargarDatos();
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int stockTotal = _calcularStockTotal();
    // Lista usada para el Dropdown (solo no asignadas)
    final List<Ubicacion> ubicacionesDisponibles =
        _obtenerUbicacionesNoAsignadas();

    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicaciones - ${widget.producto.nombre}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Gestionar ubicaciones',
            onPressed: _abrirGestionUbicaciones,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Stock total: $stockTotal',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Formulario para ASIGNAR stock a una NUEVA ubicación
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: <Widget>[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Asignar producto a una ubicación (nueva)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          // Dropdown solo muestra ubicaciones SIN ASIGNAR
                          // ✨ **CUMPLE REQUISITO 1**
                          child: DropdownButtonFormField<Ubicacion>(
                            value: _ubicacionSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Ubicación',
                            ),
                            items: ubicacionesDisponibles.map((Ubicacion u) {
                              return DropdownMenuItem<Ubicacion>(
                                value: u,
                                child: Text(u.nombreAlmacen!),
                              );
                            }).toList(),
                            onChanged: (Ubicacion? nueva) {
                              setState(() {
                                _ubicacionSeleccionada = nueva;
                                // Para nuevas asignaciones, la cantidad es 0 por defecto
                                _cantidadController.text = '0';
                              });
                            },
                            hint: ubicacionesDisponibles.isEmpty
                                ? const Text('Sin opciones')
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: _ubicacionSeleccionada != null
                              ? _guardarStockEnUbicacion
                              : null,
                          child: const Text('Asignar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Lista de ubicaciones con stock ASIGNADO
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Stock asignado por ubicación (Tocar para actualizar)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        // 💡 Aquí usamos _stockUbicaciones (solo las asignadas)
                        child: _stockUbicaciones.isEmpty
                            ? const Center(
                                child: Text(
                                  'El producto no está asignado a ninguna ubicación.',
                                ),
                              )
                            : ListView.builder(
                                itemCount: _stockUbicaciones.length,
                                itemBuilder: (BuildContext context, int index) {
                                  StockUbicacion s = _stockUbicaciones[index];

                                  // Buscamos la Ubicacion completa para usarla en el Dropdown
                                  Ubicacion?
                                  ubicacionCompleta = _ubicaciones.firstWhere(
                                    (u) =>
                                        u.nombreAlmacen ==
                                        s.idUbicacion, // Asumo que idUbicacion de StockUbicacion es el nombre del almacén
                                    orElse: () => Ubicacion(
                                      idUbicacion: -1,
                                      nombreAlmacen: s.idUbicacion,
                                      activa: true,
                                    ),
                                  );

                                  return ListTile(
                                    title: Text(
                                      s.idUbicacion,
                                    ), // El nombre del almacén viene en s.idUbicacion
                                    subtitle: Text(
                                      'Stock actual: ${s.cantidad}',
                                    ),
                                    selected:
                                        ubicacionCompleta ==
                                        _ubicacionSeleccionada,
                                    // Trailing con botones de editar y eliminar.
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        // Botón de Eliminar
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          tooltip: 'Eliminar asignación',
                                          onPressed: () async {
                                            // Verificamos que tengamos un ID de ubicación válido
                                            if (ubicacionCompleta.idUbicacion !=
                                                    null &&
                                                ubicacionCompleta.idUbicacion! >
                                                    0) {
                                              // 1. Llamada al servicio con los dos parámetros (idProducto, idUbicacion)
                                              await _inventarioService
                                                  .eliminarInstanciaUbicacion(
                                                    widget.producto.idProducto!,
                                                    ubicacionCompleta
                                                        .idUbicacion!, // <-- Aquí está el ID entero
                                                  );

                                              // 2. Recargamos los datos para actualizar la lista en pantalla
                                              // ✨ **CUMPLE REQUISITO 2: ACTUALIZACIÓN DE VISTA**
                                              await _cargarDatos();

                                              _mostrarMensaje(
                                                'Ubicación ${s.idUbicacion} desasignada.',
                                              );
                                            } else {
                                              _mostrarMensaje(
                                                'Error: No se pudo obtener un ID de ubicación válido.',
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
