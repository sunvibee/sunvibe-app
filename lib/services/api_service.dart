import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const _timeout = Duration(seconds: 15);
  final String? token;

  ApiService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, dynamic> _decode(http.Response r) {
    try {
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response', statusCode: r.statusCode);
    }
  }

  void _assertOk(http.Response r, Map<String, dynamic> body) {
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw ApiException(
        body['error']?.toString() ?? 'Request failed',
        statusCode: r.statusCode,
      );
    }
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    String? wifiSsid,
    String? wifiPassword,
  }) async {
    try {
      final r = await http
          .post(
            _uri('/api/auth/register'),
            headers: _headers,
            body: jsonEncode({
              'username': username,
              'password': password,
              'wifi_ssid': wifiSsid,
              'wifi_password': wifiPassword,
            }),
          )
          .timeout(_timeout);
      final body = _decode(r);
      _assertOk(r, body);
      return body;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out — check your connection');
    } catch (e) {
      throw ApiException('Something went wrong: $e');
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final r = await http
          .post(
            _uri('/api/auth/login'),
            headers: _headers,
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);
      final body = _decode(r);
      _assertOk(r, body);
      return body;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out — check your connection');
    } catch (e) {
      throw ApiException('Something went wrong: $e');
    }
  }

  // ── User ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMe() async {
    final r = await http
        .get(_uri('/api/user/me'), headers: _headers)
        .timeout(_timeout);
    final body = _decode(r);
    _assertOk(r, body);
    return body;
  }

  Future<void> updateWifi({
    required String wifiSsid,
    required String wifiPassword,
  }) async {
    final r = await http
        .put(
          _uri('/api/user/wifi'),
          headers: _headers,
          body: jsonEncode({'wifi_ssid': wifiSsid, 'wifi_password': wifiPassword}),
        )
        .timeout(_timeout);
    final body = _decode(r);
    _assertOk(r, body);
  }

  // ── Robots ──────────────────────────────────────────────────────────────────

  /// Checks that the robot UID exists in the pre-registered registry.
  /// Throws [ApiException] with a user-facing message if not found.
  Future<Map<String, dynamic>> validateRobot(String robotUid) async {
    try {
      final r = await http
          .get(_uri('/api/robots/validate/$robotUid'), headers: _headers)
          .timeout(_timeout);
      final body = _decode(r);
      _assertOk(r, body);
      return body;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out — check your connection');
    } catch (e) {
      throw ApiException('Something went wrong: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRobots() async {
    final r = await http
        .get(_uri('/api/robots'), headers: _headers)
        .timeout(_timeout);
    if (r.statusCode == 200) {
      return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    }
    throw ApiException('Failed to load robots', statusCode: r.statusCode);
  }

  Future<Map<String, dynamic>> registerRobot({
    required String robotUid,
    String? robotName,
  }) async {
    final r = await http
        .post(
          _uri('/api/robots'),
          headers: _headers,
          body: jsonEncode({'robot_uid': robotUid, 'robot_name': robotName}),
        )
        .timeout(_timeout);
    final body = _decode(r);
    _assertOk(r, body);
    return body;
  }

  Future<void> removeRobot(String robotUid) async {
    final r = await http
        .delete(_uri('/api/robots/$robotUid'), headers: _headers)
        .timeout(_timeout);
    if (r.statusCode != 200 && r.statusCode != 204) {
      final body = _decode(r);
      throw ApiException(
        body['error']?.toString() ?? 'Failed to remove robot',
        statusCode: r.statusCode,
      );
    }
  }

  // ── Sensor data ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSensorData(String robotUid) async {
    final r = await http
        .get(_uri('/api/sensor-data/$robotUid'), headers: _headers)
        .timeout(_timeout);
    if (r.statusCode == 200) {
      return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
    }
    throw ApiException('Failed to load sensor data', statusCode: r.statusCode);
  }

  Future<void> storeSensorData({
    required String robotUid,
    required Map<String, dynamic> data,
  }) async {
    final r = await http
        .post(
          _uri('/api/sensor-data'),
          headers: _headers,
          body: jsonEncode({'robot_uid': robotUid, 'data': data}),
        )
        .timeout(_timeout);
    final body = _decode(r);
    _assertOk(r, body);
  }
}
