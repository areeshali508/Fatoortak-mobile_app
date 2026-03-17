import 'dart:convert';
import 'dart:async';
import 'dart:io';

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

  final Map<String, Map<String, dynamic>> _jsonCache =
      <String, Map<String, dynamic>>{};
  final Map<String, String> _textCache = <String, String>{};

  static const Duration requestTimeout = Duration(seconds: 20);

  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  static const List<String> _sensitiveKeys = <String>[
    'zatcaCredentials',
    'privateKey',
    'csr',
    'complianceSecret',
    'productionSecret',
    'complianceCertificate',
    'productionCSID',
    'password',
    'confirmPassword',
    'avatarUrl',
    'website',
    'qrCode',
  ];

  Object? _scrubSecrets(Object? v) {
    if (v is List) {
      return v.map(_scrubSecrets).toList();
    }
    if (v is Map) {
      final Map<String, dynamic> m =
          v.map((dynamic k, dynamic v) => MapEntry(k.toString(), v));

      for (final String k in _sensitiveKeys) {
        if (m.containsKey(k)) {
          if (k == 'zatcaCredentials') {
            m[k] = <String, dynamic>{};
          } else {
            m[k] = '<redacted>';
          }
        }
      }

      return m.map((String k, dynamic v) => MapEntry(k, _scrubSecrets(v)));
    }
    return v;
  }

  String _redactSensitiveFields(String rawBody) {
    try {
      final Object? decoded = jsonDecode(rawBody);
      final Object? cleaned = _scrubSecrets(decoded);
      return jsonEncode(cleaned);
    } catch (_) {
      return rawBody;
    }
  }

  Map<String, dynamic> _sanitizeDecodedMap(Map<String, dynamic> decoded) {
    final Object? cleaned = _scrubSecrets(decoded);
    if (cleaned is Map<String, dynamic>) {
      return cleaned;
    }
    return decoded;
  }

  Future<Map<String, dynamic>> postForm(
    String path, {
    Map<String, String>? queryParameters,
    required Map<String, String> body,
    bool auth = true,
  }) async {
    final Uri uri = _buildUri(path, queryParameters);
    _debugLog('POST $uri');
    _debugLog('POST FORM BODY ${_redactSensitiveFields(jsonEncode(body))}');

    final Stopwatch sw = Stopwatch()..start();

    final String encoded = body.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    late final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: await _headers(
              auth: auth,
              contentType: 'application/x-www-form-urlencoded',
            ),
            body: encoded,
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiClientException('Request timed out', statusCode: 408);
    } on SocketException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } catch (e) {
      throw ApiClientException('Network error: $e');
    } finally {
      sw.stop();
      _debugLog('POST TIME ${sw.elapsedMilliseconds}ms $uri');
    }

    _debugLog('POST STATUS ${res.statusCode}');
    _debugLog('POST RESPONSE ${_redactSensitiveFields(res.body)}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Object? decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return _sanitizeDecodedMap(decoded);
      }
      throw const ApiClientException('Invalid response');
    }

    throw ApiClientException(_extractMessage(res), statusCode: res.statusCode);
  }

  Future<String> getText(
    String path, {
    Map<String, String>? queryParameters,
    bool auth = true,
  }) async {
    final Map<String, String>? qp = queryParameters == null
        ? (kIsWeb
            ? <String, String>{
                'cb': DateTime.now().millisecondsSinceEpoch.toString(),
              }
            : null)
        : <String, String>{
            ...queryParameters,
            if (kIsWeb) 'cb': DateTime.now().millisecondsSinceEpoch.toString(),
          };

    final Uri uri = _buildUri(path, qp);
    _debugLog('GET $uri');

    final Stopwatch sw = Stopwatch()..start();

    late final http.Response res;
    try {
      final Map<String, String> headers = await _headers(auth: auth);
      headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
      headers['Pragma'] = 'no-cache';
      headers['Expires'] = '0';
      res = await _client
          .get(uri, headers: headers)
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiClientException('Request timed out', statusCode: 408);
    } on SocketException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } catch (e) {
      throw ApiClientException('Network error: $e');
    } finally {
      sw.stop();
      _debugLog('GET TIME ${sw.elapsedMilliseconds}ms $uri');
    }

    _debugLog('GET STATUS ${res.statusCode}');
    _debugLog('GET RESPONSE ${_redactSensitiveFields(res.body)}');

    if (res.statusCode == 304) {
      final String? cached = _textCache[uri.toString()];
      if (cached != null) {
        return cached;
      }
      throw const ApiClientException('Not modified', statusCode: 304);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      _textCache[uri.toString()] = res.body;
      return res.body;
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
    final Map<String, String>? qp = queryParameters == null
        ? (kIsWeb
            ? <String, String>{
                'cb': DateTime.now().millisecondsSinceEpoch.toString(),
              }
            : null)
        : <String, String>{
            ...queryParameters,
            if (kIsWeb) 'cb': DateTime.now().millisecondsSinceEpoch.toString(),
          };

    final Uri uri = _buildUri(path, qp);
    _debugLog('GET $uri');

    final Stopwatch sw = Stopwatch()..start();

    late final http.Response res;
    try {
      final Map<String, String> headers = await _headers(auth: auth);
      headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
      headers['Pragma'] = 'no-cache';
      headers['Expires'] = '0';
      res = await _client.get(uri, headers: headers).timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiClientException('Request timed out', statusCode: 408);
    } on SocketException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } catch (e) {
      throw ApiClientException('Network error: $e');
    } finally {
      sw.stop();
      _debugLog('GET TIME ${sw.elapsedMilliseconds}ms $uri');
    }
    _debugLog('GET STATUS ${res.statusCode}');
    _debugLog('GET RESPONSE ${_redactSensitiveFields(res.body)}');

    if (res.statusCode == 304) {
      final Map<String, dynamic>? cached = _jsonCache[uri.toString()];
      if (cached != null) {
        return cached;
      }
      throw const ApiClientException('Not modified', statusCode: 304);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Object? decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final Map<String, dynamic> sanitized = _sanitizeDecodedMap(decoded);
        _jsonCache[uri.toString()] = sanitized;
        return sanitized;
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
    _debugLog('POST BODY ${_redactSensitiveFields(jsonEncode(body))}');

    final Stopwatch sw = Stopwatch()..start();

    late final http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiClientException('Request timed out', statusCode: 408);
    } on SocketException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } catch (e) {
      throw ApiClientException('Network error: $e');
    } finally {
      sw.stop();
      _debugLog('POST TIME ${sw.elapsedMilliseconds}ms $uri');
    }

    _debugLog('POST STATUS ${res.statusCode}');
    _debugLog('POST RESPONSE ${_redactSensitiveFields(res.body)}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Object? decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return _sanitizeDecodedMap(decoded);
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
    _debugLog('PATCH BODY ${_redactSensitiveFields(jsonEncode(body))}');

    final Stopwatch sw = Stopwatch()..start();

    late final http.Response res;
    try {
      res = await _client
          .patch(
            uri,
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiClientException('Request timed out', statusCode: 408);
    } on SocketException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } on http.ClientException catch (e) {
      throw ApiClientException('Network error: ${e.message}');
    } catch (e) {
      throw ApiClientException('Network error: $e');
    } finally {
      sw.stop();
      _debugLog('PATCH TIME ${sw.elapsedMilliseconds}ms $uri');
    }
    _debugLog('PATCH STATUS ${res.statusCode}');
    _debugLog('PATCH RESPONSE ${_redactSensitiveFields(res.body)}');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final Object? decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return _sanitizeDecodedMap(decoded);
      }
      throw const ApiClientException('Invalid response');
    }

    throw ApiClientException(_extractMessage(res), statusCode: res.statusCode);
  }
}
