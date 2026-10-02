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

  Future<void> toggleAdBlock(bool enabled) =>
      _update((s) => s.copyWith(adBlockEnabled: enabled));

  Future<void> togglePopupBlock(bool enabled) =>
      _update((s) => s.copyWith(popupBlockEnabled: enabled));

  Future<void> setServerUrl(String url) =>
      _update((s) => s.copyWith(serverUrl: url.trim()));

  Future<void> setAutoSync(bool enabled) =>
      _update((s) => s.copyWith(autoSync: enabled));

  Future<void> setKeepScreenOn(bool enabled) =>
      _update((s) => s.copyWith(keepScreenOn: enabled));

  Future<void> _update(AppSettings Function(AppSettings) change) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;
    final updated = change(currentState.settings);
    // Apply immediately; the in-memory value stays valid even if the
    // write to disk fails, so the UI never loses the user's settings.
    emit(SettingsLoaded(updated));
    try {
      await updateSettingsUseCase(updated);
    } catch (_) {}
  }
}
