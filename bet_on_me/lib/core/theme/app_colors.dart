import 'package:flutter/material.dart';

/// Semantic accent colors — same in both themes.
abstract final class AppColors {
  static const Color gold       = Color(0xFFF5A623);
  static const Color goldDim    = Color(0x26F5A623);
  static const Color success    = Color(0xFF34C759);
  static const Color successDim = Color(0x2034C759);
  static const Color error      = Color(0xFFFF3B30);
  static const Color streak     = Color(0xFFFF6B35);
  static const Color streakDim  = Color(0x33FF6B35);

  // Dark-mode static values kept for backward compat with
  // screens not yet migrated to AppThemeColors.
  static const Color bg        = Color(0xFF0D0D1A);
  static const Color surface   = Color(0xFF161625);
  static const Color textMuted = Color(0xFF7B7B9E);
  static const Color border    = Color(0xFF252542);
}

/// Adaptive colors that change between light and dark themes.
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
    required this.cardShadow,
    required this.isDark,
  });

  final Color bg;
  final Color surface;
  final Color surfaceVariant;
  final Color text;
  final Color textMuted;
  final Color border;
  final Color cardShadow;
  final bool isDark;

  static const dark = AppThemeColors(
    bg:             Color(0xFF0D0D1A),
    surface:        Color(0xFF161625),
    surfaceVariant: Color(0xFF1E1E30),
    text:           Color(0xFFFFFFFF),
    textMuted:      Color(0xFF7B7B9E),
    border:         Color(0xFF252542),
    cardShadow:     Color(0x40000000),
    isDark:         true,
  );

  static const light = AppThemeColors(
    bg:             Color(0xFFF2F2F7),
    surface:        Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F0F5),
    text:           Color(0xFF1C1C2E),
    textMuted:      Color(0xFF8E8EAA),
    border:         Color(0xFFE5E5EF),
    cardShadow:     Color(0x14000000),
    isDark:         false,
  );

  /// Convenience accessor — throws if extension is missing.
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
    Color? cardShadow,
    bool? isDark,
  }) =>
      AppThemeColors(
        bg:             bg             ?? this.bg,
        surface:        surface        ?? this.surface,
        surfaceVariant: surfaceVariant ?? this.surfaceVariant,
        text:           text           ?? this.text,
        textMuted:      textMuted      ?? this.textMuted,
        border:         border         ?? this.border,
        cardShadow:     cardShadow     ?? this.cardShadow,
        isDark:         isDark         ?? this.isDark,
      );

  @override
  AppThemeColors lerp(
    ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      bg:             Color.lerp(bg,             other.bg,             t)!,
      surface:        Color.lerp(surface,        other.surface,        t)!,
      surfaceVariant:
          Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      text:           Color.lerp(text,           other.text,           t)!,
      textMuted:      Color.lerp(textMuted,      other.textMuted,      t)!,
      border:         Color.lerp(border,         other.border,         t)!,
      cardShadow:     Color.lerp(cardShadow,     other.cardShadow,     t)!,
      isDark:         t < 0.5 ? isDark : other.isDark,
    );
  }
}
