import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/colors.dart';
import '../blocs/stream/stream_cubit.dart';
import '../blocs/stream/stream_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/stream_cards.dart';

/// Global search across every match and channel.
class StreamSearchDelegate extends SearchDelegate<void> {
  final StreamCubit cubit;

  StreamSearchDelegate(this.cubit)
      : super(searchFieldLabel: 'ابحث عن مباراة أو قناة...');

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            tooltip: 'مسح',
            icon: const Icon(Icons.close),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => BackButton(
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _results();

  @override
  Widget buildSuggestions(BuildContext context) => _results();

  Widget _results() {
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<StreamCubit, StreamState>(
        builder: (context, state) {
          if (state is! StreamLoaded) return const SizedBox.shrink();
          if (query.trim().isEmpty) {
            return const EmptyState(
              icon: Icons.search,
              title: 'اكتب اسم فريق أو قناة أو دوري',
            );
          }
          final results = StreamCubit.applyFilters(
            state.allStreams,
            FilterOption.all,
            state.currentSort,
            query,
          );
          if (results.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              title: 'لا توجد نتائج مطابقة',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: results.length,
            itemBuilder: (_, i) => StreamListTile(stream: results[i]),
          );
        },
      ),
    );
  }
}
