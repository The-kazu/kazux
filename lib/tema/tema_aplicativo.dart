import 'package:flutter/material.dart';

class TemaAplicativo {
  static const Color teal = Color(0xFF2D6B5E);
  static const Color tealLight = Color(0xFF3D8C7A);
  static const Color tealDark = Color(0xFF1E4D43);
  static const Color mint = Color(0xFFEAF3EF);
  static const Color surface = Color(0xFFF5F8F5);
  static const Color surfaceAlt = Color(0xFFEBF2EF);
  static const Color textDark = Color(0xFF1A2B26);
  static const Color textMid = Color(0xFF4A6560);
  static const Color textLight = Color(0xFF8BA8A0);
  static const Color danger = Color(0xFFE05252);
  static const Color info = Color(0xFF4A90D9);
  static const Color warning = Color(0xFFF0C040);

  static ThemeData get themeClaro => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: surface,
    fontFamily: 'Sora',
    colorScheme: ColorScheme.fromSeed(
      seedColor: teal,
      primary: teal,
      secondary: tealLight,
      surface: surface,
      error: danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: tealLight, width: 1.5),
      ),
      labelStyle: const TextStyle(color: textMid, fontWeight: FontWeight.w600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      elevation: 3,
    ),
  );

  static ThemeData get themeEscuro => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF111A17),
    fontFamily: 'Sora',
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7ED0BA),
      secondary: Color(0xFF9AE0CE),
      surface: Color(0xFF1B2925),
      error: Color(0xFFFF8B8B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF163F36),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1B2925),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF23352F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7ED0BA), width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7ED0BA),
        foregroundColor: const Color(0xFF10231D),
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF7ED0BA),
      foregroundColor: Color(0xFF10231D),
      elevation: 3,
    ),
  );

  static ThemeData get theme => themeClaro;
}
