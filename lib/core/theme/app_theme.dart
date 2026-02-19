import 'package:flutter/material.dart';

/// Centralised Glassmorphism-inspired colour tokens.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF141828);
  static const Color primary = Color(0xFF4F8EF7);
  static const Color primaryVariant = Color(0xFF7B61FF);
  static const Color accent = Color(0xFF00D4AA);
  static const Color danger = Color(0xFFFF4D6A);
  static const Color warning = Color(0xFFFFB830);
  static const Color success = Color(0xFF22C55E);

  static const Color glassWhite = Color(0x33FFFFFF); // 20 % white
  static const Color glassBorder = Color(0x55FFFFFF); // 33 % white
  static const Color onGlass = Color(0xF0FFFFFF);

  static const Color textPrimary = Color(0xFFF1F5FF);
  static const Color textSecondary = Color(0xFFABB3C8);
  static const Color textDisabled = Color(0xFF5A6178);

  // Folder tag colours
  static const Color folderActive = Color(0xFF4F8EF7);
  static const Color folderFollowUp = Color(0xFFFFB830);
  static const Color folderHotLead = Color(0xFFFF4D6A);
  static const Color folderSold = Color(0xFF22C55E);
  static const Color folderArchived = Color(0xFF5A6178);
}

/// Application-wide [ThemeData] built around the Glassmorphism aesthetic.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'SF Pro Display',
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle:
            const TextStyle(color: AppColors.textDisabled, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textPrimary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.glassWhite,
        labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
        side: const BorderSide(color: AppColors.glassBorder),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerColor: AppColors.glassBorder,
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle:
            const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700),
    displayMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600),
    titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600),
    titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w400),
    labelLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3),
    labelSmall: TextStyle(
        color: AppColors.textDisabled,
        fontSize: 11,
        fontWeight: FontWeight.w400),
  );
}
