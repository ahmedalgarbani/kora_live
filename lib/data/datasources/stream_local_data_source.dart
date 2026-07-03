import 'package:hive/hive.dart';
import '../models/stream_link_model.dart';

abstract class StreamLocalDataSource {
  List<StreamLinkModel> getStreams();
  Future<void> addStream(StreamLinkModel stream);
  Future<void> deleteStream(String id);
  Future<void> updateStream(StreamLinkModel stream);
}

class StreamLocalDataSourceImpl implements StreamLocalDataSource {
  final Box _box;

  StreamLocalDataSourceImpl(this._box);

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
}
