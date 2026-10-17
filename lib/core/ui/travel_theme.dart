import 'package:flutter/material.dart';

abstract final class TravelTheme {
  static const forest = Color(0xff294b3d),
      paper = Color(0xfff6f3eb),
      ink = Color(0xff273a30),
      muted = Color(0xff68766c),
      line = Color(0xffdfe3d8),
      copper = Color(0xffb66d43);
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: forest, surface: paper),
      fontFamily: 'NotoSansSC',
    );
    return base.copyWith(
      scaffoldBackgroundColor: paper,
      textTheme: base.textTheme
          .apply(bodyColor: ink, displayColor: ink)
          .copyWith(
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              height: 1.65,
              color: ink,
            ),
            bodyLarge: base.textTheme.bodyLarge?.copyWith(
              fontSize: 15,
              height: 1.65,
              color: ink,
            ),
            headlineLarge: base.textTheme.headlineLarge?.copyWith(
              fontSize: 36,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: forest,
            ),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontSize: 27,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: forest,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: forest,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: forest,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xfffffdf8),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      dividerTheme: const DividerThemeData(color: line, space: 28),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xfffffdf8),
        indicatorColor: forest.withValues(alpha: .12),
      ),
    );
  }
}
