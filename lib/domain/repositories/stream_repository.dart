import '../entities/stream_link.dart';

abstract class StreamRepository {
  Future<List<StreamLink>> getStreams();
  Future<void> addStream(StreamLink stream);
  Future<void> deleteStream(String id);
  Future<void> updateStream(StreamLink stream);
}
