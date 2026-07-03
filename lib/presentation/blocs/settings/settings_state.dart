import '../../../domain/entities/settings.dart';

sealed class SettingsState {
  const SettingsState();
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final AppSettings settings;
  const SettingsLoaded(this.settings);
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}
