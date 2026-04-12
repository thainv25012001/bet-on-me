import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Nike-inspired application theme.
///
/// Flat elevation model (no card shadows), pill-shaped buttons (30px radius),
/// monochromatic UI with system Helvetica/Arial body font and
/// Barlow Condensed display font.
abstract final class AppTheme {
  static ThemeData get light => _build(AppThemeColors.light);
  static ThemeData get dark  => _build(AppThemeColors.dark);

  static ThemeData _build(AppThemeColors c) {
    final isDark = c.isDark;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    // CTA colors: black pill on light, white pill on dark.
    final ctaBg   = isDark ? AppColors.white      : AppColors.nikeBlack;
    final ctaText = isDark ? AppColors.nikeBlack  : AppColors.white;

    return ThemeData(
      brightness:              brightness,
      scaffoldBackgroundColor: c.bg,
      extensions:              [c],

      colorScheme: ColorScheme(
        brightness:  brightness,
        primary:     ctaBg,
        onPrimary:   ctaText,
        secondary:   AppColors.textSecondary,
        onSecondary: c.text,
        error:       AppColors.nikeRed,
        onError:     AppColors.white,
        surface:     c.surface,
        onSurface:   c.text,
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:      c.bg,
        foregroundColor:      c.text,
        elevation:            0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.text),
        titleTextStyle: AppTypography.heading3(c.text),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // ── NavigationBar ─────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:  c.surface,
        indicatorColor:   AppColors.hoverGray,
        elevation:        0,
        height:           68,
        labelBehavior:    NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.text
                : c.textMuted,
            size: 22,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.small(
            states.contains(WidgetState.selected) ? c.text : c.textMuted,
          ),
        ),
      ),

      // ── Elevated Button (primary CTA — pill shaped) ───────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:         ctaBg,
          foregroundColor:         ctaText,
          disabledBackgroundColor: AppColors.hoverGray,
          disabledForegroundColor: AppColors.textDisabled,
          elevation:    0,
          shadowColor:  Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: AppTypography.button(ctaText),
        ),
      ),

      // ── Text Button (links, secondary actions) ────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.text,
          textStyle:       AppTypography.linkSmall(c.text),
        ),
      ),

      // ── Outlined Button (secondary CTA) ──────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          side: BorderSide(color: AppColors.borderSecondary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: const Size(double.infinity, 52),
          textStyle: AppTypography.button(c.text),
        ),
      ),

      // ── Input Decoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:    true,
        fillColor: AppColors.lightGray,
        hintStyle: AppTypography.body(AppColors.textSecondary),
        labelStyle: AppTypography.caption(AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.white : AppColors.nikeBlack,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.nikeRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.nikeRed,
            width: 1.5,
          ),
        ),
        errorStyle: AppTypography.small(AppColors.nikeRed),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:     c.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin:    EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Drawer ────────────────────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: c.surface,
        elevation: 0,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color:     c.border,
        thickness: 1,
        space:     1,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        elevation:  0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
        ),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentTextStyle: AppTypography.body(c.text),
      ),

      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color:            isDark ? AppColors.white : AppColors.nikeBlack,
        linearTrackColor: AppColors.hoverGray,
      ),

      // ── Text ──────────────────────────────────────────────────────────────
      textTheme: AppTypography.buildTextTheme(c.text, c.textMuted),

      // ── Focus ─────────────────────────────────────────────────────────────
      focusColor: AppColors.focusRing,
    );
  }
}
