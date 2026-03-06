import 'package:flutter/material.dart';
import 'screens/signin_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFFB800),
          surface: const Color(0xFF0A0A14),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
        fontFamily: 'Roboto',
      ),
      home: const SignInScreen(),
    );
  }
}
