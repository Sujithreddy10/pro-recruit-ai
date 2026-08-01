import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ---------------------------------------------------------------
/// HYLO DESIGN SYSTEM
/// Colors are mutable so ThemeController can swap light/dark at runtime.
/// ---------------------------------------------------------------

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  bool isDarkMode = false;

  void toggleTheme() {
    isDarkMode = !isDarkMode;
    AppColors.applyPalette(isDarkMode);
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (isDarkMode == value) return;
    isDarkMode = value;
    AppColors.applyPalette(isDarkMode);
    notifyListeners();
  }
}

abstract final class AppColors {
  // Brand (fixed across light/dark)
  static const Color accentAmber = Color(0xFFF59E0B);

  // --- Light palette ---
  static const Color _lightPrimary = Color(0xFF1E40AF);
  static const Color _lightPrimaryDark = Color(0xFF0F172A);
  static const Color _lightSecondary = Color(0xFF0F172A);
  static const Color _lightAccent = Color(0xFF059669);
  static const Color _lightSuccess = Color(0xFF16A34A);
  static const Color _lightWarning = Color(0xFFEA580C);
  static const Color _lightDanger = Color(0xFFDC2626);
  static const Color _lightInfo = Color(0xFF2563EB);
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF64748B);
  static const Color _lightTextMuted = Color(0xFF94A3B8);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceAlt = Color(0xFFF8FAFC);
  static const Color _lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color _lightBorder = Color(0xFFE2E8F0);

  // --- Dark palette ---
  static const Color _darkPrimary = Color(0xFF3B82F6);
  static const Color _darkPrimaryDark = Color(0xFF60A5FA);
  static const Color _darkSecondary = Color(0xFF1E293B);
  static const Color _darkAccent = Color(0xFF10B981);
  static const Color _darkSuccess = Color(0xFF22C55E);
  static const Color _darkWarning = Color(0xFFFB923C);
  static const Color _darkDanger = Color(0xFFEF4444);
  static const Color _darkInfo = Color(0xFF60A5FA);
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFFCBD5E1);
  static const Color _darkTextMuted = Color(0xFF94A3B8);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkSurfaceAlt = Color(0xFF0F172A);
  static const Color _darkSurfaceVariant = Color(0xFF334155);
  static const Color _darkBorder = Color(0xFF334155);

  // --- Mutable active values (default: light) ---
  static Color primary = _lightPrimary;
  static Color primaryDark = _lightPrimaryDark;
  static Color secondary = _lightSecondary;
  static Color accent = _lightAccent;
  static Color success = _lightSuccess;
  static Color warning = _lightWarning;
  static Color danger = _lightDanger;
  static Color error = _lightDanger;
  static Color info = _lightInfo;
  static Color textPrimary = _lightTextPrimary;
  static Color textSecondary = _lightTextSecondary;
  static Color textMuted = _lightTextMuted;
  static Color textDark = _lightTextPrimary;
  static Color textLight = Colors.white;
  static Color surface = _lightSurface;
  static Color surfaceAlt = _lightSurfaceAlt;
  static Color surfaceVariant = _lightSurfaceVariant;
  static Color border = _lightBorder;

  static LinearGradient get heroGradient => LinearGradient(
        colors: [primaryDark, primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get successGradient => LinearGradient(
        colors: [const Color(0xFF064E3B), accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static void applyPalette(bool dark) {
    if (dark) {
      primary = _darkPrimary;
      primaryDark = _darkPrimaryDark;
      secondary = _darkSecondary;
      accent = _darkAccent;
      success = _darkSuccess;
      warning = _darkWarning;
      danger = _darkDanger;
      error = _darkDanger;
      info = _darkInfo;
      textPrimary = _darkTextPrimary;
      textSecondary = _darkTextSecondary;
      textMuted = _darkTextMuted;
      textDark = _darkTextPrimary;
      textLight = Colors.white;
      surface = _darkSurface;
      surfaceAlt = _darkSurfaceAlt;
      surfaceVariant = _darkSurfaceVariant;
      border = _darkBorder;
    } else {
      primary = _lightPrimary;
      primaryDark = _lightPrimaryDark;
      secondary = _lightSecondary;
      accent = _lightAccent;
      success = _lightSuccess;
      warning = _lightWarning;
      danger = _lightDanger;
      error = _lightDanger;
      info = _lightInfo;
      textPrimary = _lightTextPrimary;
      textSecondary = _lightTextSecondary;
      textMuted = _lightTextMuted;
      textDark = _lightTextPrimary;
      textLight = Colors.white;
      surface = _lightSurface;
      surfaceAlt = _lightSurfaceAlt;
      surfaceVariant = _lightSurfaceVariant;
      border = _lightBorder;
    }
  }
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
}

abstract final class AppBorderRadius {
  static final BorderRadius small = BorderRadius.circular(10);
  static final BorderRadius medium = BorderRadius.circular(16);
  static final BorderRadius large = BorderRadius.circular(24);
  static const BorderRadius topLarge = BorderRadius.vertical(top: Radius.circular(30));
}

abstract final class AppTypography {
  static TextStyle brand({double size = 28, Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.primary,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionHeader => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.6,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  static TextStyle get bodyMediumBold =>
      bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmallBold => bodySmall.copyWith(fontWeight: FontWeight.w800);

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      );

  static TextStyle get captionBold => caption.copyWith(fontWeight: FontWeight.w800);
}

abstract final class AppText {
  static TextStyle brand({double size = 28, Color? color}) => AppTypography.brand(size: size, color: color);
  static TextStyle displayTitle({Color? color}) => AppTypography.headlineLarge.copyWith(color: color);
  static TextStyle sectionLabel({Color? color}) => AppTypography.sectionHeader.copyWith(color: color);
  static TextStyle cardTitle({Color? color}) => AppTypography.titleMedium.copyWith(color: color);
  static TextStyle body({Color? color}) => AppTypography.bodyMedium.copyWith(color: color);
  static TextStyle caption({Color? color}) => AppTypography.caption.copyWith(color: color);
  static TextStyle badge({Color? color}) => AppTypography.captionBold.copyWith(color: color ?? AppColors.primary);
}

abstract final class AppDecorations {
  static BoxDecoration card({Color? borderColor}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorderRadius.medium,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      );

  static BoxDecoration get elevatedCard => card();

  static BoxDecoration get heroCard => BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppBorderRadius.large,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      );

  static BoxDecoration get primaryCard => heroCard;

  static BoxDecoration pill(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppBorderRadius.small,
      );
}

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.surfaceAlt,
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.headlineLarge,
          iconTheme: IconThemeData(color: AppColors.primary),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.medium,
            side: BorderSide(color: AppColors.border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
            textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      );
}
