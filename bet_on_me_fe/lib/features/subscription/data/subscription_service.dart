import 'package:bet_on_me/core/services/api_client.dart';
import 'package:bet_on_me/features/auth/data/auth_service.dart';

/// Data-layer service for subscription plans and user subscriptions.
class SubscriptionService {
  final _authService = AuthService();

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns the list of all available subscription plans.
  Future<List<Map<String, dynamic>>> listPlans() async {
    final response = await ApiClient.get('/api/v1/subscriptions/plans');
    final items = response['data'] as List<dynamic>;
    return items.cast<Map<String, dynamic>>();
  }

  /// Returns the current user's active subscription, or null.
  Future<Map<String, dynamic>?> getActiveSubscription() async {
    final token = await _authService.getStoredToken();
    final response = await ApiClient.get(
      '/api/v1/subscriptions/me',
      token: token,
    );
    return response['data'] as Map<String, dynamic>?;
  }

  /// Subscribes to the given [tier].
  Future<Map<String, dynamic>> subscribe(String tier) async {
    final token = await _authService.getStoredToken();
    final response = await ApiClient.post(
      '/api/v1/subscriptions',
      {'tier': tier, 'started_at': _today()},
      token: token,
    );
    return response['data'] as Map<String, dynamic>;
  }

  /// Cancels the current user's active subscription.
  Future<void> cancelSubscription() async {
    final token = await _authService.getStoredToken();
    await ApiClient.delete('/api/v1/subscriptions/me', token: token);
  }
}
