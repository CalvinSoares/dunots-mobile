import 'package:flutter/material.dart';

abstract final class DunotsColors {
  static const background = Color(0xFF202321);
  static const panel = Color(0xFF292D2A);
  static const ink = Color(0xFFF2EEE4);
  static const muted = Color(0xFFB6B7AD);
  static const border = Color(0xFF4A504B);
  static const coral = Color(0xFFFF7168);
  static const blue = Color(0xFF78B8FF);
  static const purple = Color(0xFFB79BFF);
  static const yellow = Color(0xFFFFC857);
}

ThemeData buildDunotsTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: DunotsColors.coral,
        brightness: Brightness.dark,
        surface: DunotsColors.panel,
      ).copyWith(
        surface: DunotsColors.panel,
        onSurface: DunotsColors.ink,
        primary: DunotsColors.coral,
        secondary: DunotsColors.blue,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: DunotsColors.background,
    cardTheme: const CardThemeData(
      color: DunotsColors.panel,
      margin: EdgeInsets.zero,
      elevation: 0,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: DunotsColors.panel,
      indicatorColor: Color(0x2EFF7168),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, color: DunotsColors.muted),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: DunotsColors.panel,
      indicatorColor: Color(0x2EFF7168),
      selectedIconTheme: IconThemeData(color: DunotsColors.coral),
      unselectedIconTheme: IconThemeData(color: DunotsColors.muted),
      selectedLabelTextStyle: TextStyle(
        color: DunotsColors.ink,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: DunotsColors.muted),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: DunotsColors.panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: DunotsColors.border),
      ),
    ),
  );
}
