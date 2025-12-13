import 'package:akasha/models/cliente.dart'; // Asegúrate de que esta ruta sea correcta
import 'package:flutter/material.dart';

class ClienteDetalles extends StatelessWidget {
  
  final Cliente cliente;

  const ClienteDetalles({super.key, required this.cliente});

  // Función auxiliar para obtener el texto legible del tipo de documento
  String _getTextoTipoDocumento(String tipoDocumento) {
    if (tipoDocumento.toUpperCase().contains('CEDULA')) return 'Cédula';
    if (tipoDocumento.toUpperCase().contains('PASAPORTE')) return 'Pasaporte';
    return tipoDocumento;
  }
  
  @override
  Widget build(BuildContext dialogContext) {
    return AlertDialog(
      title: Text(
        '${cliente.nombre} ${cliente.apellido}', 
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            // TIPO DE DOCUMENTO
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Tipo de Documento'),
              subtitle: Text(_getTextoTipoDocumento(cliente.tipoDocumento)),
              dense: true,
            ),
            // NÚMERO DE DOCUMENTO
            ListTile(
              leading: const Icon(Icons.numbers),
              title: const Text('Nro. Documento'),
              subtitle: Text(cliente.nroDocumento),
              dense: true,
            ),
            // TELÉFONO
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Teléfono'),
              subtitle: Text(cliente.telefono),
              dense: true,
            ),
            // EMAIL
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(cliente.email ?? 'No registrado'),
              dense: true,
            ),
            // DIRECCIÓN
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Dirección'),
              subtitle: Text(cliente.direccion ?? 'No especificada'),
              dense: true,
            ),
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