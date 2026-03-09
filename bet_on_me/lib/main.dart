import 'package:flutter/material.dart';
import 'package:bet_on_me/core/theme/app_theme.dart';
import 'package:bet_on_me/features/auth/presentation/screens/signin_screen.dart';

void main() {
  runApp(const BetOnMeApp());
}

class BetOnMeApp extends StatelessWidget {
  const BetOnMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BetOnMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SignInScreen(),
    );
  }
}
