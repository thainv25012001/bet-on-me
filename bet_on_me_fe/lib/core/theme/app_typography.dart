import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nike-inspired typography system.
///
/// Display text uses Barlow Condensed (a free substitute for Nike Futura ND).
/// Body and UI text uses the platform system font (Helvetica/Arial).
abstract final class AppTypography {
  /// 96px condensed uppercase — hero headlines only.
  static TextStyle display(Color color) => GoogleFonts.barlowCondensed(
        fontSize: 96,
        fontWeight: FontWeight.w700,
        height: 0.90,
        color: color,
      );

  /// 32px medium — primary section titles.
  static TextStyle heading1(Color color) => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.20,
        color: color,
      );

  /// 24px medium — subsection titles.
  static TextStyle heading2(Color color) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.20,
        color: color,
      );

  /// 16px medium — card titles, heading 3.
  static TextStyle heading3(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.50,
        color: color,
      );

  /// 16px regular — product descriptions, standard body.
  static TextStyle body(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.75,
        color: color,
      );

  /// 16px medium — emphasized body text.
  static TextStyle bodyMedium(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.75,
        color: color,
      );

  /// 16px medium — navigation links.
  static TextStyle link(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.75,
        color: color,
      );

  /// 14px medium — footer/utility links.
  static TextStyle linkSmall(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.86,
        color: color,
      );

  /// 16px medium — CTA button text.
  static TextStyle button(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.50,
        color: color,
      );

  /// 14px medium — secondary button text.
  static TextStyle buttonSmall(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.50,
        color: color,
      );

  /// 14px medium — price labels, captions.
  static TextStyle caption(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.50,
        color: color,
      );

  /// 12px medium — timestamps, secondary metadata.
  static TextStyle small(Color color) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.50,
        color: color,
      );

  /// 12px regular — legal text, fine print.
  static TextStyle tiny(Color color) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.50,
        color: color,
      );

  /// Maps the Nike type scale to Flutter's [TextTheme].
  ///
  /// Pass the foreground [textColor] appropriate for the current brightness.
  static TextTheme buildTextTheme(Color textColor, Color mutedColor) {
    return TextTheme(
      // displayLarge  → Nike display (96px Barlow Condensed)
      displayLarge: display(textColor),

      // displayMedium → heading 1 (32px)
      displayMedium: heading1(textColor),

      // displaySmall  → heading 2 (24px)
      displaySmall: heading2(textColor),

      // headlineMedium → heading 3 (16px/500)
      headlineMedium: heading3(textColor),

      // titleLarge    → body medium (16px/500)
      titleLarge: bodyMedium(textColor),

      // titleMedium   → link (16px/500)
      titleMedium: link(textColor),

      // titleSmall    → link small (14px/500)
      titleSmall: linkSmall(textColor),

      // bodyLarge     → body (16px/400)
      bodyLarge: body(textColor),

      // bodyMedium    → button (16px/500)
      bodyMedium: button(textColor),

      // bodySmall     → caption (14px/500)
      bodySmall: caption(mutedColor),

      // labelLarge    → button small (14px/500)
      labelLarge: buttonSmall(textColor),

      // labelMedium   → small (12px/500)
      labelMedium: small(mutedColor),

      // labelSmall    → tiny (12px/400)
      labelSmall: tiny(mutedColor),
    );
  }
}
