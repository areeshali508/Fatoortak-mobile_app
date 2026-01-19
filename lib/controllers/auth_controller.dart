import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthRepository _repository;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  AuthController({required AuthRepository repository}) : _repository = repository;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  void updateRepository(AuthRepository repository) {
    _repository = repository;
  }

  Future<bool> signIn({
    required String usernameOrEmail,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final bool ok = await _repository.signIn(
        usernameOrEmail: usernameOrEmail,
        password: password,
      );
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
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final bool ok = await _repository.signUp(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      if (ok) {
        _isAuthenticated = true;
      }
      return ok;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> sendPasswordResetLink({required String email}) async {
    await _repository.sendPasswordResetLink(email: email);
  }
}
