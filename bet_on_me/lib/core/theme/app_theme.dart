import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.dark(
          primary: AppColors.gold,
          surface: AppColors.bg,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
      );
}
