import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import '../../data/datasources/settings_local_data_source.dart';
import '../../data/datasources/stream_local_data_source.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/repositories/stream_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/stream_repository.dart';
import '../../domain/usecases/settings_usecases.dart';
import '../../domain/usecases/stream_usecases.dart';
import '../../presentation/blocs/settings/settings_cubit.dart';
import '../../presentation/blocs/stream/stream_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> initDI() async {
  // Hive Boxes
  final streamsBox = await Hive.openBox('kora_streams_box');
  final settingsBox = await Hive.openBox('kora_settings_box');

  sl.registerSingleton<Box>(streamsBox, instanceName: 'streamsBox');
  sl.registerSingleton<Box>(settingsBox, instanceName: 'settingsBox');

  // Data Sources
  sl.registerLazySingleton<StreamLocalDataSource>(
    () => StreamLocalDataSourceImpl(sl<Box>(instanceName: 'streamsBox')),
  );
  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(sl<Box>(instanceName: 'settingsBox')),
  );

  // Repositories
  sl.registerLazySingleton<StreamRepository>(
    () => StreamRepositoryImpl(sl<StreamLocalDataSource>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<SettingsLocalDataSource>()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetStreamLinks(sl<StreamRepository>()));
  sl.registerLazySingleton(() => AddStreamLink(sl<StreamRepository>()));
  sl.registerLazySingleton(() => DeleteStreamLink(sl<StreamRepository>()));
  sl.registerLazySingleton(() => ToggleFavoriteStreamLink(sl<StreamRepository>()));
  sl.registerLazySingleton(() => IncrementPlayCount(sl<StreamRepository>()));

  sl.registerLazySingleton(() => GetSettings(sl<SettingsRepository>()));
  sl.registerLazySingleton(() => UpdateSettings(sl<SettingsRepository>()));

  // Cubits (Factories to support disposal lifecycle)
  sl.registerFactory(
    () => SettingsCubit(
      getSettingsUseCase: sl<GetSettings>(),
      updateSettingsUseCase: sl<UpdateSettings>(),
    ),
  );
  
  sl.registerFactory(
    () => StreamCubit(
      getStreamLinksUseCase: sl<GetStreamLinks>(),
      addStreamLinkUseCase: sl<AddStreamLink>(),
      deleteStreamLinkUseCase: sl<DeleteStreamLink>(),
      toggleFavoriteStreamLinkUseCase: sl<ToggleFavoriteStreamLink>(),
      incrementPlayCountUseCase: sl<IncrementPlayCount>(),
    ),
  );
}
