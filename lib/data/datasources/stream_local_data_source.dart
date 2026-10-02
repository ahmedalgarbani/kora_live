import 'package:hive/hive.dart';
import '../../domain/entities/sync_result.dart';
import '../models/stream_link_model.dart';

abstract class StreamLocalDataSource {
  List<StreamLinkModel> getStreams();
  Future<void> addStream(StreamLinkModel stream);
  Future<void> deleteStream(String id);
  Future<void> updateStream(StreamLinkModel stream);
  Future<void> putAll(List<StreamLinkModel> streams);
  Future<void> deleteAll(Iterable<String> ids);
  SyncResult? getLastSync();
  Future<void> saveLastSync(SyncResult result);
}

class StreamLocalDataSourceImpl implements StreamLocalDataSource {
  final Box _box;
  final Box _metaBox;
  static const String _lastSyncKey = 'last_sync';

  StreamLocalDataSourceImpl(this._box, this._metaBox);

  @override
  List<StreamLinkModel> getStreams() {
    final List<StreamLinkModel> list = [];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is Map) {
        try {
          list.add(StreamLinkModel.fromMap(value));
        } catch (_) {
          // Skip corrupt entries
        }
      }
    }
    return list;
  }

  @override
  Future<void> addStream(StreamLinkModel stream) async {
    await _box.put(stream.id, stream.toMap());
  }

  @override
  Future<void> deleteStream(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> updateStream(StreamLinkModel stream) async {
    await _box.put(stream.id, stream.toMap());
  }

  @override
  Future<void> putAll(List<StreamLinkModel> streams) async {
    await _box.putAll({for (final s in streams) s.id: s.toMap()});
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    await _box.deleteAll(ids);
  }

  @override
  SyncResult? getLastSync() {
    final value = _metaBox.get(_lastSyncKey);
    if (value is! Map) return null;
    final syncedAt = DateTime.tryParse(value['syncedAt']?.toString() ?? '');
    if (syncedAt == null) return null;
    return SyncResult(
      added: (value['added'] as num?)?.toInt() ?? 0,
      updated: (value['updated'] as num?)?.toInt() ?? 0,
      removed: (value['removed'] as num?)?.toInt() ?? 0,
      message: value['message'] as String?,
      syncedAt: syncedAt,
    );
  }

  @override
  Future<void> saveLastSync(SyncResult result) async {
    await _metaBox.put(_lastSyncKey, {
      'added': result.added,
      'updated': result.updated,
      'removed': result.removed,
      'message': result.message,
      'syncedAt': result.syncedAt.toIso8601String(),
    });
  }
}
