import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';

class SystemSettingsController extends ChangeNotifier {
  final SettingsRepository _repository;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  bool _systemAlerts = true;
  final bool _securityAlerts = true;
  bool _maintenanceAlerts = true;

  bool _dirty = false;

  SystemSettingsController({required SettingsRepository repository})
      : _repository = repository;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  bool get emailNotifications => _emailNotifications;
  bool get smsNotifications => _smsNotifications;
  bool get pushNotifications => _pushNotifications;
  bool get systemAlerts => _systemAlerts;
  bool get securityAlerts => _securityAlerts;
  bool get maintenanceAlerts => _maintenanceAlerts;
  bool get isDirty => _dirty;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _emailNotifications = await _repository.getEmailNotificationsEnabled();
      _smsNotifications = await _repository.getSmsNotificationsEnabled();
      _pushNotifications = await _repository.getPushNotificationsEnabled();
      _systemAlerts = await _repository.getSystemAlertsEnabled();
      _maintenanceAlerts = await _repository.getMaintenanceAlertsEnabled();
      _dirty = false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setEmailNotifications(bool v) {
    if (v == _emailNotifications) return;
    _emailNotifications = v;
    _dirty = true;
    notifyListeners();
  }

  void setSmsNotifications(bool v) {
    if (v == _smsNotifications) return;
    _smsNotifications = v;
    _dirty = true;
    notifyListeners();
  }

  void setPushNotifications(bool v) {
    if (v == _pushNotifications) return;
    _pushNotifications = v;
    _dirty = true;
    notifyListeners();
  }

  void setSystemAlerts(bool v) {
    if (v == _systemAlerts) return;
    _systemAlerts = v;
    _dirty = true;
    notifyListeners();
  }

  void setMaintenanceAlerts(bool v) {
    if (v == _maintenanceAlerts) return;
    _maintenanceAlerts = v;
    _dirty = true;
    notifyListeners();
  }

  Future<bool> saveAll() async {
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.setEmailNotificationsEnabled(_emailNotifications);
      await _repository.setSmsNotificationsEnabled(_smsNotifications);
      await _repository.setPushNotificationsEnabled(_pushNotifications);
      await _repository.setSystemAlertsEnabled(_systemAlerts);
      await _repository.setMaintenanceAlertsEnabled(_maintenanceAlerts);
      _dirty = false;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
