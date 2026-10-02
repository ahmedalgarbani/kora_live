import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kora_live/data/datasources/stream_remote_data_source.dart';
import 'package:kora_live/domain/entities/stream_link.dart';

void main() {
  group('parseFeed', () {
    test('reads the documented object format', () {
      final feed = StreamRemoteDataSourceImpl.parseFeed(jsonEncode({
        'message': '  مرحباً  ',
        'streams': [
          {
            'id': 'm1',
            'title': 'الهلال vs النصر',
            'url': 'https://live.example.com/1',
            'type': 'match',
            'league': 'دوري روشن',
            'startTime': '2026-10-02T18:00:00Z',
            'logo': 'https://example.com/logo.png',
            'mirrors': [
              {'name': 'HD', 'url': 'https://hd.example.com/1'},
              'https://backup.example.com/1',
              {'name': 'bad', 'url': 'not a url'},
            ],
          },
          {
            'name': 'beIN Sports 1',
            'link': 'http://tv.example.com/bein1',
            'type': 'channel',
          },
        ],
      }));

      expect(feed.message, 'مرحباً');
      expect(feed.streams, hasLength(2));

      final match = feed.streams.first;
      expect(match.id, 'remote_m1');
      expect(match.source, StreamSource.remote);
      expect(match.type, StreamType.koraMatch);
      expect(match.league, 'دوري روشن');
      expect(match.logoUrl, 'https://example.com/logo.png');
      expect(match.startTime!.toUtc(), DateTime.utc(2026, 10, 2, 18));
      expect(match.mirrors.map((m) => m.name), ['HD', 'سيرفر 3']);

      final channel = feed.streams.last;
      expect(channel.title, 'beIN Sports 1');
      expect(channel.url, 'http://tv.example.com/bein1');
      expect(channel.type, StreamType.tvChannel);
      // Without an id the URL is used, so ids stay stable across syncs.
      expect(channel.id, 'remote_http://tv.example.com/bein1');
    });

    test('accepts a bare list and separate matches/channels arrays', () {
      final list = StreamRemoteDataSourceImpl.parseFeed(jsonEncode([
        {'title': 'A', 'url': 'https://a.com'},
      ]));
      expect(list.streams.single.title, 'A');

      final split = StreamRemoteDataSourceImpl.parseFeed(jsonEncode({
        'matches': [
          {'title': 'M', 'url': 'https://m.com'},
        ],
        'channels': [
          {'title': 'C', 'url': 'https://c.com'},
        ],
      }));
      expect(split.streams.map((s) => s.type),
          [StreamType.koraMatch, StreamType.tvChannel]);
    });

    test('skips invalid and duplicate items', () {
      final feed = StreamRemoteDataSourceImpl.parseFeed(jsonEncode({
        'streams': [
          {'title': 'no url'},
          {'url': 'https://no-title.com'},
          {'title': 'bad scheme', 'url': 'ftp://x.com'},
          {'title': 'js', 'url': 'javascript:alert(1)'},
          'just a string',
          {'id': '1', 'title': 'ok', 'url': 'https://ok.com'},
          {'id': '1', 'title': 'dup', 'url': 'https://dup.com'},
        ],
      }));
      expect(feed.streams.map((s) => s.title), ['ok']);
    });

    test('accepts unix timestamps', () {
      final feed = StreamRemoteDataSourceImpl.parseFeed(jsonEncode([
        {'title': 'A', 'url': 'https://a.com', 'startTime': 1790000000},
      ]));
      expect(
        feed.streams.single.startTime,
        DateTime.fromMillisecondsSinceEpoch(1790000000 * 1000),
      );
    });
  });

  group('fetchFeed', () {
    test('decodes UTF-8 Arabic responses', () async {
      final client = MockClient((req) async {
        expect(req.url.toString(), 'https://srv.example.com/feed.json');
        return http.Response.bytes(
          utf8.encode(jsonEncode([
            {'title': 'الأهلي ضد الزمالك', 'url': 'https://a.com'},
          ])),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final feed = await StreamRemoteDataSourceImpl(client)
          .fetchFeed(' https://srv.example.com/feed.json ');
      expect(feed.streams.single.title, 'الأهلي ضد الزمالك');
    });

    test('reports HTTP, format and URL errors in Arabic', () async {
      final notFound = StreamRemoteDataSourceImpl(
        MockClient((_) async => http.Response('nope', 404)),
      );
      await expectLater(
        notFound.fetchFeed('https://srv.example.com'),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', contains('404'))),
      );

      final badJson = StreamRemoteDataSourceImpl(
        MockClient((_) async => http.Response('<html>', 200)),
      );
      await expectLater(
        badJson.fetchFeed('https://srv.example.com'),
        throwsA(isA<ServerException>()),
      );

      final offline = StreamRemoteDataSourceImpl(
        MockClient((_) async => throw Exception('socket')),
      );
      await expectLater(
        offline.fetchFeed('https://srv.example.com'),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', contains('الاتصال'))),
      );

      await expectLater(
        notFound.fetchFeed('srv.example.com'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
