import '../entities/stream_link.dart';
import '../repositories/stream_repository.dart';

class GetStreamLinks {
  final StreamRepository repository;
  const GetStreamLinks(this.repository);

  Future<List<StreamLink>> call() async {
    return repository.getStreams();
  }
}

class AddStreamLink {
  final StreamRepository repository;
  const AddStreamLink(this.repository);

  Future<void> call(StreamLink stream) async {
    return repository.addStream(stream);
  }
}

class DeleteStreamLink {
  final StreamRepository repository;
  const DeleteStreamLink(this.repository);

  Future<void> call(String id) async {
    return repository.deleteStream(id);
  }
}

class ToggleFavoriteStreamLink {
  final StreamRepository repository;
  const ToggleFavoriteStreamLink(this.repository);

  Future<void> call(StreamLink stream) async {
    final updated = stream.copyWith(isFavorite: !stream.isFavorite);
    return repository.updateStream(updated);
  }
}

class IncrementPlayCount {
  final StreamRepository repository;
  const IncrementPlayCount(this.repository);

  Future<void> call(StreamLink stream) async {
    final updated = stream.copyWith(
      playCount: stream.playCount + 1,
      lastViewedAt: DateTime.now(),
    );
    return repository.updateStream(updated);
  }
}
