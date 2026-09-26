import 'package:flutter/material.dart';

import 'dunots_home_shell.dart';

class DunotsMobileApp extends StatelessWidget {
  const DunotsMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF202321);
    const panel = Color(0xFF292D2A);
    const ink = Color(0xFFF2EEE4);
    const muted = Color(0xFFB6B7AD);
    const coral = Color(0xFFFF7168);
    const blue = Color(0xFF78B8FF);

    final scheme = ColorScheme.fromSeed(
      seedColor: coral,
      brightness: Brightness.dark,
      surface: panel,
    ).copyWith(surface: panel, onSurface: ink, primary: coral, secondary: blue);

    return MaterialApp(
      title: 'Dunots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: background,
        cardTheme: const CardThemeData(
          color: panel,
          margin: EdgeInsets.zero,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: panel,
          indicatorColor: coral.withValues(alpha: 0.18),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12, color: muted),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFF4A504B)),
          ),
        ),
      ),
      home: const DunotsHomeShell(),
    );
  }
}
