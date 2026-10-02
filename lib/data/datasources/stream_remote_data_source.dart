import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../models/stream_link_model.dart';

class RemoteFeed {
  final List<StreamLinkModel> streams;
  final String? message;

  const RemoteFeed({required this.streams, this.message});
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);

  @override
  String toString() => message;
}

abstract class StreamRemoteDataSource {
  Future<RemoteFeed> fetchFeed(String serverUrl);
}

/// Downloads the stream links JSON from the server.
///
/// Accepted formats (see `server/streams.example.json`):
/// - `{"message": "...", "streams": [ {...}, ... ]}` (also `links`, `data`,
///   `items`, or separate `matches` / `channels` arrays)
/// - a bare JSON array of items.
class StreamRemoteDataSourceImpl implements StreamRemoteDataSource {
  final http.Client client;

  StreamRemoteDataSourceImpl(this.client);

  @override
  Future<RemoteFeed> fetchFeed(String serverUrl) async {
    final uri = Uri.tryParse(serverUrl.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw const ServerException('رابط السيرفر غير صالح');
    }

    final http.Response response;
    try {
      response = await client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(AppConfig.requestTimeout);
    } catch (_) {
      throw const ServerException('تعذر الاتصال بالسيرفر، تحقق من الإنترنت');
    }

    if (response.statusCode != 200) {
      throw ServerException('استجابة غير متوقعة من السيرفر (${response.statusCode})');
    }

    try {
      return parseFeed(utf8.decode(response.bodyBytes));
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException('صيغة البيانات القادمة من السيرفر غير صحيحة');
    }
  }

  static RemoteFeed parseFeed(String body, {DateTime? now}) {
    final decoded = jsonDecode(body);
    final timestamp = now ?? DateTime.now();
    String? message;
    final rawItems = <Object?>[];

    if (decoded is List) {
      rawItems.addAll(decoded);
    } else if (decoded is Map) {
      final msg = decoded['message'] ?? decoded['notice'];
      if (msg is String && msg.trim().isNotEmpty) message = msg.trim();

      for (final key in const ['streams', 'links', 'data', 'items']) {
        final value = decoded[key];
        if (value is List) rawItems.addAll(value);
      }
      final matches = decoded['matches'];
      if (matches is List) {
        rawItems.addAll(
          matches.map((e) => e is Map ? {'type': 'match', ...e} : e),
        );
      }
      final channels = decoded['channels'];
      if (channels is List) {
        rawItems.addAll(
          channels.map((e) => e is Map ? {'type': 'channel', ...e} : e),
        );
      }
    } else {
      throw const ServerException('صيغة البيانات القادمة من السيرفر غير صحيحة');
    }

    final streams = <StreamLinkModel>[];
    final seen = <String>{};
    for (final item in rawItems) {
      final model = StreamLinkModel.fromServerJson(item, now: timestamp);
      if (model != null && seen.add(model.id)) streams.add(model);
    }
    return RemoteFeed(streams: streams, message: message);
  }
}
