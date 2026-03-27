import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:bet_on_me/features/auth/data/auth_service.dart';

/// Connects to the backend's WebSocket job-status endpoint and returns a
/// [Stream] that emits exactly one message (the completion payload) then
/// closes.
///
/// Usage:
/// ```dart
/// final stream = await GoalWsService().watchJob(jobId);
/// stream.listen((payload) {
///   if (payload['status'] == 'success') { ... }
/// });
/// ```
class GoalWsService {
  final _authService = AuthService();
  WebSocketChannel? _channel;

  /// Opens a WebSocket to ``ws://localhost:8000/ws/jobs/{jobId}?token=…``.
  ///
  /// Returns a [Stream] of decoded JSON maps.  Listen for one event then
  /// cancel — the server closes its end after sending the result.
  Future<Stream<Map<String, dynamic>>> watchJob(String jobId) async {
    final token = await _authService.getStoredToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final uri = Uri.parse(
      'ws://localhost:8000/ws/jobs/$jobId?token=$token',
    );
    _channel = WebSocketChannel.connect(uri);
    // Surface connection errors (bad token, job not found) as stream errors.
    await _channel!.ready;
    return _channel!.stream.map(
      (raw) => jsonDecode(raw as String) as Map<String, dynamic>,
    );
  }

  void close() {
    _channel?.sink.close();
    _channel = null;
  }
}
