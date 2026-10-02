import 'package:flutter_test/flutter_test.dart';
import 'package:kora_live/data/datasources/stream_remote_data_source.dart';
import 'package:kora_live/data/models/stream_link_model.dart';
import 'package:kora_live/data/repositories/stream_repository_impl.dart';
import 'package:kora_live/domain/entities/stream_link.dart';
import 'package:kora_live/presentation/blocs/stream/stream_state.dart';

import 'helpers/fakes.dart';

StreamLinkModel remote(String id, String title, {String? url}) => StreamLinkModel(
      id: 'remote_$id',
      title: title,
      url: url ?? 'https://srv.example.com/$id',
      type: StreamType.koraMatch,
      createdAt: DateTime(2026, 10, 1),
      source: StreamSource.remote,
    );

void main() {
  late FakeLocalDataSource local;
  late FakeRemoteDataSource server;
  late StreamRepositoryImpl repo;

  setUp(() {
    local = FakeLocalDataSource();
    server = FakeRemoteDataSource();
    repo = StreamRepositoryImpl(local, server);
  });

  test('sync adds, updates and removes remote links only', () async {
    await local.addStream(localStream('mine', 'My own link'));
    await local.addStream(remote('old', 'Gone from server'));
    await local.addStream(remote('keep', 'Old title').copyWithModel(
      isFavorite: true,
      playCount: 7,
      lastViewedAt: DateTime(2026, 9, 30),
    ));

    server.feed = RemoteFeed(
      streams: [
        remote('keep', 'New title', url: 'https://srv.example.com/new'),
        remote('fresh', 'Brand new'),
      ],
      message: 'hello',
    );

    final result = await repo.syncFromServer('https://srv.example.com');

    expect(result.added, 1);
    expect(result.updated, 1);
    expect(result.removed, 1);
    expect(result.message, 'hello');

    expect(local.store.keys,
        unorderedEquals(['mine', 'remote_keep', 'remote_fresh']));

    final kept = local.store['remote_keep']!;
    expect(kept.title, 'New title');
    expect(kept.url, 'https://srv.example.com/new');
    // The user's own data survives the update.
    expect(kept.isFavorite, isTrue);
    expect(kept.playCount, 7);
    expect(kept.lastViewedAt, DateTime(2026, 9, 30));

    expect((await repo.getLastSync())!.total, 2);
  });

  test('failed sync keeps existing links untouched', () async {
    await local.addStream(remote('a', 'A'));
    server.error = Exception('offline');
    await expectLater(repo.syncFromServer('https://x.com'), throwsException);
    expect(local.store.keys, ['remote_a']);
    expect(local.lastSync, isNull);
  });

  test('cubit exposes sync state and keeps the list on errors', () async {
    await local.addStream(localStream('mine', 'Mine'));
    final cubit = buildStreamCubit(repo);
    await cubit.loadStreams();

    server.feed = RemoteFeed(streams: [remote('r', 'Remote')]);
    final result = await cubit.syncWithServer('https://srv.example.com');
    expect(result!.added, 1);
    var state = cubit.state as StreamLoaded;
    expect(state.isSyncing, isFalse);
    expect(state.allStreams, hasLength(2));
    expect(state.lastSync, isNotNull);

    server.error = const ServerException('تعذر الاتصال');
    expect(await cubit.syncWithServer('https://srv.example.com'), isNull);
    state = cubit.state as StreamLoaded;
    expect(state.error, 'تعذر الاتصال');
    expect(state.allStreams, hasLength(2));

    cubit.clearError();
    expect((cubit.state as StreamLoaded).error, isNull);

    // Empty server URL is a no-op.
    final calls = server.calls;
    expect(await cubit.syncWithServer('  '), isNull);
    expect(server.calls, calls);
    await cubit.close();
  });
}

extension on StreamLinkModel {
  StreamLinkModel copyWithModel({
    bool? isFavorite,
    int? playCount,
    DateTime? lastViewedAt,
  }) =>
      StreamLinkModel.fromEntity(copyWith(
        isFavorite: isFavorite,
        playCount: playCount,
        lastViewedAt: lastViewedAt,
      ));
}
