import '../models/cliente.dart';

/// Servicio que maneja la lógica de negocio relacionada con los clientes.
/// En esta versión, la información se mantiene en memoria para fines didácticos.
class ClienteService {
  final List<Cliente> _clientes = <Cliente>[];

  ClienteService() {
    // Datos de ejemplo.
    _clientes.add(
      Cliente(
        idCliente: 1,
        nombre: 'Cliente Genérico',
        telefono: '555-0000',
        email: 'cliente@example.com',
        direccion: 'Calle Principal 123',
        activo: true,
      ),
    );
  }

  /// Obtiene todos los clientes activos.
  Future<List<Cliente>> obtenerClientesActivos() async {
    await Future.delayed(const Duration(milliseconds: 200));

    List<Cliente> activos = <Cliente>[];

    for (int i = 0; i < _clientes.length; i++) {
      Cliente cliente = _clientes[i];
      if (cliente.activo) {
        activos.add(cliente);
      }
    }

    return activos;
  }

  /// Crea un nuevo cliente y lo agrega a la lista en memoria.
  Future<Cliente> crearCliente(Cliente cliente) async {
    await Future.delayed(const Duration(milliseconds: 200));

    int nuevoId = _clientes.length + 1;
    cliente.idCliente = nuevoId;
    _clientes.add(cliente);
    return cliente;
  }

  /// Actualiza un cliente existente.
  Future<void> actualizarCliente(Cliente clienteActualizado) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (int i = 0; i < _clientes.length; i++) {
      Cliente cliente = _clientes[i];
      if (cliente.idCliente == clienteActualizado.idCliente) {
        _clientes[i] = clienteActualizado;
      }
    }
  }

  /// Elimina lógicamente un cliente (lo marca como inactivo).
  Future<void> eliminarCliente(int idCliente) async {
    await Future.delayed(const Duration(milliseconds: 200));

    for (int i = 0; i < _clientes.length; i++) {
      Cliente cliente = _clientes[i];
      if (cliente.idCliente == idCliente) {
        cliente.activo = false;
      }
    }
  }
}
