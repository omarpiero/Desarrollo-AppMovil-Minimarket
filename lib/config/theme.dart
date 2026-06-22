import 'package:flutter/material.dart';

class MinimarketTheme {
  // ─── Colores Primarios Wisa (Rojo) ───
  static const Color primaryRed = Color(0xFFE53935);
  static const Color primaryRedDark = Color(0xFFC62828);
  static const Color primaryRedLight = Color(0xFFEF5350);
  static const Color primaryRedSurface = Color(0xFFFFF5F5);

  // ─── Colores de Acento (Amarillo — del logo Wisa) ───
  static const Color primaryYellow = Color(0xFFFFC107);
  static const Color primaryYellowDark = Color(0xFFFFA000);
  static const Color primaryYellowLight = Color(0xFFFFCA28);
  static const Color primaryYellowSurface = Color(0xFFFFF8E1);

  // ─── Aliases de compatibilidad (old names → new Wisa values) ───
  static const Color secondaryNavy = primaryRed;
  static const Color secondaryNavyLight = primaryRedLight;
  static const Color secondaryNavyDark = primaryRedDark;

  // ─── Colores Neutros ───
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);

  // ─── Colores de Estado ───
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFD32F2F);
  static const Color disponible = Color(0xFF4CAF50);
  static const Color sinStock = Color(0xFFBDBDBD);
  static const Color stockBajo = Color(0xFFFF9800);

  // ─── ThemeData ───
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        onPrimary: Colors.white,
        secondary: primaryYellow,
        onSecondary: primaryRedDark,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryRedDark,
        selectedItemColor: primaryYellow,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: primaryRed.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: primaryRedDark,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        prefixIconColor: primaryRed,
        labelStyle: const TextStyle(color: textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryRedDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: primaryRed,
        labelStyle: const TextStyle(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryYellow,
        foregroundColor: primaryRedDark,
      ),
    );
  }
}
