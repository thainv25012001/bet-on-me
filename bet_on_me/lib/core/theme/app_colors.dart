import 'package:flutter/material.dart';

/// Nike-inspired static color palette.
///
/// UI stays monochromatic (black / white / grey).
/// [streakOrange] is reserved for gamification elements only —
/// it is the "product color" that carries all vibrancy.
abstract final class AppColors {
  // ── Primary ────────────────────────────────────────────────────────────────

  /// `#111111` — primary text, CTA background, nav text.
  static const Color nikeBlack = Color(0xFF111111);

  /// `#FFFFFF` — page canvas, CTA text on dark, card surfaces.
  static const Color white = Color(0xFFFFFFFF);

  // ── Surface & Background ───────────────────────────────────────────────────

  /// `#FAFAFA` — lightest surface, near-white differentiation (grey-50).
  static const Color snow = Color(0xFFFAFAFA);

  /// `#F5F5F5` — input fill, image placeholder, loading skeleton (grey-100).
  static const Color lightGray = Color(0xFFF5F5F5);

  /// `#E5E5E5` — hover state background, disabled button fill (grey-200).
  static const Color hoverGray = Color(0xFFE5E5E5);

  /// `#CACACB` — input borders, subtle divider lines (grey-300).
  static const Color borderSecondary = Color(0xFFCACACB);

  /// `#707072` — descriptive copy, metadata, timestamps (grey-500).
  static const Color textSecondary = Color(0xFF707072);

  /// `#9E9EA0` — inactive elements, unavailable options (grey-400).
  static const Color textDisabled = Color(0xFF9E9EA0);

  /// `#28282A` — primary background on dark/inverted sections (grey-800).
  static const Color darkSurface = Color(0xFF28282A);

  /// `#1F1F21` — darkest non-black surface (grey-900).
  static const Color deepCharcoal = Color(0xFF1F1F21);

  /// `#39393B` — hover state on dark backgrounds (grey-700).
  static const Color darkHover = Color(0xFF39393B);

  // ── Semantic ───────────────────────────────────────────────────────────────

  /// `#D30005` — errors, sale badges, urgent notifications (red-600).
  static const Color nikeRed = Color(0xFFD30005);

  /// `#007D48` — confirmation, availability, positive states (green-600).
  static const Color successGreen = Color(0xFF007D48);

  /// `#1151FF` — text links, informational highlights (blue-500).
  static const Color linkBlue = Color(0xFF1151FF);

  /// `rgba(39, 93, 197, 1)` — keyboard focus indicator ring.
  static const Color focusRing = Color(0xFF275DC5);

  // ── Gamification ───────────────────────────────────────────────────────────

  /// `#FF5000` — streak badges and progress indicators (orange-400).
  ///
  /// This is the only expressive color in the UI; everything else is greyscale.
  static const Color streakOrange = Color(0xFFFF5000);
}

/// Adaptive colors that resolve correctly in both light and dark themes.
///
/// Access via [AppThemeColors.of].
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.bg,
    required this.surface,
    required this.surfaceVariant,
    required this.text,
    required this.textMuted,
    required this.border,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color surfaceVariant;
  final Color text;
  final Color textMuted;
  final Color border;
  final bool isDark;

  /// Nike light theme — white canvas, monochromatic.
  static const light = AppThemeColors(
    bg:             AppColors.white,
    surface:        AppColors.snow,
    surfaceVariant: AppColors.lightGray,
    text:           AppColors.nikeBlack,
    textMuted:      AppColors.textSecondary,
    border:         AppColors.borderSecondary,
    isDark:         false,
  );

  /// Nike dark theme — #111111 canvas, dark grey surfaces.
  static const dark = AppThemeColors(
    bg:             AppColors.nikeBlack,
    surface:        AppColors.darkSurface,
    surfaceVariant: AppColors.deepCharcoal,
    text:           AppColors.white,
    textMuted:      AppColors.textSecondary,
    border:         AppColors.darkHover,
    isDark:         true,
  );

  /// Convenience accessor — throws if extension is missing from theme.
  static AppThemeColors of(BuildContext context) =>
      Theme.of(context).extension<AppThemeColors>()!;

  @override
  AppThemeColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceVariant,
    Color? text,
    Color? textMuted,
    Color? border,
    bool? isDark,
  }) =>
      AppThemeColors(
        bg:             bg             ?? this.bg,
        surface:        surface        ?? this.surface,
        surfaceVariant: surfaceVariant ?? this.surfaceVariant,
        text:           text           ?? this.text,
        textMuted:      textMuted      ?? this.textMuted,
        border:         border         ?? this.border,
        isDark:         isDark         ?? this.isDark,
      );

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bg:             Color.lerp(bg,             other.bg,             t)!,
      surface:        Color.lerp(surface,        other.surface,        t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      text:           Color.lerp(text,           other.text,           t)!,
      textMuted:      Color.lerp(textMuted,      other.textMuted,      t)!,
      border:         Color.lerp(border,         other.border,         t)!,
      isDark:         t < 0.5 ? isDark : other.isDark,
    );
  }
}
