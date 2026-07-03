import 'package:hive/hive.dart';
import '../models/settings_model.dart';

abstract class SettingsLocalDataSource {
  SettingsModel getSettings();
  Future<void> saveSettings(SettingsModel settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box _box;
  static const String _settingsKey = 'app_settings';

  SettingsLocalDataSourceImpl(this._box);

  @override
  SettingsModel getSettings() {
    final value = _box.get(_settingsKey);
    if (value is Map) {
      try {
        return SettingsModel.fromMap(value);
      } catch (_) {
        // Return default settings if parsing fails
      }
    }
    // Default: Adblock and Popup Block are enabled by default for a clean user experience!
    return const SettingsModel(adBlockEnabled: true, popupBlockEnabled: true);
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    await _box.put(_settingsKey, settings.toMap());
  }
}
