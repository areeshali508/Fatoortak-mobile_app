import 'package:flutter/material.dart';
import 'dart:async';

import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthRepository _repository;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _myCompany;
  Map<String, dynamic>? _activeCompany;
  Future<void>? _sessionHydrationFuture;

  AuthController({required AuthRepository repository})
    : _repository = repository;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get profile => _profile;
  Map<String, dynamic>? get myCompany => _myCompany;
  Map<String, dynamic>? get activeCompany => _activeCompany ?? _myCompany;

  void updateLocalProfile(Map<String, dynamic> profile) {
    _profile = profile;
    notifyListeners();
  }

  String? get activeCompanyId {
    final Map<String, dynamic>? c = activeCompany;
    final String? id = (c?['_id'] ?? c?['id'])?.toString().trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  void setActiveCompany(Map<String, dynamic>? company) {
    if (company == null) {
      _activeCompany = null;
      notifyListeners();
      return;
    }
    final String? id = (company['_id'] ?? company['id'])?.toString().trim();
    if (id == null || id.isEmpty) {
      return;
    }
    _activeCompany = company;
    notifyListeners();
  }

  void updateRepository(AuthRepository repository) {
    _repository = repository;
  }

  Future<bool> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final bool ok = await _repository.signIn(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
      if (!ok) return false;

      _isAuthenticated = true;
      await _hydrateSessionContext();
      return true;
    } catch (e) {
      if (e is AuthApiException) {
        _errorMessage = e.statusCode == null
            ? e.message
            : '${e.message} (${e.statusCode})';
      } else {
        _errorMessage = 'Sign in failed';
      }
      _profile = null;
      _myCompany = null;
      _activeCompany = null;
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final bool ok = await _repository.signInWithGoogle();
      if (ok) {
        _isAuthenticated = true;
        await _hydrateSessionContext();
      }
      return ok;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final bool ok = await _repository.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      if (ok) {
        return await signIn(
          usernameOrEmail: email,
          password: password,
        );
      }
      return false;
    } catch (e) {
      if (e is AuthApiException) {
        _errorMessage = e.statusCode == null
            ? e.message
            : '${e.message} (${e.statusCode})';
      } else {
        _errorMessage = 'Sign up failed';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _isAuthenticated = false;
    _errorMessage = null;
    _profile = null;
    _myCompany = null;
    _activeCompany = null;
    _sessionHydrationFuture = null;
    notifyListeners();
  }

  Future<void> sendPasswordResetLink({required String email}) async {
    await _repository.sendPasswordResetLink(email: email);
  }

  Future<Map<String, dynamic>?> getProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _repository.getProfile();
    } catch (e) {
      if (e is AuthApiException) {
        _errorMessage = e.statusCode == null
            ? e.message
            : '${e.message} (${e.statusCode})';
      } else {
        _errorMessage = 'Failed to load profile';
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMyCompany() async {
    final Future<void>? inFlight = _sessionHydrationFuture;
    if (inFlight != null) {
      await inFlight;
      if (_myCompany != null) {
        return;
      }
    }

    try {
      _myCompany = await _repository.getMyCompany();
      _activeCompany ??= _myCompany;
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _hydrateSessionContext() {
    final Future<void>? inFlight = _sessionHydrationFuture;
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<void> future;
    future = _runSessionHydration().whenComplete(() {
      if (identical(_sessionHydrationFuture, future)) {
        _sessionHydrationFuture = null;
      }
    });
    _sessionHydrationFuture = future;
    return future;
  }

  Future<void> _runSessionHydration() async {
    try {
      final List<dynamic> res = await Future.wait<dynamic>([
        _repository.getProfile(),
        _repository.getMyCompany(),
      ]);
      if (!_isAuthenticated) {
        return;
      }
      _profile = res[0] as Map<String, dynamic>;
      _myCompany = res[1] as Map<String, dynamic>;
      _activeCompany ??= _myCompany;
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }
}
