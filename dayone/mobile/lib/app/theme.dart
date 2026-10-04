import 'package:flutter/material.dart';

class DayOneColors {
  DayOneColors._();

  static const bg = Color(0xFFFFF5F8);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFFD9467F);
  static const primaryDark = Color(0xFF8C1F4E);
  static const primarySoft = Color(0xFFFDE6EF);
  static const plum = Color(0xFF6E2A5C);
  static const plumSoft = Color(0xFFF4E8F1);
  static const success = Color(0xFF1F8A5B);
  static const successSoft = Color(0xFFE3F5EC);
  static const warning = Color(0xFFC46A12);
  static const warningSoft = Color(0xFFFFF1DF);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFDE8E6);
  static const text = Color(0xFF2A1520);
  static const muted = Color(0xFF86707B);
  static const border = Color(0xFFF3DCE5);
  static const bubbleMine = Color(0xFFFFD9E7);
  static const chatBg = Color(0xFFFBEFF3);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEC6A9E), Color(0xFFD9467F), Color(0xFF8C1F4E)],
  );

  static const shadow = [
    BoxShadow(color: Color(0x148C1F4E), blurRadius: 16, offset: Offset(0, 6)),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: DayOneColors.primary,
      primary: DayOneColors.primary,
      onPrimary: Colors.white,
      surface: DayOneColors.surface,
      onSurface: DayOneColors.text,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DayOneColors.bg,
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: DayOneColors.muted, fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(color: DayOneColors.text, fontWeight: FontWeight.w700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DayOneColors.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DayOneColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DayOneColors.primary, width: 1.8),
        ),
      ),
    );
  }
}
