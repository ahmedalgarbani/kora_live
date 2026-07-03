import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/stream_link.dart';
import '../../../domain/usecases/stream_usecases.dart';
import 'stream_state.dart';

class StreamCubit extends Cubit<StreamState> {
  final GetStreamLinks getStreamLinksUseCase;
  final AddStreamLink addStreamLinkUseCase;
  final DeleteStreamLink deleteStreamLinkUseCase;
  final ToggleFavoriteStreamLink toggleFavoriteStreamLinkUseCase;
  final IncrementPlayCount incrementPlayCountUseCase;

  StreamCubit({
    required this.getStreamLinksUseCase,
    required this.addStreamLinkUseCase,
    required this.deleteStreamLinkUseCase,
    required this.toggleFavoriteStreamLinkUseCase,
    required this.incrementPlayCountUseCase,
  }) : super(const StreamInitial());

  Future<void> loadStreams() async {
    final currentState = state;
    SortOption sort = SortOption.dateAdded;
    FilterOption filter = FilterOption.all;
    String query = '';

    if (currentState is StreamLoaded) {
      sort = currentState.currentSort;
      filter = currentState.currentFilter;
      query = currentState.searchQuery;
    } else {
      emit(const StreamLoading());
    }

    try {
      final streams = await getStreamLinksUseCase();
      final filtered = _processStreams(streams, filter, sort, query);
      emit(StreamLoaded(
        allStreams: streams,
        filteredStreams: filtered,
        currentSort: sort,
        currentFilter: filter,
        searchQuery: query,
      ));
    } catch (e) {
      emit(StreamError(e.toString()));
    }
  }

  Future<void> addNewStream(String title, String url, StreamType type) async {
    try {
      final newStream = StreamLink(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        url: url,
        type: type,
        createdAt: DateTime.now(),
      );
      await addStreamLinkUseCase(newStream);
      await loadStreams();
    } catch (e) {
      emit(StreamError(e.toString()));
    }
  }

  Future<void> removeStream(String id) async {
    try {
      await deleteStreamLinkUseCase(id);
      await loadStreams();
    } catch (e) {
      emit(StreamError(e.toString()));
    }
  }

  Future<void> toggleFavorite(StreamLink stream) async {
    try {
      await toggleFavoriteStreamLinkUseCase(stream);
      await loadStreams();
    } catch (e) {
      emit(StreamError(e.toString()));
    }
  }

  Future<void> recordPlay(StreamLink stream) async {
    try {
      await incrementPlayCountUseCase(stream);
      await loadStreams();
    } catch (e) {
      emit(StreamError(e.toString()));
    }
  }

  void changeFilter(FilterOption filter) {
    final currentState = state;
    if (currentState is StreamLoaded) {
      final filtered = _processStreams(
        currentState.allStreams,
        filter,
        currentState.currentSort,
        currentState.searchQuery,
      );
      emit(currentState.copyWith(
        currentFilter: filter,
        filteredStreams: filtered,
      ));
    }
  }

  void changeSort(SortOption sort) {
    final currentState = state;
    if (currentState is StreamLoaded) {
      final filtered = _processStreams(
        currentState.allStreams,
        currentState.currentFilter,
        sort,
        currentState.searchQuery,
      );
      emit(currentState.copyWith(
        currentSort: sort,
        filteredStreams: filtered,
      ));
    }
  }

  void searchStreams(String query) {
    final currentState = state;
    if (currentState is StreamLoaded) {
      final filtered = _processStreams(
        currentState.allStreams,
        currentState.currentFilter,
        currentState.currentSort,
        query,
      );
      emit(currentState.copyWith(
        searchQuery: query,
        filteredStreams: filtered,
      ));
    }
  }

  List<StreamLink> _processStreams(
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

    // 2. Search
    if (query.trim().isNotEmpty) {
      final lower = query.toLowerCase();
      result = result.where((e) =>
          e.title.toLowerCase().contains(lower) ||
          e.url.toLowerCase().contains(lower));
    }

    // 3. Sort
    final List<StreamLink> sortedList = result.toList();
    switch (sort) {
      case SortOption.dateAdded:
        sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.alphabetical:
        sortedList.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.mostPlayed:
        sortedList.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case SortOption.lastPlayed:
        sortedList.sort((a, b) {
          if (a.lastViewedAt == null && b.lastViewedAt == null) return b.createdAt.compareTo(a.createdAt);
          if (a.lastViewedAt == null) return 1;
          if (b.lastViewedAt == null) return -1;
          return b.lastViewedAt!.compareTo(a.lastViewedAt!);
        });
        break;
    }

    return sortedList;
  }
}
