import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClientException implements Exception {
  final String message;
  final int? statusCode;

  const ApiClientException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  Future<Map<String, dynamic>> postForm(
    String path, {
    Map<String, String>? queryParameters,
    required Map<String, String> body,
    bool auth = true,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    _debugLog('POST $uri');
    _debugLog('POST FORM BODY $body');

    final String encoded = body.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    final http.Response res = await _client
        .post(
          uri,
          headers: await _headers(
            auth: auth,
            contentType: 'application/x-www-form-urlencoded',
          ),
          body: encoded,
        )
        .timeout(const Duration(seconds: 20));

    _debugLog('POST STATUS ${res.statusCode}');
    _debugLog('POST RESPONSE ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Object? decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const ApiClientException('Invalid response');
    }

    throw ApiClientException(_extractMessage(res), statusCode: res.statusCode);
  }

  String _extractMessage(http.Response res) {
    final String raw = res.body.trim();
    if (raw.isEmpty) {
      return 'Request failed (${res.statusCode})';
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final Object? msg = decoded['message'] ?? decoded['error'];
        if (msg is String && msg.trim().isNotEmpty) {
          return msg;
        }
      }
    } catch (_) {
      // ignore
    }

    return raw;
  }

  Future<Map<String, String>> _headers({
    bool auth = true,
    String contentType = 'application/json',
  }) async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': contentType,
      'Accept': 'application/json',
    };

    if (auth) {
      final String? token = await tokenProvider();
      if (token == null || token.trim().isEmpty) {
        throw const ApiClientException('Unauthorized - No token provided');
      }
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final Uri base = Uri.parse(baseUrl);
    final Uri next = base.resolve(path);
    if (queryParameters == null || queryParameters.isEmpty) {
      return next;
    }
    return next.replace(queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    bool auth = true,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    _debugLog('GET $uri');
    final http.Response res = await _client
        .get(uri, headers: await _headers(auth: auth))
        .timeout(const Duration(seconds: 20));
    _debugLog('GET STATUS ${res.statusCode}');
    _debugLog('GET RESPONSE ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Object? decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const ApiClientException('Invalid response');
    }

    throw ApiClientException(_extractMessage(res), statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? queryParameters,
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    _debugLog('POST $uri');
    _debugLog('POST BODY ${jsonEncode(body)}');
    final http.Response res = await _client
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    _debugLog('POST STATUS ${res.statusCode}');
    _debugLog('POST RESPONSE ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Object? decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const ApiClientException('Invalid response');
    }

    throw ApiClientException(_extractMessage(res), statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, String>? queryParameters,
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    _debugLog('PATCH $uri');
    _debugLog('PATCH BODY ${jsonEncode(body)}');
    final http.Response res = await _client
        .patch(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    _debugLog('PATCH STATUS ${res.statusCode}');
    _debugLog('PATCH RESPONSE ${res.body}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Object? decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const ApiClientException('Invalid response');
    }

    throw ApiClientException(_extractMessage(res), statusCode: res.statusCode);
  }
}
