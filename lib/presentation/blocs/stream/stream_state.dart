import '../../../domain/entities/stream_link.dart';
import '../../../domain/entities/sync_result.dart';

enum SortOption {
  dateAdded,
  alphabetical,
  mostPlayed,
  lastPlayed,
}

enum FilterOption {
  all,
  koraMatches,
  tvChannels,
  favorites,
}

sealed class StreamState {
  const StreamState();
}

class StreamInitial extends StreamState {
  const StreamInitial();
}

class StreamLoading extends StreamState {
  const StreamLoading();
}

class StreamLoaded extends StreamState {
  final List<StreamLink> allStreams;
  final List<StreamLink> filteredStreams;
  final SortOption currentSort;
  final FilterOption currentFilter;
  final String searchQuery;
  final bool isSyncing;
  final SyncResult? lastSync;

  /// One-shot error to surface to the user (cleared with `clearError`).
  final String? error;

  const StreamLoaded({
    required this.allStreams,
    required this.filteredStreams,
    required this.currentSort,
    required this.currentFilter,
    required this.searchQuery,
    this.isSyncing = false,
    this.lastSync,
    this.error,
  });

  List<StreamLink> get matches =>
      allStreams.where((s) => s.type == StreamType.koraMatch).toList();

  List<StreamLink> get channels =>
      allStreams.where((s) => s.type == StreamType.tvChannel).toList();

  List<StreamLink> get recentlyWatched {
    final list = allStreams.where((s) => s.lastViewedAt != null).toList()
      ..sort((a, b) => b.lastViewedAt!.compareTo(a.lastViewedAt!));
    return list.take(10).toList();
  }

  StreamLoaded copyWith({
    List<StreamLink>? allStreams,
    List<StreamLink>? filteredStreams,
    SortOption? currentSort,
    FilterOption? currentFilter,
    String? searchQuery,
    bool? isSyncing,
    SyncResult? lastSync,
    String? error,
    bool clearError = false,
  }) {
    return StreamLoaded(
      allStreams: allStreams ?? this.allStreams,
      filteredStreams: filteredStreams ?? this.filteredStreams,
      currentSort: currentSort ?? this.currentSort,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSync: lastSync ?? this.lastSync,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StreamError extends StreamState {
  final String message;
  const StreamError(this.message);
}
