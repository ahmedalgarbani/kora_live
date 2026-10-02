import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/stream_link.dart';
import '../../../domain/entities/sync_result.dart';
import '../../../domain/usecases/stream_usecases.dart';
import 'stream_state.dart';

class StreamCubit extends Cubit<StreamState> {
  final GetStreamLinks getStreamLinksUseCase;
  final AddStreamLink addStreamLinkUseCase;
  final UpdateStreamLink updateStreamLinkUseCase;
  final DeleteStreamLink deleteStreamLinkUseCase;
  final ToggleFavoriteStreamLink toggleFavoriteStreamLinkUseCase;
  final IncrementPlayCount incrementPlayCountUseCase;
  final SyncRemoteStreams syncRemoteStreamsUseCase;
  final GetLastSync getLastSyncUseCase;

  StreamCubit({
    required this.getStreamLinksUseCase,
    required this.addStreamLinkUseCase,
    required this.updateStreamLinkUseCase,
    required this.deleteStreamLinkUseCase,
    required this.toggleFavoriteStreamLinkUseCase,
    required this.incrementPlayCountUseCase,
    required this.syncRemoteStreamsUseCase,
    required this.getLastSyncUseCase,
  }) : super(const StreamInitial());

  Future<void> loadStreams() async {
    final currentState = state;
    if (currentState is! StreamLoaded) emit(const StreamLoading());

    try {
      final streams = await getStreamLinksUseCase();
      final now = state;
      if (now is StreamLoaded) {
        emit(now.copyWith(
          allStreams: streams,
          filteredStreams: applyFilters(
            streams,
            now.currentFilter,
            now.currentSort,
            now.searchQuery,
          ),
        ));
      } else {
        final lastSync = await getLastSyncUseCase();
        emit(StreamLoaded(
          allStreams: streams,
          filteredStreams: applyFilters(
            streams,
            FilterOption.all,
            SortOption.dateAdded,
            '',
          ),
          currentSort: SortOption.dateAdded,
          currentFilter: FilterOption.all,
          searchQuery: '',
          lastSync: lastSync,
        ));
      }
    } catch (e) {
      _fail(e);
    }
  }

  /// Fetches links from the server. Returns the result, or null on failure
  /// (the failure reason is exposed through [StreamLoaded.error]).
  Future<SyncResult?> syncWithServer(String serverUrl) async {
    if (state is! StreamLoaded) await loadStreams();
    final current = state;
    if (current is! StreamLoaded || current.isSyncing) return null;
    if (serverUrl.trim().isEmpty) return null;

    emit(current.copyWith(isSyncing: true, clearError: true));
    try {
      final result = await syncRemoteStreamsUseCase(serverUrl);
      final loaded = state;
      if (loaded is StreamLoaded) {
        emit(loaded.copyWith(isSyncing: false, lastSync: result));
      }
      await loadStreams();
      return result;
    } catch (e) {
      final loaded = state;
      if (loaded is StreamLoaded) {
        emit(loaded.copyWith(isSyncing: false, error: e.toString()));
      }
      return null;
    }
  }

  Future<void> addNewStream(
    String title,
    String url,
    StreamType type, {
    List<StreamMirror> mirrors = const [],
  }) async {
    final now = DateTime.now();
    await _run(() => addStreamLinkUseCase(StreamLink(
          id: now.microsecondsSinceEpoch.toString(),
          title: title,
          url: url,
          type: type,
          createdAt: now,
          mirrors: mirrors,
        )));
  }

  Future<void> editStream(StreamLink stream) async {
    await _run(() => updateStreamLinkUseCase(stream));
  }

  Future<void> removeStream(String id) async {
    await _run(() => deleteStreamLinkUseCase(id));
  }

  /// Puts back a stream removed with [removeStream] (used by "undo").
  Future<void> restoreStream(StreamLink stream) async {
    await _run(() => addStreamLinkUseCase(stream));
  }

  Future<void> toggleFavorite(StreamLink stream) async {
    await _run(() => toggleFavoriteStreamLinkUseCase(stream));
  }

