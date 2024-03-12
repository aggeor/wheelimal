import 'package:flutter/material.dart';

class WheelimalThemes {
  static final lightTheme = ThemeData(
    primaryColor: WheelimalColors.lightBlue,
    brightness: Brightness.light,
  );

  static final darkTheme = ThemeData(
    primaryColor: WheelimalColors.darkBlue,
    brightness: Brightness.dark,
  );
}

class WheelimalColors {
  static const lightBlue = Color.fromARGB(255, 129, 170, 246);
  static const darkBlue = Color.fromARGB(255, 27, 34, 48);
}
