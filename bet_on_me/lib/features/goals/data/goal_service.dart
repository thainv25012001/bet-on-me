import 'package:bet_on_me/core/services/api_client.dart';
import 'package:bet_on_me/features/auth/data/auth_service.dart';

class GoalService {
  final _authService = AuthService();

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>> createGoal({
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime targetDate,
    required int stakePerDay,
  }) async {
    final token = await _authService.getStoredToken();
    final body = <String, dynamic>{
      'title': title,
      'start_date': _formatDate(startDate),
      'target_date': _formatDate(targetDate),
      'stake_per_day': stakePerDay,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response =
        await ApiClient.post('/api/v1/goals', body, token: token);
    return response['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listGoals() async {
    final token = await _authService.getStoredToken();
    final response = await ApiClient.get(
      '/api/v1/goals?page=1&page_size=20',
      token: token,
    );
    final items = response['data']['items'] as List<dynamic>;
    return items.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getGoalPlan(String goalId) async {
    final token = await _authService.getStoredToken();
    final response = await ApiClient.get(
      '/api/v1/goals/$goalId/plans?page=1&page_size=1',
      token: token,
    );
    final items = response['data']['items'] as List<dynamic>;
    if (items.isEmpty) {
      throw Exception('No plan found for goal $goalId');
    }
    return items.first as Map<String, dynamic>;
  }
}
