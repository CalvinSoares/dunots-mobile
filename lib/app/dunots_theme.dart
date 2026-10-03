import 'package:flutter/material.dart';

abstract final class DunotsColors {
  // Fundação escura do mobile. O fundo e as superfícies principais ficam
  // reduzidos a dois tons para diminuir ruído visual durante o estudo.
  static const background = Color(0xFF0B1316);
  static const panel = Color(0xFF122021);
  static const surfaceSubtle = background;
  static const surfaceSidebar = panel;
  static const surfaceRaised = panel;

  static const ink = Color(0xFFF5F0E7);
  static const muted = Color(0xFFCEC8BD);
  static const textTertiary = Color(0xFFAEA89D);
  static const border = Color(0xFF494D45);

  static const emerald = Color(0xFF49D17D);
  static const mint = Color(0xFFA8D5BA);
  static const teal = Color(0xFF56D4C7);
  static const amber = Color(0xFFE8C56A);
  static const purple = Color(0xFFB9A1F5); // categoria excepcional
  static const attentionSurface = Color(0xFF4B4022);
  static const success = mint;
  static const danger = Color(0xFFFF8278);
}

ThemeData buildDunotsTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: DunotsColors.emerald,
        brightness: Brightness.dark,
        surface: DunotsColors.panel,
      ).copyWith(
        surface: DunotsColors.panel,
        onSurface: DunotsColors.ink,
        onSurfaceVariant: DunotsColors.muted,
        primary: DunotsColors.emerald,
        onPrimary: DunotsColors.background,
        secondary: DunotsColors.mint,
        onSecondary: DunotsColors.background,
        tertiary: DunotsColors.teal,
        onTertiary: DunotsColors.background,
        primaryContainer: Color(0xFF1C4B32),
        onPrimaryContainer: DunotsColors.ink,
        secondaryContainer: Color(0xFF1A3A35),
        onSecondaryContainer: DunotsColors.ink,
        error: DunotsColors.danger,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: DunotsColors.background,
    cardTheme: const CardThemeData(
      color: DunotsColors.panel,
      margin: EdgeInsets.zero,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: DunotsColors.border),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: DunotsColors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: DunotsColors.panel,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black54,
      menuPadding: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: DunotsColors.border),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: DunotsColors.panel,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: DunotsColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: DunotsColors.border),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: DunotsColors.surfaceSidebar,
      indicatorColor: Color(0x2E49D17D),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12, color: DunotsColors.muted),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: DunotsColors.surfaceSidebar,
      indicatorColor: Color(0x2E49D17D),
      selectedIconTheme: IconThemeData(color: DunotsColors.emerald),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: DunotsColors.emerald, width: 2),
      ),
    ),
  );
}
