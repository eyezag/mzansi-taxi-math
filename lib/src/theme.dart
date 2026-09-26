import 'package:flutter/material.dart';

abstract final class AppColors {
  static const bg = Color(0xFFF3F2EE);
  static const surface = Colors.white;
  static const field = Color(0xFFF3F2EE);
  static const line = Color(0xFFE6E4DE);
  static const ink = Color(0xFF17181A);
  static const muted = Color(0xFF8C8B88);

  // Accent colours are reserved for money outcomes.
  static const money = Color(0xFF15945A);
  static const moneySoft = Color(0xFFE5F4EB);
  static const short = Color(0xFFD4520F);
  static const shortSoft = Color(0xFFFCEDE3);
}

abstract final class AppText {
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: AppColors.muted,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static TextStyle money(double size, {Color color = AppColors.ink}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -size * 0.03,
        height: 1.1,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

BoxDecoration cardDecoration({double radius = 22}) => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(color: Color(0x0D000000), blurRadius: 18, offset: Offset(0, 4)),
      ],
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.money,
    surface: AppColors.surface,
  ).copyWith(primary: AppColors.ink, onPrimary: Colors.white);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.ink),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      actionTextColor: const Color(0xFF7FE0AE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
