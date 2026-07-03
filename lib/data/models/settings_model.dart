import '../../domain/entities/settings.dart';

class SettingsModel extends AppSettings {
  const SettingsModel({
    required super.adBlockEnabled,
    required super.popupBlockEnabled,
  });

  factory SettingsModel.fromEntity(AppSettings entity) {
    return SettingsModel(
      adBlockEnabled: entity.adBlockEnabled,
      popupBlockEnabled: entity.popupBlockEnabled,
    );
  }

  factory SettingsModel.fromMap(Map<dynamic, dynamic> map) {
    return SettingsModel(
      adBlockEnabled: (map['adBlockEnabled'] as bool?) ?? true,
      popupBlockEnabled: (map['popupBlockEnabled'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adBlockEnabled': adBlockEnabled,
      'popupBlockEnabled': popupBlockEnabled,
    };
  }
}