  Future<void> recordPlay(StreamLink stream) async {
    await _run(() => incrementPlayCountUseCase(stream));
  }

  /// Resets the watch history (play counts and last viewed dates).
  Future<void> clearHistory() async {
    final current = state;
    if (current is! StreamLoaded) return;
    await _run(() async {
      for (final s in current.allStreams) {
        if (s.playCount == 0 && s.lastViewedAt == null) continue;
        await updateStreamLinkUseCase(StreamLink(
          id: s.id,
          title: s.title,
          url: s.url,
          type: s.type,
          isFavorite: s.isFavorite,
          createdAt: s.createdAt,
          source: s.source,
          mirrors: s.mirrors,
          league: s.league,
          logoUrl: s.logoUrl,
          startTime: s.startTime,
        ));
      }
    });
  }

  void clearError() {
    final current = state;
    if (current is StreamLoaded && current.error != null) {
      emit(current.copyWith(clearError: true));
    }
  }

  void changeFilter(FilterOption filter) {
    final currentState = state;
    if (currentState is StreamLoaded) {
      emit(currentState.copyWith(
        currentFilter: filter,
        filteredStreams: applyFilters(
          currentState.allStreams,
          filter,
          currentState.currentSort,
          currentState.searchQuery,
        ),
      ));
    }
  }

  void changeSort(SortOption sort) {
    final currentState = state;
    if (currentState is StreamLoaded) {
      emit(currentState.copyWith(
        currentSort: sort,
        filteredStreams: applyFilters(
          currentState.allStreams,
          currentState.currentFilter,
          sort,
          currentState.searchQuery,
        ),
      ));
    }
  }

  void searchStreams(String query) {
    final currentState = state;
    if (currentState is StreamLoaded) {
      emit(currentState.copyWith(
        searchQuery: query,
        filteredStreams: applyFilters(
          currentState.allStreams,
          currentState.currentFilter,
          currentState.currentSort,
          query,
        ),
      ));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await loadStreams();
    } catch (e) {
      _fail(e);
    }
  }

  void _fail(Object e) {
    final current = state;
    if (current is StreamLoaded) {
      emit(current.copyWith(error: e.toString()));
    } else {
      emit(StreamError(e.toString()));
    }
  }

  static List<StreamLink> applyFilters(
    List<StreamLink> list,
    FilterOption filter,
    SortOption sort,
    String query,
  ) {
    // 1. Filter
    Iterable<StreamLink> result = list;
    switch (filter) {
      case FilterOption.all:
        break;
      case FilterOption.koraMatches:
        result = result.where((e) => e.type == StreamType.koraMatch);
        break;
      case FilterOption.tvChannels:
        result = result.where((e) => e.type == StreamType.tvChannel);
        break;
      case FilterOption.favorites:
        result = result.where((e) => e.isFavorite);
        break;
    }

    // 2. Search (title, league or URL)
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((e) =>
          e.title.toLowerCase().contains(q) ||
          (e.league?.toLowerCase().contains(q) ?? false) ||
          e.url.toLowerCase().contains(q));
    }

    // 3. Sort
    final List<StreamLink> sortedList = result.toList();
    switch (sort) {
      case SortOption.dateAdded:
        sortedList.sort((a, b) {
          // Scheduled matches first, ordered by kick-off time.
          final sa = a.startTime, sb = b.startTime;
          if (sa != null && sb != null) return sa.compareTo(sb);
          if (sa != null) return -1;
          if (sb != null) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case SortOption.alphabetical:
        sortedList.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.mostPlayed:
        sortedList.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case SortOption.lastPlayed:
        sortedList.sort((a, b) {
          if (a.lastViewedAt == null && b.lastViewedAt == null) {
            return b.createdAt.compareTo(a.createdAt);
          }
          if (a.lastViewedAt == null) return 1;
          if (b.lastViewedAt == null) return -1;
          return b.lastViewedAt!.compareTo(a.lastViewedAt!);
        });
        break;
    }

    return sortedList;
  }
}
