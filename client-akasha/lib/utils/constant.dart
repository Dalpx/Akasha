// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

//Constantes de Color
class UxColor {
  static const bgColor = Color(0xFFFAF8EF);
  static const primaryColor = Color(0xFFBBADA0);
  static const cardBackgroundColor = Color(0xFFCDC1B4);
  static const primaryTextColor = Color(0xFF6a5741);
  static const secondTextColor = Color(0xFF776E65);
  static const thirdTextColor = Color(0xFFF9F6F2);
  static const buttonBgColor = Color(0xFF8F7A66);
}

//Constantes de Radio
class UxRadius {
  static const radiusTile = Radius.circular(6.0);
  static const radiusBoard = Radius.circular(8.0);
  static const radiusBtn = Radius.circular(4.0);
}

//Constante de Padding
class UxPadding {
  static const paddingDefault = 24;
}


//Constante de formulario
class UxForm {
  String label;
  UxForm({required this.label});

  InputDecoration textFieldStyle() {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: UxColor.buttonBgColor),
      filled: true,
      fillColor: UxColor.thirdTextColor,
      border: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: UxColor.buttonBgColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: UxColor.buttonBgColor),
      ),
      hoverColor: Colors.transparent,
    );
  }
}

//Constantes de texto
