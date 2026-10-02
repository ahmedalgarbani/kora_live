import 'package:hive/hive.dart';
import '../../core/config/app_config.dart';
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
        return SettingsModel.fromMap(
          value,
          defaultServerUrl: AppConfig.defaultServerUrl,
        );
      } catch (_) {
        // Fall through to defaults if parsing fails
      }
    }
    // Default: Adblock and Popup Block are enabled for a clean experience.
    return const SettingsModel(
      adBlockEnabled: true,
      popupBlockEnabled: true,
      serverUrl: AppConfig.defaultServerUrl,
    );
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    await _box.put(_settingsKey, settings.toMap());
  }
}
