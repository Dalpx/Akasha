import 'package:akasha/controllers/login_controller.dart';
import 'package:akasha/utils/constant.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Instancia del controlador
  final LoginController _controller = LoginController();

  //Controladores de texto para los campos
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  //Clave para el Form para validaciones
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _usernameController.text = "Nigger";
    _passwordController.text = "12345678";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(UxPadding.paddingDefault * 1),
        child: Center(
          child: SizedBox(
            width: 400,
            height: 700,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "AKASHA",
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: UxColor.secondTextColor,
                    ),
                  ),
                  SizedBox(height: UxPadding.paddingDefault / 2),
                  Text(
                    "Ingrese los datos",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                      color: UxColor.secondTextColor,
                    ),
                  ),
                  SizedBox(height: UxPadding.paddingDefault * 1),
                  // INPUT DEL USUARIO
                  TextFormField(
                    controller: _usernameController,
                    cursorColor: UxColor.secondTextColor,
                    style: TextStyle(color: UxColor.primaryTextColor),

                    decoration: UxForm(label: "Usuario").textFieldStyle(),
                    //Validacion si el usuario esta vacío
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese un usuario';
                      }
                      return null; // Retorna null si es válido
                    },
                  ),
                  SizedBox(height: UxPadding.paddingDefault / 2),
                  //INPUT DE LA CLAVE
                  TextFormField(
                    controller: _passwordController,
                    cursorColor: UxColor.secondTextColor,
                    obscureText: true, // Buena práctica para claves
                    style: TextStyle(color: UxColor.primaryTextColor),
                    decoration: UxForm(label: "Clave").textFieldStyle(),
                    //Validacion si el usuario esta vacío
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, ingrese una clave';
                      }
                      //Validacion si la clave es menor a 6 caracteres
                      if (value.length < 6) {
                        return 'La clave debe tener al menos 6 caracteres';
                      }
                      return null; // Retorna null si es válido
                    },
                  ),
                  SizedBox(height: UxPadding.paddingDefault * 1),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UxColor.buttonBgColor,
                      foregroundColor: UxColor.thirdTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: UxPadding.paddingDefault * 5,
                        vertical: 20,
                      ),
                      textStyle: TextStyle(fontSize: 20),
                    ),
                    onPressed: () {
                      _onLoginPressed();
                    },
                    child: Text("Ingresar"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _controller.handleLogin(
        context,
        _usernameController.text,
        _passwordController.text,
        (bool success, String message) {
          //Snackbar con el resultado
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        },
      );
    }
  }
}
