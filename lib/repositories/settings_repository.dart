import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsRepository {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _kPush = 'settings_push_notifications';
  static const String _kEmail = 'settings_email_notifications';
  static const String _kSms = 'settings_sms_notifications';
  static const String _kSystemAlerts = 'settings_system_alerts';
  static const String _kMaintenanceAlerts = 'settings_maintenance_alerts';

  const SettingsRepository();

  Future<bool> _readBool(String key, {required bool fallback}) async {
    final String? raw = await _storage.read(key: key);
    if (raw == null) return fallback;
    final String v = raw.trim().toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
    return fallback;
  }

  Future<void> _writeBool(String key, bool value) async {
    await _storage.write(key: key, value: value ? 'true' : 'false');
  }

  Future<bool> getPushNotificationsEnabled() async {
    return _readBool(_kPush, fallback: true);
  }

  Future<void> setPushNotificationsEnabled(bool enabled) async {
    await _writeBool(_kPush, enabled);
  }

  Future<bool> getEmailNotificationsEnabled() async {
    return _readBool(_kEmail, fallback: true);
  }

  Future<void> setEmailNotificationsEnabled(bool enabled) async {
    await _writeBool(_kEmail, enabled);
  }

  Future<bool> getSmsNotificationsEnabled() async {
    return _readBool(_kSms, fallback: false);
  }

  Future<void> setSmsNotificationsEnabled(bool enabled) async {
    await _writeBool(_kSms, enabled);
  }

  Future<bool> getSystemAlertsEnabled() async {
    return _readBool(_kSystemAlerts, fallback: true);
  }

  Future<void> setSystemAlertsEnabled(bool enabled) async {
    await _writeBool(_kSystemAlerts, enabled);
  }

  Future<bool> getMaintenanceAlertsEnabled() async {
    return _readBool(_kMaintenanceAlerts, fallback: true);
  }

  Future<void> setMaintenanceAlertsEnabled(bool enabled) async {
    await _writeBool(_kMaintenanceAlerts, enabled);
  }
}
