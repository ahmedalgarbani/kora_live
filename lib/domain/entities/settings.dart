class AppSettings {
  final bool adBlockEnabled;
  final bool popupBlockEnabled;

  const AppSettings({
    required this.adBlockEnabled,
    required this.popupBlockEnabled,
  });

  AppSettings copyWith({
    bool? adBlockEnabled,
    bool? popupBlockEnabled,
  }) {
    return AppSettings(
      adBlockEnabled: adBlockEnabled ?? this.adBlockEnabled,
      popupBlockEnabled: popupBlockEnabled ?? this.popupBlockEnabled,
    );
  }
}
