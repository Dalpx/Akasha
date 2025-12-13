import 'package:akasha/models/producto.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:flutter/material.dart';

class LineaCompraForm {
  Producto? producto;
  Ubicacion? ubicacionSeleccionada;
  int stockDisponible;

  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;

  LineaCompraForm({
    this.producto,
    int cantidadInicial = 1,
    this.stockDisponible = 0, // Inicializado a 0
  })
      : cantidadCtrl =
            TextEditingController(text: cantidadInicial.toString()),
        precioCtrl = TextEditingController() {
    if (producto != null) {
      precioCtrl.text = producto!.precioCosto.toStringAsFixed(2);
    } else {
      precioCtrl.text = '0.00';
    }
  }

  void dispose() {
    cantidadCtrl.dispose();
    precioCtrl.dispose();
  }
}