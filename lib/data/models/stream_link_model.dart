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
    super.source,
    super.mirrors,
    super.league,
    super.logoUrl,
    super.startTime,
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
      source: entity.source,
      mirrors: entity.mirrors,
      league: entity.league,
      logoUrl: entity.logoUrl,
      startTime: entity.startTime,
    );
  }

  /// Reads a record previously written by [toMap]. Fields added in later
  /// versions are optional so older stored records keep loading.
  factory StreamLinkModel.fromMap(Map<dynamic, dynamic> map) {
    return StreamLinkModel(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      type: StreamType.values.firstWhere(
        (e) => e.name == (map['type'] as String?),
        orElse: () => StreamType.koraMatch,
      ),
      isFavorite: (map['isFavorite'] as bool?) ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastViewedAt: _parseDate(map['lastViewedAt']),
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
      source: StreamSource.values.firstWhere(
        (e) => e.name == (map['source'] as String?),
        orElse: () => StreamSource.local,
      ),
      mirrors: parseMirrors(map['mirrors']),
      league: _nonEmpty(map['league']),
      logoUrl: _nonEmpty(map['logoUrl']),
      startTime: _parseDate(map['startTime']),
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
      'source': source.name,
      'mirrors': [
        for (final m in mirrors) {'name': m.name, 'url': m.url},
      ],
      'league': league,
      'logoUrl': logoUrl,
      'startTime': startTime?.toIso8601String(),
    };
  }

  /// Parses one item of the server JSON feed. Returns null when the item has
  /// no usable title or URL. Accepts several common key spellings so the
  /// server side can stay simple.
  static StreamLinkModel? fromServerJson(Object? json, {DateTime? now}) {
    if (json is! Map) return null;

    final title = _firstString(json, const ['title', 'name']);
    final url = _firstString(json, const ['url', 'link', 'stream', 'src']);
    if (title == null || url == null || !isValidStreamUrl(url)) return null;

    final rawId = _firstString(json, const ['id', 'uid', 'slug']) ?? url;
    final mirrors = parseMirrors(json['mirrors'] ?? json['servers'])
        .where((m) => isValidStreamUrl(m.url))
        .toList();

    return StreamLinkModel(
      id: 'remote_$rawId',
      title: title,
      url: url,
      type: parseType(json['type'] ?? json['category']),
      createdAt: now ?? DateTime.now(),
      source: StreamSource.remote,
      mirrors: mirrors,
      league: _firstString(json, const ['league', 'competition', 'tournament']),
      logoUrl: _firstString(json, const ['logo', 'logoUrl', 'image', 'icon']),
      startTime: _parseDate(json['startTime'] ?? json['time'] ?? json['date']),
    );
  }

  static StreamType parseType(Object? raw) {
    final value = raw?.toString().toLowerCase().trim() ?? '';
    const channelWords = ['channel', 'tv', 'tvchannel', 'قناة', 'قنوات'];
    return channelWords.contains(value)
        ? StreamType.tvChannel
        : StreamType.koraMatch;
  }

  static List<StreamMirror> parseMirrors(Object? raw) {
    if (raw is! List) return const [];
    final result = <StreamMirror>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is String && item.trim().isNotEmpty) {
        result.add(StreamMirror(name: 'سيرفر ${i + 2}', url: item.trim()));
      } else if (item is Map) {
        final url = _firstString(item, const ['url', 'link']);
        if (url == null) continue;
        final name =
            _firstString(item, const ['name', 'title', 'label']) ??
            'سيرفر ${i + 2}';
        result.add(StreamMirror(name: name, url: url));
      }
    }
    return result;
  }

  static bool isValidStreamUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static String? _firstString(Map<dynamic, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = _nonEmpty(map[key]);
      if (value != null) return value;
    }
    return null;
  }

  static String? _nonEmpty(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is int) {
      // Accept unix seconds or milliseconds.
      return DateTime.fromMillisecondsSinceEpoch(
        value < 100000000000 ? value * 1000 : value,
      );
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
