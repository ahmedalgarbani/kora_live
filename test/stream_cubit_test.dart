import 'package:flutter_test/flutter_test.dart';
import 'package:kora_live/data/repositories/stream_repository_impl.dart';
import 'package:kora_live/domain/entities/stream_link.dart';
import 'package:kora_live/presentation/blocs/stream/stream_cubit.dart';
import 'package:kora_live/presentation/blocs/stream/stream_state.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeLocalDataSource local;
  late StreamCubit cubit;

  setUp(() {
    local = FakeLocalDataSource();
    cubit = buildStreamCubit(StreamRepositoryImpl(local, FakeRemoteDataSource()));
  });

  tearDown(() => cubit.close());

  StreamLoaded loaded() => cubit.state as StreamLoaded;

  test('add, edit, favorite, play, delete and undo', () async {
    await cubit.loadStreams();
    await cubit.addNewStream(
      'Arsenal vs Chelsea',
      'https://a.com',
      StreamType.koraMatch,
      mirrors: const [StreamMirror(name: 'سيرفر 2', url: 'https://b.com')],
    );
    var stream = loaded().allStreams.single;
    expect(stream.allSources, hasLength(2));

    await cubit.editStream(stream.copyWith(title: 'Arsenal vs Spurs'));
    stream = loaded().allStreams.single;
    expect(stream.title, 'Arsenal vs Spurs');

    await cubit.toggleFavorite(stream);
    stream = loaded().allStreams.single;
    expect(stream.isFavorite, isTrue);

    await cubit.recordPlay(stream);
    stream = loaded().allStreams.single;
    expect(stream.playCount, 1);
    expect(loaded().recentlyWatched.single.id, stream.id);

    await cubit.removeStream(stream.id);
    expect(loaded().allStreams, isEmpty);
    await cubit.restoreStream(stream);
    expect(loaded().allStreams.single.isFavorite, isTrue);

    await cubit.clearHistory();
    stream = loaded().allStreams.single;
    expect(stream.playCount, 0);
    expect(stream.lastViewedAt, isNull);
    expect(stream.isFavorite, isTrue);
  });

  test('filter, search and sort are combined', () async {
    await local.addStream(localStream('1', 'Zamalek vs Ahly', createdAt: DateTime(2026, 1, 1)));
    await local.addStream(localStream('2', 'beIN 1', type: StreamType.tvChannel, createdAt: DateTime(2026, 1, 2)));
    await local.addStream(localStream('3', 'Barca vs Real', isFavorite: true, createdAt: DateTime(2026, 1, 3)));
    await cubit.loadStreams();

    expect(loaded().filteredStreams.map((s) => s.id), ['3', '2', '1']);

    cubit.changeFilter(FilterOption.koraMatches);
    expect(loaded().filteredStreams.map((s) => s.id), ['3', '1']);

    cubit.changeSort(SortOption.alphabetical);
    expect(loaded().filteredStreams.map((s) => s.id), ['3', '1']);

    cubit.searchStreams('ZAMALEK');
    expect(loaded().filteredStreams.map((s) => s.id), ['1']);

    cubit.searchStreams('');
    cubit.changeFilter(FilterOption.favorites);
    expect(loaded().filteredStreams.map((s) => s.id), ['3']);
  });

  test('default sort puts scheduled matches first by kick-off', () {
    final base = DateTime(2026, 1, 1);
    final list = [
      StreamLink(id: 'new', title: 'n', url: 'u', type: StreamType.tvChannel, createdAt: base.add(const Duration(days: 5))),
      StreamLink(id: 'late', title: 'l', url: 'u', type: StreamType.koraMatch, createdAt: base, startTime: base.add(const Duration(hours: 5))),
      StreamLink(id: 'early', title: 'e', url: 'u', type: StreamType.koraMatch, createdAt: base, startTime: base.add(const Duration(hours: 1))),
    ];
    final sorted = StreamCubit.applyFilters(list, FilterOption.all, SortOption.dateAdded, '');
    expect(sorted.map((s) => s.id), ['early', 'late', 'new']);

    final byLeague = StreamCubit.applyFilters(
      [list.first.copyWith(league: 'Premier League')],
      FilterOption.all,
      SortOption.dateAdded,
      'premier',
    );
    expect(byLeague, hasLength(1));
  });

  test('isLiveAt covers the match window', () {
    final start = DateTime(2026, 10, 2, 20);
    final s = StreamLink(id: '1', title: 't', url: 'u', type: StreamType.koraMatch, createdAt: start, startTime: start);
    expect(s.isLiveAt(start.subtract(const Duration(minutes: 1))), isFalse);
    expect(s.isLiveAt(start.add(const Duration(minutes: 90))), isTrue);
    expect(s.isLiveAt(start.add(const Duration(hours: 3))), isFalse);
  });
}
