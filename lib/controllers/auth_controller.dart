import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthRepository _repository;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _myCompany;
  Map<String, dynamic>? _activeCompany;

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

      _profile = await _repository.getProfile();
      _myCompany = await _repository.getMyCompany();
      _activeCompany ??= _myCompany;
      _isAuthenticated = true;
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
        _isAuthenticated = true;
      }
      return ok;
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
    try {
      _myCompany = await _repository.getMyCompany();
      _activeCompany ??= _myCompany;
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }
}
