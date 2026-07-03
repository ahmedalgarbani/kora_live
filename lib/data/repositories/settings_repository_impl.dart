import '../../domain/entities/settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl(this.localDataSource);

  @override
  Future<AppSettings> getSettings() async {
    return localDataSource.getSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final model = SettingsModel.fromEntity(settings);
    await localDataSource.saveSettings(model);
  }
}
