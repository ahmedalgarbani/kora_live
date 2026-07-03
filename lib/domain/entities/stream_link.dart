enum StreamType {
  koraMatch,
  tvChannel,
}

class StreamLink {
  final String id;
  final String title;
  final String url;
  final StreamType type;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? lastViewedAt;
  final int playCount;

  const StreamLink({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    this.isFavorite = false,
    required this.createdAt,
    this.lastViewedAt,
    this.playCount = 0,
  });

  StreamLink copyWith({
    String? id,
    String? title,
    String? url,
    StreamType? type,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastViewedAt,
    int? playCount,
  }) {
    return StreamLink(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      playCount: playCount ?? this.playCount,
    );
  }
}
