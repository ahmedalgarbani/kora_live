import '../entities/settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository repository;
  const GetSettings(this.repository);

  Future<AppSettings> call() async {
    return repository.getSettings();
  }
}

class UpdateSettings {
  final SettingsRepository repository;
  const UpdateSettings(this.repository);

  Future<void> call(AppSettings settings) async {
    return repository.saveSettings(settings);
  }
}
