import 'package:flutter/material.dart';

class AppWidget {
  static TextStyle HeadlineTextFieldStyle() {
    return TextStyle(
      color: Colors.black,
      fontSize: 30.0,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle SimpleTextFieldStyle() {
    return TextStyle(color: Colors.black, fontSize: 18.0);
  }

  static TextStyle whiteTextFieldStyle() {
    return TextStyle(
      color: Colors.white,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle boldTextFieldStyle() {
    return TextStyle(
      color: Colors.black,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle priceTextFieldStyle() {
    return TextStyle(
      color: const Color.fromARGB(184, 0, 0, 0),
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle boldwhiteTextFieldStyle() {
    return TextStyle(
      color: Colors.white,
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle SignUpTextFeildStyle() {
    return TextStyle(
      color: const Color.fromARGB(174, 0, 0, 0),
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ); // TextStyle
  }
}
