import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kora_live/core/theme/app_theme.dart';
import 'package:kora_live/data/repositories/stream_repository_impl.dart';
import 'package:kora_live/presentation/screens/home_screen.dart';
import 'package:kora_live/domain/entities/stream_link.dart';
import 'package:kora_live/data/models/stream_link_model.dart';
import 'package:kora_live/data/models/settings_model.dart';

import 'helpers/fakes.dart';

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
      expect(decoded.serverUrl, '');
      expect(decoded.autoSync, true);
    });

    test('records saved by v1.0 (without new fields) still load', () {
      final legacy = StreamLinkModel.fromMap({
        'id': '1700000000000',
        'title': 'Old',
        'url': 'https://old.example.com',
        'type': 'tvChannel',
        'isFavorite': false,
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'lastViewedAt': null,
        'playCount': 2,
      });
      expect(legacy.source, StreamSource.local);
      expect(legacy.mirrors, isEmpty);
      expect(legacy.type, StreamType.tvChannel);
      expect(legacy.playCount, 2);

      final legacySettings = SettingsModel.fromMap(
        {'adBlockEnabled': false, 'popupBlockEnabled': true},
        defaultServerUrl: 'https://default.example.com',
      );
      expect(legacySettings.adBlockEnabled, false);
      expect(legacySettings.serverUrl, 'https://default.example.com');
    });

    test('new fields round-trip', () {
      final model = StreamLinkModel(
        id: 'remote_1',
        title: 'T',
        url: 'https://a.com',
        type: StreamType.koraMatch,
        createdAt: DateTime(2026, 1, 1),
        source: StreamSource.remote,
        mirrors: const [StreamMirror(name: 'HD', url: 'https://b.com')],
        league: 'UCL',
        logoUrl: 'https://logo.png',
        startTime: DateTime(2026, 1, 2, 20),
      );
      final decoded = StreamLinkModel.fromMap(model.toMap());
      expect(decoded.source, StreamSource.remote);
      expect(decoded.mirrors, model.mirrors);
      expect(decoded.league, 'UCL');
      expect(decoded.logoUrl, 'https://logo.png');
      expect(decoded.startTime, DateTime(2026, 1, 2, 20));
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

  group('Home screen', () {
    Future<FakeLocalDataSource> pumpHome(WidgetTester tester) async {
      final local = FakeLocalDataSource();
      await local.addStream(localStream('1', 'Arsenal vs Chelsea'));
      await local.addStream(localStream('2', 'beIN Sports 1', type: StreamType.tvChannel));
      final streamCubit = buildStreamCubit(
        StreamRepositoryImpl(local, FakeRemoteDataSource()),
      );
      final settingsCubit = buildSettingsCubit(InMemorySettingsRepository());

      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settingsCubit),
          BlocProvider.value(value: streamCubit),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      return local;
    }

    testWidgets('shows streams and navigates between tabs', (tester) async {
      await pumpHome(tester);

      expect(find.text('المباريات'), findsWidgets);
      expect(find.text('Arsenal vs Chelsea'), findsWidgets);
      expect(find.text('beIN Sports 1'), findsWidgets);

      await tester.tap(find.text('الإعدادات').last);
      await tester.pumpAndSettle();
      expect(find.text('رابط السيرفر'), findsOneWidget);
      expect(find.text('حاجب الإعلانات'), findsOneWidget);

      await tester.tap(find.text('المفضلة').last);
      await tester.pumpAndSettle();
      expect(find.text('لا توجد عناصر مفضلة'), findsOneWidget);
    });

    testWidgets('add sheet validates and saves a link', (tester) async {
      final local = await pumpHome(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إضافة').last);
      await tester.pumpAndSettle();
      expect(find.text('أدخل العنوان'), findsOneWidget);
      expect(find.text('أدخل رابط البث'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Ahly vs Zamalek');
      await tester.enterText(find.byType(TextFormField).at(1), 'not-a-url');
      await tester.tap(find.text('إضافة').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('الرابط غير صالح'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'https://live.example.com/1');
      await tester.tap(find.text('إضافة').last);
      await tester.pumpAndSettle();

      expect(local.store.values.map((s) => s.title), contains('Ahly vs Zamalek'));
    });
  });
}
