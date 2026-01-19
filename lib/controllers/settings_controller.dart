import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  final SettingsRepository _repository;

  bool _isLoading = false;
  bool _pushNotifications = true;

  SettingsController({required SettingsRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;

  bool get pushNotifications => _pushNotifications;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _pushNotifications = await _repository.getPushNotificationsEnabled();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPushNotifications(bool v) async {
    if (v == _pushNotifications) {
      return;
    }
    _pushNotifications = v;
    notifyListeners();
    await _repository.setPushNotificationsEnabled(v);
  }
}
