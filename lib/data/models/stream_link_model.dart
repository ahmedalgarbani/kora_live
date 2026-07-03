import '../../domain/entities/stream_link.dart';

class StreamLinkModel extends StreamLink {
  const StreamLinkModel({
    required super.id,
    required super.title,
    required super.url,
    required super.type,
    super.isFavorite,
    required super.createdAt,
    super.lastViewedAt,
    super.playCount,
  });

  factory StreamLinkModel.fromEntity(StreamLink entity) {
    return StreamLinkModel(
      id: entity.id,
      title: entity.title,
      url: entity.url,
      type: entity.type,
      isFavorite: entity.isFavorite,
      createdAt: entity.createdAt,
      lastViewedAt: entity.lastViewedAt,
      playCount: entity.playCount,
    );
  }

  factory StreamLinkModel.fromMap(Map<dynamic, dynamic> map) {
    return StreamLinkModel(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      type: StreamType.values.firstWhere(
        (e) => e.name == (map['type'] as String),
        orElse: () => StreamType.koraMatch,
      ),
      isFavorite: (map['isFavorite'] as bool?) ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastViewedAt: map['lastViewedAt'] != null 
          ? DateTime.parse(map['lastViewedAt'] as String) 
          : null,
      playCount: (map['playCount'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'type': type.name,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'lastViewedAt': lastViewedAt?.toIso8601String(),
      'playCount': playCount,
    };
  }
}
