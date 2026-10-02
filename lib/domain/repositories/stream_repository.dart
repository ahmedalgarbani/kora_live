import '../entities/stream_link.dart';
import '../entities/sync_result.dart';

abstract class StreamRepository {
  Future<List<StreamLink>> getStreams();
  Future<void> addStream(StreamLink stream);
  Future<void> deleteStream(String id);
  Future<void> updateStream(StreamLink stream);

  /// Downloads the links from [serverUrl] and merges them into local storage,
  /// keeping the user's favorites and watch history for each link.
  Future<SyncResult> syncFromServer(String serverUrl);

  /// The result of the last successful sync, if any (survives restarts).
  Future<SyncResult?> getLastSync();
}
