import '../../domain/entities/stream_link.dart';
import '../../domain/repositories/stream_repository.dart';
import '../datasources/stream_local_data_source.dart';
import '../models/stream_link_model.dart';

class StreamRepositoryImpl implements StreamRepository {
  final StreamLocalDataSource localDataSource;

  StreamRepositoryImpl(this.localDataSource);

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
}
