// ignore_for_file: non_constant_identifier_names, avoid_print
import 'package:akasha/controllers/inventario_controller.dart';
import 'package:akasha/models/producto.dart';
import 'package:flutter/material.dart';

class InventarioView extends StatefulWidget {
  const InventarioView({super.key});

  @override
  State<InventarioView> createState() => _InventarioViewState();
}

class _InventarioViewState extends State<InventarioView> {
  //Instancia del controlador
  final InventarioController _controller = InventarioController();

  //Controladores de texto para los campos
  final TextEditingController _nombre_producto = TextEditingController();
  final TextEditingController _sku_producto = TextEditingController();
  final TextEditingController _descripcion_producto = TextEditingController();
  final TextEditingController _precioCosto_producto = TextEditingController();
  final TextEditingController _precioVenta_producto = TextEditingController();
  final TextEditingController _proveedor_producto = TextEditingController();

  //Instancia de lista productos
  List<Producto> _lista_productos = [];

  //Abre una modal para añadir un producto
  void _openNoteBox({int? index}) {
    //Rellenar campos con el texto si se va a editar
    if (index != null) {
      _nombre_producto.text = _lista_productos[index].nombre;
      _sku_producto.text = _lista_productos[index].sku;
      _descripcion_producto.text = _lista_productos[index].descripcion;
      _precioCosto_producto.text = _lista_productos[index].precioCosto
          .toString();
      _precioVenta_producto.text = _lista_productos[index].precioVenta
          .toString();
      _proveedor_producto.text = _lista_productos[index].id_proveedor
          .toString();
    } else {
      _nombre_producto.text = "Destornillador Rojo";
      _sku_producto.text = "0001";
      _descripcion_producto.text = "Es rojo y desatornilla";
      _precioCosto_producto.text = "5";
      _precioVenta_producto.text = "10";
      _proveedor_producto.text = "1";
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          height: 440,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              index == null
                  ? Text("Agregar", style: TextStyle(fontSize: 22))
                  : Text("Editar", style: TextStyle(fontSize: 22)),
              SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(label: Text("Producto")),
                controller: _nombre_producto,
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(label: Text("SKU")),
                controller: _sku_producto,
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(label: Text("descripcion")),
                controller: _descripcion_producto,
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(label: Text("Precio Costo")),
                controller: _precioCosto_producto,
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(label: Text("Precio Venta")),
                controller: _precioVenta_producto,
              ),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(label: Text("proveedor")),
                controller: _proveedor_producto,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              //Parsea la información
              String nombre = _nombre_producto.text;
              String sku = _sku_producto.text;
              String descripcion = _descripcion_producto.text;
              String precioCosto = _precioCosto_producto.text;
              String precioVenta = _precioVenta_producto.text;
              String proveedor = _proveedor_producto.text;

              if (index == null) {
                //Acá se enviara al controlador para que este hiciera las validaciones y lo mandara a la API
                _controller.agregarNuevoProducto(
                  context,
                  nombre,
                  sku,
                  descripcion,
                  precioCosto,
                  precioVenta,
                  proveedor,
                  (bool success, String message) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                );
              } else {
                _controller.actualizarProducto(
                  context,
                  index,
                  nombre,
                  sku,
                  descripcion,
                  precioCosto,
                  precioVenta,
                  proveedor,
                  (bool success, String message) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
                );
              }

              //Actualizamos los datos para que  se refleje el nuevo producto
              setState(() {
                _lista_productos = _controller.obtenerProductos();
              });

              //Acá se debe borrar toda la información
              _nombre_producto.clear();
              _sku_producto.clear();
              _descripcion_producto.clear();
              _precioCosto_producto.clear();
              _precioVenta_producto.clear();
              _proveedor_producto.clear();

              //cerramos el modal
              Navigator.pop(context);
            },
            child: index == null ? Text("Agregar") : Text("Editar"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _lista_productos = _controller.obtenerProductos();
  }

  @override
  void dispose() {
    _nombre_producto.dispose();
    _sku_producto.dispose();
    _descripcion_producto.dispose();
    _precioCosto_producto.dispose();
    _precioVenta_producto.dispose();
    _proveedor_producto.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Instancia de lista de productos
    return Scaffold(
      appBar: AppBar(
        title: Text("Inventario"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            onPressed: () {
              print("Abrir notificaciones");
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            onPressed: () {
              print("Abrir configuración");
            },
          ),
        ],
        // Esta línea elimina la flecha de retroceso
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNoteBox,
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _lista_productos.length,
        itemBuilder: (context, index) {
          final producto = _lista_productos[index];
          return InkWell(
            onTap: () {
              showDialog(context: context, builder: (context) => AlertDialog(
                content: Text("Detalle del producto ${producto.nombre}"),
              ));
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: Text((index + 1).toString()),
                title: Text(
                  producto.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('SKU: ${producto.sku}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        _openNoteBox(index: index);
                      },
                      icon: Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () {
                        _controller.eliminarProducto(index);
                        setState(() {
                          _lista_productos = _controller.obtenerProductos();
                        });
                      },
                      icon: Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
