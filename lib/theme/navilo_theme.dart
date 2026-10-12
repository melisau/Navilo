import 'package:flutter/material.dart';

abstract final class NaviloColors {
  static const forest = Color(0xFF194839);
  static const forestDeep = Color(0xFF12392E);
  static const saffron = Color(0xFFD99A32);
  static const ivory = Color(0xFFFAF7EF);
  static const paper = Color(0xFFFFFEFA);
  static const ink = Color(0xFF1B2420);
  static const muted = Color(0xFF68756F);
  static const line = Color(0xFFE4E0D5);
  static const warning = Color(0xFFB45B29);
  static const uncertain = Color(0xFF777D79);
}

abstract final class NaviloTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: NaviloColors.forest,
      surface: NaviloColors.ivory,
    ).copyWith(
      primary: NaviloColors.forest,
      onPrimary: Colors.white,
      secondary: NaviloColors.saffron,
      surface: NaviloColors.ivory,
      onSurface: NaviloColors.ink,
      error: NaviloColors.warning,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: NaviloColors.ivory,
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'serif',
          fontSize: 29,
          height: 1.16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.55,
          color: NaviloColors.ink,
        ),
        titleLarge: TextStyle(
          fontFamily: 'serif',
          fontSize: 21,
          height: 1.25,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
          color: NaviloColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: NaviloColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.48,
          color: NaviloColors.muted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: NaviloColors.ivory,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleSpacing: 20,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: NaviloColors.paper,
        indicatorColor: const Color(0xFFE9E3D4),
        height: 72,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        )),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: NaviloColors.paper,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: NaviloColors.paper,
          foregroundColor: NaviloColors.forest,
          side: const BorderSide(color: NaviloColors.line),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NaviloColors.paper,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NaviloColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NaviloColors.line),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0ECE2),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: const DividerThemeData(color: NaviloColors.line, space: 24),
    );
  }
}
