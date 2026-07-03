import 'package:flutter_test/flutter_test.dart';
import 'package:kora_live/domain/entities/stream_link.dart';
import 'package:kora_live/data/models/stream_link_model.dart';
import 'package:kora_live/data/models/settings_model.dart';

void main() {
  group('Data Layer Model Serialization Tests', () {
    test('StreamLinkModel serialization and deserialization', () {
      final now = DateTime(2026, 7, 4, 12, 0, 0);
      final stream = StreamLinkModel(
        id: 'test_123',
        title: 'Real Madrid vs Barcelona',
        url: 'https://kora-live.com/bein-1',
        type: StreamType.koraMatch,
        isFavorite: true,
        createdAt: now,
        lastViewedAt: now,
        playCount: 5,
      );

      final map = stream.toMap();
      expect(map['id'], 'test_123');
      expect(map['title'], 'Real Madrid vs Barcelona');
      expect(map['url'], 'https://kora-live.com/bein-1');
      expect(map['type'], 'koraMatch');
      expect(map['isFavorite'], true);
      expect(map['createdAt'], now.toIso8601String());
      expect(map['lastViewedAt'], now.toIso8601String());
      expect(map['playCount'], 5);

      final decoded = StreamLinkModel.fromMap(map);
      expect(decoded.id, stream.id);
      expect(decoded.title, stream.title);
      expect(decoded.url, stream.url);
      expect(decoded.type, stream.type);
      expect(decoded.isFavorite, stream.isFavorite);
      expect(decoded.createdAt.isAtSameMomentAs(stream.createdAt), true);
      expect(decoded.lastViewedAt!.isAtSameMomentAs(stream.lastViewedAt!), true);
      expect(decoded.playCount, stream.playCount);
    });

    test('SettingsModel serialization and deserialization', () {
      const settings = SettingsModel(
        adBlockEnabled: true,
        popupBlockEnabled: false,
      );

      final map = settings.toMap();
      expect(map['adBlockEnabled'], true);
      expect(map['popupBlockEnabled'], false);

      final decoded = SettingsModel.fromMap(map);
      expect(decoded.adBlockEnabled, true);
      expect(decoded.popupBlockEnabled, false);
    });
  });

  group('Sorting and Helpers Verification', () {
    test('Stream list sorting helper test', () {
      final now = DateTime.now();
      final stream1 = StreamLink(
        id: '1',
        title: 'Z TV Channel',
        url: 'https://tv.z',
        type: StreamType.tvChannel,
        createdAt: now.subtract(const Duration(minutes: 10)),
        playCount: 10,
        lastViewedAt: now.subtract(const Duration(minutes: 5)),
      );

      final stream2 = StreamLink(
        id: '2',
        title: 'A Kora Match',
        url: 'https://live.a',
        type: StreamType.koraMatch,
        createdAt: now,
        playCount: 20,
        lastViewedAt: now,
      );

      final list = [stream1, stream2];

      // Test Alphabetical Sorting (A-Z)
      final alphabetical = List<StreamLink>.from(list);
      alphabetical.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      expect(alphabetical.first.id, '2'); // 'A Kora Match' comes first

      // Test Play Count Sorting (Descending)
      final playCountSort = List<StreamLink>.from(list);
      playCountSort.sort((a, b) => b.playCount.compareTo(a.playCount));
      expect(playCountSort.first.id, '2'); // playCount 20 is greater than 10

      // Test Date Added Sorting (Newest First)
      final dateSort = List<StreamLink>.from(list);
      dateSort.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      expect(dateSort.first.id, '2'); // createdAt 'now' is newer than 'now - 10m'
    });
  });
}
