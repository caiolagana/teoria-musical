import 'package:flutter/material.dart';

class AppColors {
  static const accent = Color(0xFFE8A54B);
  static const accentDark = Color(0xFFC48530);
  static const background = Color(0xFF151515);
  static const surface = Color(0xFF1E1E1E);
  static const border = Color(0xFF2A2A2A);
  static const text = Color(0xFFE0E0E0);
  static const textDim = Color(0xFF777777);
  static const black = Color(0xFF000000);
}

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accent,
    secondary: AppColors.accentDark,
    surface: AppColors.surface,
    onPrimary: AppColors.black,
    onSurface: AppColors.text,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.text,
    elevation: 0,
  ),
  cardTheme: const CardThemeData(
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      side: BorderSide(color: AppColors.border),
    ),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w300,
      letterSpacing: 1,
      color: AppColors.text,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.text,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.text),
    bodySmall: TextStyle(fontSize: 12, color: AppColors.textDim),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.black,
    ),
  ),
);
