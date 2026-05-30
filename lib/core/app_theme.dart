import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // User-app color palette
  static const Color primary = Color(0xFFFCC050);       // orange-yellow
  static const Color primaryCoral = Color(0xFFFF724C);  // coral/orange
  static const Color background = Color(0xFF3D3E46);    // dark bg
  static const Color surface = Color(0xFF4A4B54);       // slightly lighter card bg
  static const Color offWhite = Color(0xFFFFFEFC);

  static const Color primaryLight = Color(0xFFFFD980); // lighter primary for accepted state
  static const Color accent = Color(0xFFFF724C);
  static const Color success = Color(0xFF0CA40E);
  static const Color warning = Color(0xFFFFE02E);
  static const Color danger = Color(0xFFEB0101);

  // Text colors on dark bg
  static const Color textPrimary = Color(0xFFFFFEFC);
  static const Color textSecondary = Color(0xFFBDBDBD);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'LamaSans',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.dark(
          primary: primary,
          onPrimary: background,
          secondary: primaryCoral,
          onSecondary: offWhite,
          surface: surface,
          onSurface: offWhite,
          error: danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: offWhite,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          titleTextStyle: TextStyle(
            fontFamily: 'LamaSans',
            color: primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: offWhite),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: textSecondary,
          indicatorColor: primary,
          labelStyle: TextStyle(fontFamily: 'LamaSans', fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontFamily: 'LamaSans',
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger),
          ),
          hintStyle: const TextStyle(color: textSecondary),
          labelStyle: const TextStyle(color: textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withValues(alpha: 0.08),
          thickness: 1,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: background,
          selectedItemColor: primary,
          unselectedItemColor: textSecondary,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surface,
          contentTextStyle: const TextStyle(color: offWhite, fontFamily: 'LamaSans'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surface,
          selectedColor: primary,
          labelStyle: const TextStyle(color: offWhite, fontFamily: 'LamaSans'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: background,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: offWhite, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: offWhite, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(color: offWhite, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: offWhite, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: offWhite, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: offWhite, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: offWhite),
          bodyMedium: TextStyle(color: offWhite),
          bodySmall: TextStyle(color: textSecondary),
          labelLarge: TextStyle(color: offWhite, fontWeight: FontWeight.bold),
          labelSmall: TextStyle(color: textSecondary),
        ),
      );
}
