import 'package:flutter/material.dart';

class InicioView extends StatefulWidget {
  const InicioView({super.key});

  @override
  State<InicioView> createState() => _InicioViewState();
}

class _InicioViewState extends State<InicioView> {
  int _counter = 0;
  bool bee = true;

  void _incrementar() {
    setState(() {
      
      if (_counter >= 9) {
        bee = false;
      }
      _counter++;
      print(_counter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementar,
        child: Icon(Icons.add),
      ),
      appBar: AppBar(title: const Text('Inicio')),
      body: Center(child: bee ? Text("$_counter") : Text("Chupalo Bee") ),
    );
  }
}
