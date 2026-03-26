import 'package:flutter/material.dart';
import 'package:bet_on_me/features/auth/presentation/screens/session_expired_screen.dart';

/// Holds the single [NavigatorState] key used by [MaterialApp].
/// [ApiClient] calls [redirectToSessionExpired] from anywhere in the app
/// when the server returns TOKEN_EXPIRED.
class AppNavigator {
  AppNavigator._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static void redirectToSessionExpired() {
    final state = navigatorKey.currentState;
    if (state == null) return;
    // Avoid pushing if already on SessionExpiredScreen.
    if (state.context.widget.runtimeType == SessionExpiredScreen) return;
    state.pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => const SessionExpiredScreen()),
      (_) => false,
    );
  }
}
