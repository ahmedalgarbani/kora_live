class AppSettings {
  final bool adBlockEnabled;
  final bool popupBlockEnabled;

  /// JSON endpoint that serves the stream links. Empty means "no server".
  final String serverUrl;

  /// Fetch links from [serverUrl] automatically when the app starts.
  final bool autoSync;

  /// Keep the screen awake while a stream is playing.
  final bool keepScreenOn;

  const AppSettings({
    required this.adBlockEnabled,
    required this.popupBlockEnabled,
    this.serverUrl = '',
    this.autoSync = true,
    this.keepScreenOn = true,
  });

  bool get hasServer => serverUrl.trim().isNotEmpty;

  AppSettings copyWith({
    bool? adBlockEnabled,
    bool? popupBlockEnabled,
    String? serverUrl,
    bool? autoSync,
    bool? keepScreenOn,
  }) {
    return AppSettings(
      adBlockEnabled: adBlockEnabled ?? this.adBlockEnabled,
      popupBlockEnabled: popupBlockEnabled ?? this.popupBlockEnabled,
      serverUrl: serverUrl ?? this.serverUrl,
      autoSync: autoSync ?? this.autoSync,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
    );
  }
}
