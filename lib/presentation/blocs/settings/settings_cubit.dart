import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/settings.dart';
import '../../../domain/usecases/settings_usecases.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettings getSettingsUseCase;
  final UpdateSettings updateSettingsUseCase;

  SettingsCubit({
    required this.getSettingsUseCase,
    required this.updateSettingsUseCase,
  }) : super(const SettingsInitial());

  Future<void> loadSettings() async {
    emit(const SettingsLoading());
    try {
      final settings = await getSettingsUseCase();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> toggleAdBlock(bool enabled) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final updatedSettings = currentState.settings.copyWith(adBlockEnabled: enabled);
      emit(SettingsLoaded(updatedSettings));
      try {
        await updateSettingsUseCase(updatedSettings);
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }

  Future<void> togglePopupBlock(bool enabled) async {
    final currentState = state;
    if (currentState is SettingsLoaded) {
      final updatedSettings = currentState.settings.copyWith(popupBlockEnabled: enabled);
      emit(SettingsLoaded(updatedSettings));
      try {
        await updateSettingsUseCase(updatedSettings);
      } catch (e) {
        emit(SettingsError(e.toString()));
      }
    }
  }
}
