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

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }
}
