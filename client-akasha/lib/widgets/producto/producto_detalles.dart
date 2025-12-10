import 'package:akasha/models/producto.dart';
import 'package:flutter/material.dart';

class productoDetalles extends StatelessWidget {
  
  final Producto producto;

  const productoDetalles({super.key, required this.producto});
  @override
  Widget build(BuildContext dialogContext) {
    return AlertDialog(
      title: Text(
        producto.nombre, 
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            // Código de barras
            ListTile(
              leading: const Icon(Icons.qr_code_2,),
              title: const Text('SKU'),
              subtitle: Text(producto.sku),
              dense: true,
            ),
            // Precio de Venta
            ListTile(
              leading: const Icon(Icons.sell),
              title: const Text('Precio de Venta'),
              subtitle: Text('\$${producto.precioVenta.toStringAsFixed(2)}'),
              dense: true,
            ),
            // Costo
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Costo'),
              subtitle: Text('\$${producto.precioCosto.toStringAsFixed(2)}'),
              dense: true,
            ),
            // Categoría
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categoría'),
              subtitle: Text(producto.idCategoria!),
              dense: true,
            ),
            // Proveedor
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Proveedor'),
              subtitle: Text(producto.idProveedor!),
              dense: true,
            ),
            // Activo / Desactivado
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          child: const Text('Cerrar'),
          onPressed: () {
            Navigator.of(dialogContext).pop();
          },
        ),
      ],
    );
  }
}