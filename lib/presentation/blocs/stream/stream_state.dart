import '../../../domain/entities/stream_link.dart';

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

  const StreamLoaded({
    required this.allStreams,
    required this.filteredStreams,
    required this.currentSort,
    required this.currentFilter,
    required this.searchQuery,
  });

  StreamLoaded copyWith({
    List<StreamLink>? allStreams,
    List<StreamLink>? filteredStreams,
    SortOption? currentSort,
    FilterOption? currentFilter,
    String? searchQuery,
  }) {
    return StreamLoaded(
      allStreams: allStreams ?? this.allStreams,
      filteredStreams: filteredStreams ?? this.filteredStreams,
      currentSort: currentSort ?? this.currentSort,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class StreamError extends StreamState {
  final String message;
  const StreamError(this.message);
}
