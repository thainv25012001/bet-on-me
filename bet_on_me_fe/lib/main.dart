import 'package:flutter/material.dart';
import 'package:bet_on_me/core/navigation/app_navigator.dart';
import 'package:bet_on_me/core/theme/app_theme.dart';
import 'package:bet_on_me/features/auth/presentation/screens/signin_screen.dart';

/// Global theme-mode notifier — toggled from the settings drawer.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

void main() {
  runApp(const BetOnMeApp());
}

class BetOnMeApp extends StatelessWidget {
  const BetOnMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, child) => MaterialApp(
        title: 'BetOnMe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        navigatorKey: AppNavigator.navigatorKey,
        home: const SignInScreen(),
      ),
    );
  }
}
