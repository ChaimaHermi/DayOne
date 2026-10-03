import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD9467A)),
    useMaterial3: true,
  );
}
