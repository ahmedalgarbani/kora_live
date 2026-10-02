import '../../domain/entities/stream_link.dart';
import '../../domain/entities/sync_result.dart';
import '../../domain/repositories/stream_repository.dart';
import '../datasources/stream_local_data_source.dart';
import '../datasources/stream_remote_data_source.dart';
import '../models/stream_link_model.dart';

class StreamRepositoryImpl implements StreamRepository {
  final StreamLocalDataSource localDataSource;
  final StreamRemoteDataSource remoteDataSource;

  StreamRepositoryImpl(this.localDataSource, this.remoteDataSource);

  @override
  Future<List<StreamLink>> getStreams() async {
    return localDataSource.getStreams();
  }

  @override
  Future<void> addStream(StreamLink stream) async {
    final model = StreamLinkModel.fromEntity(stream);
    await localDataSource.addStream(model);
  }

  @override
  Future<void> deleteStream(String id) async {
    await localDataSource.deleteStream(id);
  }

  @override
  Future<void> updateStream(StreamLink stream) async {
    final model = StreamLinkModel.fromEntity(stream);
    await localDataSource.updateStream(model);
  }

  @override
  Future<SyncResult> syncFromServer(String serverUrl) async {
    final feed = await remoteDataSource.fetchFeed(serverUrl);

    final existingRemote = {
      for (final s in localDataSource.getStreams())
        if (s.isRemote) s.id: s,
    };

    var added = 0;
    var updated = 0;
    final merged = <StreamLinkModel>[];
    for (final incoming in feed.streams) {
      final previous = existingRemote.remove(incoming.id);
      if (previous == null) {
        added++;
        merged.add(incoming);
      } else {
        updated++;
        // Server owns the content; the user owns favorites and history.
        merged.add(
          StreamLinkModel.fromEntity(
            incoming.copyWith(
              isFavorite: previous.isFavorite,
              playCount: previous.playCount,
              lastViewedAt: previous.lastViewedAt,
              createdAt: previous.createdAt,
            ),
          ),
        );
      }
    }

    // Whatever is left was removed from the server.
    final removedIds = existingRemote.keys.toList();
    await localDataSource.putAll(merged);
    await localDataSource.deleteAll(removedIds);

    final result = SyncResult(
      added: added,
      updated: updated,
      removed: removedIds.length,
      message: feed.message,
      syncedAt: DateTime.now(),
    );
    await localDataSource.saveLastSync(result);
    return result;
  }

  @override
  Future<SyncResult?> getLastSync() async {
    return localDataSource.getLastSync();
  }
}
