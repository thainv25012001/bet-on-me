import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bet_on_me/core/navigation/app_navigator.dart';

const String kBaseUrl = 'http://localhost:8000';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? code;

  const ApiException(this.message, this.statusCode, {this.code});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class TokenExpiredException extends ApiException {
  const TokenExpiredException()
      : super(
          'Your session has expired. Please log in again.',
          401,
          code: 'TOKEN_EXPIRED',
        );
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

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final response = await http.patch(
      uri,
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
  }) async {
    final uri = Uri.parse('$kBaseUrl$path');
    final response =
        await http.delete(uri, headers: _headers(token: token));
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final errorCode = decoded['error']?['code'] as String?;
    final errorMessage =
        decoded['error']?['message'] as String? ?? 'Something went wrong';

    if (errorCode == 'TOKEN_EXPIRED') {
      AppNavigator.redirectToSessionExpired();
      throw const TokenExpiredException();
    }

    throw ApiException(errorMessage, response.statusCode, code: errorCode);
  }
}
