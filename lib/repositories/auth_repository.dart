import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;

  const AuthApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthRepository {
  const AuthRepository();

  static const String _baseUrl = 'https://e-invoicing-solution-backend.vercel.app';
  static const String _tokenStorageKey = 'auth_jwt_token';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static String? _inMemoryToken;

  static const Duration _timeout = Duration(seconds: 20);

  Future<Map<String, String>> _authHeaders() async {
    final String? token = _inMemoryToken ??
        await _secureStorage.read(key: _tokenStorageKey);
    if (token == null || token.trim().isEmpty) {
      throw const AuthApiException('Unauthorized - No token provided');
    }
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  String _extractErrorMessage(http.Response res) {
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

        final Object? errors = decoded['errors'] ?? decoded['details'];
        if (errors is String && errors.trim().isNotEmpty) {
          return errors;
        }
        if (errors is List) {
          final List<String> parts = errors
              .map((Object? e) => e?.toString().trim() ?? '')
              .where((String s) => s.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            return parts.join('\n');
          }
        }
        if (errors is Map) {
          return jsonEncode(errors);
        }
      }
    } catch (_) {
      // ignore
    }

    return raw;
  }

  Future<bool> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/user/login');
    final Map<String, dynamic> payload = <String, dynamic>{
      'email': usernameOrEmail.trim(),
      'password': password,
    };
    try {
      _debugLog('LOGIN POST $uri');
      _debugLog('LOGIN BODY ${jsonEncode(payload)}');
      final Stopwatch sw = Stopwatch()..start();
      late final http.Response res;
      try {
        res = await http
            .post(
              uri,
              headers: <String, String>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(_timeout);
      } on TimeoutException {
        throw const AuthApiException('Request timed out', statusCode: 408);
      } finally {
        sw.stop();
        _debugLog('LOGIN TIME ${sw.elapsedMilliseconds}ms');
      }

      _debugLog('LOGIN STATUS ${res.statusCode}');
      _debugLog('LOGIN RESPONSE ${res.body}');

      if (res.statusCode == 200) {
        final String raw = res.body.trim();
        if (raw.isNotEmpty) {
          try {
            final Object? decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              final Object? token = decoded['token'];
              if (token is String && token.trim().isNotEmpty) {
                _inMemoryToken = token.trim();
                await _secureStorage.write(
                  key: _tokenStorageKey,
                  value: token.trim(),
                );
              }
            }
          } catch (_) {
            // ignore
          }
        }
        return true;
      }

      throw AuthApiException(
        _extractErrorMessage(res),
        statusCode: res.statusCode,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      throw const AuthApiException('First name and last name are required');
    }
    final Uri uri = Uri.parse('$_baseUrl/user/signup');
    final Map<String, dynamic> payload = <String, dynamic>{
      'email': email,
      'password': password,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
    };
    try {
      _debugLog('SIGNUP POST $uri');
      _debugLog('SIGNUP BODY ${jsonEncode(payload)}');
      final Stopwatch sw = Stopwatch()..start();
      late final http.Response res;
      try {
        res = await http
            .post(
              uri,
              headers: <String, String>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode(payload),
            )
            .timeout(_timeout);
      } on TimeoutException {
        throw const AuthApiException('Request timed out', statusCode: 408);
      } finally {
        sw.stop();
        _debugLog('SIGNUP TIME ${sw.elapsedMilliseconds}ms');
      }

      _debugLog('SIGNUP STATUS ${res.statusCode}');
      _debugLog('SIGNUP RESPONSE ${res.body}');

      if (res.statusCode == 201) {
        return true;
      }

      throw AuthApiException(
        _extractErrorMessage(res),
        statusCode: res.statusCode,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await GoogleSignIn().signIn();
      if (account == null) {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _inMemoryToken = null;
      await _secureStorage.delete(key: _tokenStorageKey);
      await GoogleSignIn().signOut();
    } catch (_) {
      // ignore
    }
  }

  Future<String?> getToken() async {
    return _inMemoryToken ?? _secureStorage.read(key: _tokenStorageKey);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final Uri uri = Uri.parse('$_baseUrl/user/profile');
    try {
      _debugLog('PROFILE GET $uri');
      final Stopwatch sw = Stopwatch()..start();
      late final http.Response res;
      try {
        res = await http
            .get(
              uri,
              headers: await _authHeaders(),
            )
            .timeout(_timeout);
      } on TimeoutException {
        throw const AuthApiException('Request timed out', statusCode: 408);
      } finally {
        sw.stop();
        _debugLog('PROFILE TIME ${sw.elapsedMilliseconds}ms');
      }

      _debugLog('PROFILE STATUS ${res.statusCode}');
      _debugLog('PROFILE RESPONSE ${res.body}');

      if (res.statusCode == 200) {
        final Object? decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final Object? user = decoded['user'] ?? decoded['data'];
          if (user is Map<String, dynamic>) {
            return user;
          }
          return decoded;
        }
        throw const AuthApiException('Invalid profile response');
      }

      throw AuthApiException(
        _extractErrorMessage(res),
        statusCode: res.statusCode,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyCompany() async {
    final Uri uri = Uri.parse('$_baseUrl/api/companies/me');
    try {
      _debugLog('COMPANY_ME GET $uri');
      final Stopwatch sw = Stopwatch()..start();
      late final http.Response res;
      try {
        res = await http
            .get(
              uri,
              headers: await _authHeaders(),
            )
            .timeout(_timeout);
      } on TimeoutException {
        throw const AuthApiException('Request timed out', statusCode: 408);
      } finally {
        sw.stop();
        _debugLog('COMPANY_ME TIME ${sw.elapsedMilliseconds}ms');
      }

      _debugLog('COMPANY_ME STATUS ${res.statusCode}');
      _debugLog('COMPANY_ME RESPONSE ${res.body}');

      if (res.statusCode == 200) {
        final Object? decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final Object? company = decoded['company'] ?? decoded['data'];
          if (company is Map<String, dynamic>) {
            return company;
          }
          return decoded;
        }
        throw const AuthApiException('Invalid company response');
      }

      throw AuthApiException(
        _extractErrorMessage(res),
        statusCode: res.statusCode,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<void> sendPasswordResetLink({required String email}) async {}
}
