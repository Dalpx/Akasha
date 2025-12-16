import 'package:flutter/material.dart';

class MovimientoDialogs {
  static Future<int?> pickTipoMovimiento({
    required BuildContext context,
    required int? initial,
  }) async {
    int? local = initial;

    final result = await showDialog<int?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filtros'),
              content: DropdownButtonFormField<int?>(
                value: local,
                items: const [
                  DropdownMenuItem<int?>(value: null, child: Text('Todos')),
                  DropdownMenuItem<int?>(value: 1, child: Text('Entrada')),
                  DropdownMenuItem<int?>(value: 0, child: Text('Salida')),
                ],
                onChanged: (v) => setDialogState(() => local = v),
                decoration: const InputDecoration(
                  labelText: 'Tipo de movimiento',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => setDialogState(() => local = null),
                  child: const Text('Limpiar'),
                ),
                ElevatedButton(
                  // Vuelve al valor inicial sin cambios
                  onPressed: () => Navigator.of(context).pop(initial),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  // Aplica el valor 'local' (que puede ser null para 'Todos')
                  onPressed: () => Navigator.of(context).pop(local),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );

    // *** CAMBIO AQUÍ: QUITAR EL '?? initial' ***
    // Si result es null, se devuelve null (que es el valor de 'Todos').
    // Si el diálogo se descarta (tap outside), result será null, y
    // se devolverá null, lo que puede ser deseable si 'Todos' es el valor por defecto
    // para un descarte.
    return result; 
  }
}