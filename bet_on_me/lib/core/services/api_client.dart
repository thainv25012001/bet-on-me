import 'dart:convert';
import 'package:http/http.dart' as http;

const String kBaseUrl = 'http://localhost:8000';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final response = await http.post(
      uri,
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    String? token,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final response = await http.get(uri, headers: _headers(token: token));
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final errorMessage =
        decoded['error']?['message'] as String? ?? 'Something went wrong';
    throw ApiException(errorMessage, response.statusCode);
  }
}
