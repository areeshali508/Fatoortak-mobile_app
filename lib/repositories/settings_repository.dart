class SettingsRepository {
  const SettingsRepository();

  Future<bool> getPushNotificationsEnabled() async {
    return true;
  }

  Future<void> setPushNotificationsEnabled(bool enabled) async {}
}
