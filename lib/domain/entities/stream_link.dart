enum StreamType {
  koraMatch,
  tvChannel,
}

/// Where a link came from: added manually by the user, or synced from the server.
enum StreamSource {
  local,
  remote,
}

/// An alternative server/quality for the same stream (e.g. "HD", "سيرفر 2").
class StreamMirror {
  final String name;
  final String url;

  const StreamMirror({required this.name, required this.url});

  @override
  bool operator ==(Object other) =>
      other is StreamMirror && other.name == name && other.url == url;

  @override
  int get hashCode => Object.hash(name, url);
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
  final StreamSource source;
  final List<StreamMirror> mirrors;
  final String? league;
  final String? logoUrl;
  final DateTime? startTime;

  const StreamLink({
    required this.id,
    required this.title,
    required this.url,
    required this.type,
    this.isFavorite = false,
    required this.createdAt,
    this.lastViewedAt,
    this.playCount = 0,
    this.source = StreamSource.local,
    this.mirrors = const [],
    this.league,
    this.logoUrl,
    this.startTime,
  });

  bool get isRemote => source == StreamSource.remote;
  bool get isMatch => type == StreamType.koraMatch;

  /// The main URL followed by any distinct mirrors.
  List<StreamMirror> get allSources {
    final result = <StreamMirror>[StreamMirror(name: 'الرئيسي', url: url)];
    for (final m in mirrors) {
      if (!result.any((e) => e.url == m.url)) result.add(m);
    }
    return result;
  }

  /// A match is considered live from its start time until ~2.5 hours later.
  bool isLiveAt(DateTime now) {
    final start = startTime;
    if (start == null) return false;
    return !now.isBefore(start) &&
        now.isBefore(start.add(const Duration(minutes: 150)));
  }

  StreamLink copyWith({
    String? id,
    String? title,
    String? url,
    StreamType? type,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastViewedAt,
    int? playCount,
    StreamSource? source,
    List<StreamMirror>? mirrors,
    String? league,
    String? logoUrl,
    DateTime? startTime,
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
      source: source ?? this.source,
      mirrors: mirrors ?? this.mirrors,
      league: league ?? this.league,
      logoUrl: logoUrl ?? this.logoUrl,
      startTime: startTime ?? this.startTime,
    );
  }
}
