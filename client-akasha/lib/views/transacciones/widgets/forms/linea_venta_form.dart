import 'package:akasha/models/producto.dart';
import 'package:akasha/models/ubicacion.dart';
import 'package:flutter/material.dart';

class LineaVentaForm {
  Producto? producto;
  Ubicacion? ubicacionSeleccionada;
  // AÑADIDO: Campo para almacenar el stock disponible en la ubicacionSeleccionada
  int stockDisponible;

  final TextEditingController cantidadCtrl;
  final TextEditingController precioCtrl;

  LineaVentaForm({
    this.producto, 
    int cantidadInicial = 1,
    this.stockDisponible = 0, // Inicializado a 0
  })
      : cantidadCtrl =
            TextEditingController(text: cantidadInicial.toString()),
        precioCtrl = TextEditingController() {
    if (producto != null) {
      precioCtrl.text = producto!.precioVenta.toStringAsFixed(2);
    } else {
      precioCtrl.text = '0.00';
    }
  }

  void dispose() {
    cantidadCtrl.dispose();
    precioCtrl.dispose();
  }
}