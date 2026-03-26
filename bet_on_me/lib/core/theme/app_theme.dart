import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Application theme definitions.
abstract final class AppTheme {
  static ThemeData get dark  => _build(AppThemeColors.dark);
  static ThemeData get light => _build(AppThemeColors.light);

  static ThemeData _build(AppThemeColors c) {
    final isDark = c.isDark;
    final brightness =
        isDark ? Brightness.dark : Brightness.light;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      extensions: [c],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.gold,
        onPrimary: Colors.black,
        secondary: AppColors.gold,
        onSecondary: Colors.black,
        error: AppColors.error,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.text),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: AppColors.goldDim,
        elevation: 0,
        height: 68,
        labelBehavior:
            NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.gold
                : c.textMuted,
            size: 22,
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: c.surface,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark
              ? BorderSide(color: c.border)
              : BorderSide.none,
        ),
        elevation: isDark ? 0 : 8,
        shadowColor: c.cardShadow,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: TextStyle(color: c.text),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: c.text,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.1,
        ),
        headlineMedium: TextStyle(
          color: c.text,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          color: c.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: c.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: c.text,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: c.text,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: c.textMuted,
          fontSize: 13,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          color: c.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: c.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
