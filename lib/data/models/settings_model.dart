import '../../domain/entities/settings.dart';

class SettingsModel extends AppSettings {
  const SettingsModel({
    required super.adBlockEnabled,
    required super.popupBlockEnabled,
    super.serverUrl,
    super.autoSync,
    super.keepScreenOn,
  });

  factory SettingsModel.fromEntity(AppSettings entity) {
    return SettingsModel(
      adBlockEnabled: entity.adBlockEnabled,
      popupBlockEnabled: entity.popupBlockEnabled,
      serverUrl: entity.serverUrl,
      autoSync: entity.autoSync,
      keepScreenOn: entity.keepScreenOn,
    );
  }

  factory SettingsModel.fromMap(
    Map<dynamic, dynamic> map, {
    String defaultServerUrl = '',
  }) {
    return SettingsModel(
      adBlockEnabled: (map['adBlockEnabled'] as bool?) ?? true,
      popupBlockEnabled: (map['popupBlockEnabled'] as bool?) ?? true,
      serverUrl: (map['serverUrl'] as String?) ?? defaultServerUrl,
      autoSync: (map['autoSync'] as bool?) ?? true,
      keepScreenOn: (map['keepScreenOn'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adBlockEnabled': adBlockEnabled,
      'popupBlockEnabled': popupBlockEnabled,
      'serverUrl': serverUrl,
      'autoSync': autoSync,
      'keepScreenOn': keepScreenOn,
    };
  }
}
