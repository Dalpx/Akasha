import 'package:akasha/models/ubicacion.dart';
import 'package:akasha/services/ubicacion_service.dart';

import 'package:akasha/views/entidades_maestras/widgets/tabs/categorias_tab.dart';
import 'package:akasha/views/entidades_maestras/widgets/tabs/proveedores_tab.dart';
import 'package:akasha/views/entidades_maestras/widgets/tabs/ubicaciones_tab.dart';

import 'package:flutter/material.dart';
import '../../models/proveedor.dart';
import '../../models/categoria.dart';
import '../../services/proveedor_service.dart';
import '../../services/categoria_service.dart';

class GestionEntidadesMaestrasPage extends StatefulWidget {
  const GestionEntidadesMaestrasPage({super.key});

  @override
  State<GestionEntidadesMaestrasPage> createState() {
    return _GestionEntidadesMaestrasPageState();
  }
}

class _GestionEntidadesMaestrasPageState
    extends State<GestionEntidadesMaestrasPage> {
  final ProveedorService _proveedorService = ProveedorService();
  final CategoriaService _categoriaService = CategoriaService();
  final UbicacionService _ubicacionService = UbicacionService();

  late Future<List<Proveedor>> _futureProveedores;
  late Future<List<Categoria>> _futureCategorias;
  late Future<List<Ubicacion>> _futureUbicaciones;

  List<Proveedor>? _cacheProveedores;
  List<Categoria>? _cacheCategorias;
  List<Ubicacion>? _cacheUbicaciones;

  @override
  void initState() {
    super.initState();
    _futureProveedores = _loadProveedores();
    _futureCategorias = _loadCategorias();
    _futureUbicaciones = _loadUbicaciones();
  }

  Future<List<Proveedor>> _loadProveedores({bool force = false}) async {
    if (!force && _cacheProveedores != null) {
      return _cacheProveedores!;
    }
    final list = await _proveedorService.obtenerProveedoresActivos();
    _cacheProveedores = list;
    return list;
  }

  Future<List<Categoria>> _loadCategorias({bool force = false}) async {
    if (!force && _cacheCategorias != null) {
      return _cacheCategorias!;
    }
    final list = await _categoriaService.obtenerCategorias();
    _cacheCategorias = list;
    return list;
  }

  Future<List<Ubicacion>> _loadUbicaciones({bool force = false}) async {
    if (!force && _cacheUbicaciones != null) {
      return _cacheUbicaciones!;
    }
    final list = await _ubicacionService.obtenerUbicacionesActivas();
    _cacheUbicaciones = list;
    return list;
  }

  void _recargarProveedores() {
    if (!mounted) return;
    setState(() {
      _futureProveedores = _loadProveedores(force: true);
    });
  }

  void _recargarCategorias() {
    if (!mounted) return;
    setState(() {
      _futureCategorias = _loadCategorias(force: true);
    });
  }

  void _recargarUbicaciones() {
    if (!mounted) return;
    setState(() {
      _futureUbicaciones = _loadUbicaciones(force: true);
    });
  }

  void _confirmarEliminarProveedor(Proveedor proveedor) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Seguro que deseas eliminar al proveedor "${proveedor.nombre}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (proveedor.idProveedor != null) {
                  await _proveedorService.eliminarProveedor(
                    proveedor.idProveedor!,
                  );
                }

                if (!mounted) return;

                Navigator.of(dialogContext).pop();

                _cacheProveedores = null;
                _recargarProveedores();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarEliminarCategoria(Categoria categoria) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Seguro que deseas eliminar la categoría "${categoria.nombreCategoria}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (categoria.idCategoria != null) {
                  await _categoriaService.eliminarCategoria(
                    categoria.idCategoria!,
                  );
                }

                if (!mounted) return;

                Navigator.of(dialogContext).pop();

                _cacheCategorias = null;
                _recargarCategorias();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmarEliminarUbicacion(Ubicacion ubicacion) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Seguro que deseas eliminar la ubicación "${ubicacion.nombreAlmacen}"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (ubicacion.idUbicacion != null) {
                  await _ubicacionService.eliminarUbicacion(
                    ubicacion.idUbicacion!,
                  );
                }

                if (!mounted) return;

                Navigator.of(dialogContext).pop();

                _cacheUbicaciones = null;
                _recargarUbicaciones();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              const TabBar(
                tabs: <Tab>[
                  Tab(text: 'Proveedores'),
                  Tab(text: 'Categorías'),
                  Tab(text: 'Ubicaciones'),
                ],
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: TabBarView(
                  children: [
                    ProveedoresTab(
                      service: _proveedorService,
                      future: _futureProveedores,
                      onReload: _recargarProveedores,
                      onDelete: _confirmarEliminarProveedor,
                    ),
                    CategoriasTab(
                      service: _categoriaService,
                      future: _futureCategorias,
                      onReload: _recargarCategorias,
                      onDelete: _confirmarEliminarCategoria,
                    ),
                    UbicacionesTab(
                      service: _ubicacionService,
                      future: _futureUbicaciones,
                      onReload: _recargarUbicaciones,
                      onDelete: _confirmarEliminarUbicacion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                child: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
