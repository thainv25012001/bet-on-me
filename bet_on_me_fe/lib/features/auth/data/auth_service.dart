import 'package:shared_preferences/shared_preferences.dart';
import 'package:bet_on_me/core/services/api_client.dart';

const String _tokenKey = 'auth_token';

class AuthService {
  Future<String> login({required String email, required String password}) async {
    final response = await ApiClient.post(
      '/api/v1/auth/login',
      {'email': email, 'password': password},
    );
    final token = response['data']['access_token'] as String;
    await _saveToken(token);
    return token;
  }

  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await ApiClient.post(
      '/api/v1/auth/register',
      {'name': name, 'email': email, 'password': password},
    );
    final token = response['data']['access_token'] as String;
    await _saveToken(token);
    return token;
  }

  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, dynamic>> getMe() async {
    final token = await getStoredToken();
    final response = await ApiClient.get('/api/v1/users/me', token: token);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Requests a password-reset token for [email].
  /// Returns the response data map (contains `reset_token` in dev mode).
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await ApiClient.post(
      '/api/v1/auth/forgot-password',
      {'email': email},
    );
    return response['data'] as Map<String, dynamic>;
  }

  /// Resets the password using a [token] from [forgotPassword].
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await ApiClient.post(
      '/api/v1/auth/reset-password',
      {'token': token, 'new_password': newPassword},
    );
  }

  /// Changes the password for the currently signed-in user.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final authToken = await getStoredToken();
    await ApiClient.post(
      '/api/v1/users/me/change-password',
      {'current_password': currentPassword, 'new_password': newPassword},
      token: authToken,
    );
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}
