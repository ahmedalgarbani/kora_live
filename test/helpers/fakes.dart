import 'package:kora_live/data/datasources/stream_local_data_source.dart';
import 'package:kora_live/data/datasources/stream_remote_data_source.dart';
import 'package:kora_live/data/models/stream_link_model.dart';
import 'package:kora_live/domain/entities/settings.dart';
import 'package:kora_live/domain/entities/stream_link.dart';
import 'package:kora_live/domain/entities/sync_result.dart';
import 'package:kora_live/domain/repositories/settings_repository.dart';
import 'package:kora_live/domain/repositories/stream_repository.dart';
import 'package:kora_live/domain/usecases/settings_usecases.dart';
import 'package:kora_live/domain/usecases/stream_usecases.dart';
import 'package:kora_live/presentation/blocs/settings/settings_cubit.dart';
import 'package:kora_live/presentation/blocs/stream/stream_cubit.dart';

class FakeLocalDataSource implements StreamLocalDataSource {
  final Map<String, StreamLinkModel> store = {};
  SyncResult? lastSync;

  @override
  List<StreamLinkModel> getStreams() => store.values.toList();

  @override
  Future<void> addStream(StreamLinkModel stream) async => store[stream.id] = stream;

  @override
  Future<void> updateStream(StreamLinkModel stream) async => store[stream.id] = stream;

  @override
  Future<void> deleteStream(String id) async => store.remove(id);

  @override
  Future<void> putAll(List<StreamLinkModel> streams) async {
    for (final s in streams) {
      store[s.id] = s;
    }
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    for (final id in ids) {
      store.remove(id);
    }
  }

  @override
  SyncResult? getLastSync() => lastSync;

  @override
  Future<void> saveLastSync(SyncResult result) async => lastSync = result;
}

class FakeRemoteDataSource implements StreamRemoteDataSource {
  RemoteFeed feed = const RemoteFeed(streams: []);
  Object? error;
  int calls = 0;

  @override
  Future<RemoteFeed> fetchFeed(String serverUrl) async {
    calls++;
    if (error != null) throw error!;
    return feed;
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  AppSettings settings;
  InMemorySettingsRepository([
    this.settings = const AppSettings(adBlockEnabled: true, popupBlockEnabled: true),
  ]);

  @override
  Future<AppSettings> getSettings() async => settings;

  @override
  Future<void> saveSettings(AppSettings value) async => settings = value;
}

StreamCubit buildStreamCubit(StreamRepository repo) => StreamCubit(
      getStreamLinksUseCase: GetStreamLinks(repo),
      addStreamLinkUseCase: AddStreamLink(repo),
      updateStreamLinkUseCase: UpdateStreamLink(repo),
      deleteStreamLinkUseCase: DeleteStreamLink(repo),
      toggleFavoriteStreamLinkUseCase: ToggleFavoriteStreamLink(repo),
      incrementPlayCountUseCase: IncrementPlayCount(repo),
      syncRemoteStreamsUseCase: SyncRemoteStreams(repo),
      getLastSyncUseCase: GetLastSync(repo),
    );

SettingsCubit buildSettingsCubit(SettingsRepository repo) => SettingsCubit(
      getSettingsUseCase: GetSettings(repo),
      updateSettingsUseCase: UpdateSettings(repo),
    );

StreamLinkModel localStream(
  String id,
  String title, {
  StreamType type = StreamType.koraMatch,
  DateTime? createdAt,
  bool isFavorite = false,
}) =>
    StreamLinkModel(
      id: id,
      title: title,
      url: 'https://example.com/$id',
      type: type,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      isFavorite: isFavorite,
    );
