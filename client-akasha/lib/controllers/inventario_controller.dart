import 'package:akasha/models/producto.dart';
import 'package:akasha/models/services/producto_service.dart';
import 'package:flutter/material.dart';

class InventarioController {
  final ProductoService _service = ProductoService();

  //Esta función se ejecuta cuando quieran agregar un producto
  Future<void> agregarNuevoProducto(
    BuildContext context,
    String nombre,
    String sku,
    String descripcion,
    String precioCosto,
    String precioVenta,
    String proveedor,
    Function(bool, String) onLoginResult,
  ) async {
    //VALIDACIONES
    //Valida que los campos no esten vacíos
    if (nombre.isEmpty ||
        sku.isEmpty ||
        descripcion.isEmpty ||
        precioCosto.isEmpty ||
        precioVenta.isEmpty ||
        proveedor.isEmpty) {
      onLoginResult(false, "Los campos deben estar llenos");
      return;
    }



    Producto nuevoProducto = Producto(
      nombre,

      sku: sku,
      descripcion: descripcion,
      precioCosto: double.parse(precioCosto),
      precioVenta: double.parse(precioVenta),
      id_proveedor: int.parse(proveedor),
    );

    try {
      //Llama al modelo para agregar un nuevo producto
      bool success = await _service.agregarProducto(nuevoProducto);

      if (success) {
        //Notifica a la vista el exito
        onLoginResult(true, "¡Se agrego exitosamente el producto!");
      } else {
        onLoginResult(false, "Algo salió mal...");
      }
    } catch (e) {
      onLoginResult(false, "Error al conectar: ${e.toString()}");
    }
  }

  //Esta función se ejecuta cuando quieran agregar un producto
  List<Producto> obtenerProductos() {
    final List<Producto> listaProductos = [];

    try {
      //Llama al modelo para agregar un nuevo producto
      List<Producto> listaProductos = _service.leerProductos();

      if (listaProductos.isNotEmpty) {
        //Notifica a la vista el exito
        print("¡Se obtuvieron exitosamente los producto!");
        return listaProductos;
      } else {
        print("Algo salió mal...");
      }
    } catch (e) {
      print("Error al conectar: ${e.toString()}");
    }

    return listaProductos;
  }

  //Esta función se ejecuta cuando quieran agregar un producto
  Future<void> actualizarProducto(
    BuildContext context,
    int index,
    String nombre,
    String sku,
    String descripcion,
    String precioCosto,
    String precioVenta,
    String proveedor,
    Function(bool, String) onLoginResult,
  ) async {
    //VALIDACIONES
    //Valida que los campos no esten vacíos
    if (nombre.isEmpty ||
        sku.isEmpty ||
        descripcion.isEmpty ||
        precioCosto.isEmpty ||
        precioVenta.isEmpty ||
        proveedor.isEmpty) {
      onLoginResult(false, "Los campos deben estar llenos");
      return;
    }

    Producto actualizacionProducto = Producto(
      nombre,
      sku: sku,
      descripcion: descripcion,
      precioCosto: double.parse(precioCosto),
      precioVenta: double.parse(precioVenta),
      id_proveedor: int.parse(proveedor),
    );

    try {
      //Llama al modelo para agregar un nuevo producto
      bool success = await _service.actualizarProducto(
        index,
        actualizacionProducto,
      );

      if (success) {
        //Notifica a la vista el exito
        onLoginResult(true, "¡Se agrego exitosamente el producto!");
      } else {
        onLoginResult(false, "Algo salió mal...");
      }
    } catch (e) {
      onLoginResult(false, "Error al conectar: ${e.toString()}");
    }
  }

  //Esta función se ejecuta cuando quieran agregar un producto
  Future<void> eliminarProducto(int index) async {
    try {
      //Llama al modelo para agregar un nuevo producto
      bool success = await _service.eliminarProducto(index);

      if (success) {
        //Notifica a la vista el exito
        print("¡Se elimino exitosamente el producto!");
      } else {
        print("Algo salió mal...");
      }
    } catch (e) {
      print("Error al conectar: ${e.toString()}");
    }
  }
}
