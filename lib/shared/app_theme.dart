import "package:flutter/material.dart";

class AppColors {
  static const Color primary = Color(0xFF1D4ED8);
  static const Color background = Color(0xFFF1F5F9);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFF0F172A);
}

class AppText {
  static TextStyle brand({required double size, required Color color}) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
      color: color,
      letterSpacing: -0.5,
    );
  }
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.cardDark,
      useMaterial3: true,
    );
  }
}
