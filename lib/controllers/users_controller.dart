import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UsersController extends ChangeNotifier {
  final UserRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _users = const <UserModel>[];

  UsersController({required UserRepository repository}) : _repository = repository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get users => _users;

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _repository.listCreatedByMe();
    } catch (e) {
      _users = const <UserModel>[];
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load();
  }
}
