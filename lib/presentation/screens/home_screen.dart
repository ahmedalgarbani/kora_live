import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/colors.dart';
import '../../domain/entities/stream_link.dart';
import '../blocs/settings/settings_cubit.dart';
import '../blocs/settings/settings_state.dart';
import '../blocs/stream/stream_cubit.dart';
import '../blocs/stream/stream_state.dart';
import '../widgets/add_stream_sheet.dart';
import '../widgets/common_widgets.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/stream_actions.dart';
import '../widgets/stream_cards.dart';
import 'settings_screen.dart';
import 'stream_search_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _settingsTab = 4;
  int _tab = 0;
  bool _autoSyncDone = false;

  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettings();
    context.read<StreamCubit>().loadStreams();
  }

  void _maybeAutoSync(SettingsState state) {
    if (_autoSyncDone || state is! SettingsLoaded) return;
    _autoSyncDone = true;
    final s = state.settings;
    if (s.autoSync && s.hasServer) {
      context.read<StreamCubit>().syncWithServer(s.serverUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsCubit, SettingsState>(
          listener: (context, state) => _maybeAutoSync(state),
        ),
        BlocListener<StreamCubit, StreamState>(
          listenWhen: (prev, curr) =>
              curr is StreamLoaded &&
              curr.error != null &&
              (prev is! StreamLoaded || prev.error != curr.error),
          listener: (context, state) {
            final error = (state as StreamLoaded).error!;
            showSnack(context, error);
            context.read<StreamCubit>().clearError();
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tab,
            children: [
              _FeedTab(onOpenTab: (i) => setState(() => _tab = i)),
              const StreamListTab(
                title: 'المباريات',
                filter: FilterOption.koraMatches,
                emptyIcon: Icons.sports_soccer,
                emptyTitle: 'لا توجد مباريات بعد',
              ),
              const StreamListTab(
                title: 'القنوات',
                filter: FilterOption.tvChannels,
                emptyIcon: Icons.live_tv,
                emptyTitle: 'لا توجد قنوات بعد',
                grid: true,
              ),
              const StreamListTab(
                title: 'المفضلة',
                filter: FilterOption.favorites,
                emptyIcon: Icons.star_border_rounded,
                emptyTitle: 'لا توجد عناصر مفضلة',
                emptyMessage: 'اضغط على النجمة بجانب أي مباراة أو قناة لإضافتها هنا',
              ),
              const SettingsScreen(),
            ],
          ),
        ),
        floatingActionButton: _tab == _settingsTab
            ? null
            : FloatingActionButton(
                tooltip: 'إضافة رابط',
                onPressed: () => showAddStreamSheet(context),
                child: const Icon(Icons.add),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'الرئيسية',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_soccer_outlined),
              selectedIcon: Icon(Icons.sports_soccer),
              label: 'المباريات',
            ),
            NavigationDestination(
              icon: Icon(Icons.live_tv_outlined),
              selectedIcon: Icon(Icons.live_tv),
              label: 'القنوات',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_border_rounded),
              selectedIcon: Icon(Icons.star_rounded),
              label: 'المفضلة',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

/// Pull-to-refresh: sync from the server when configured, else reload.
Future<void> refreshStreams(BuildContext context) async {
  final settingsState = context.read<SettingsCubit>().state;
  final cubit = context.read<StreamCubit>();
  if (settingsState is SettingsLoaded && settingsState.settings.hasServer) {
    final result = await cubit.syncWithServer(settingsState.settings.serverUrl);
    if (result != null && context.mounted) {
      showSnack(context, 'تم التحديث: ${result.total} رابط من السيرفر');
    }
  } else {
    await cubit.loadStreams();
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Kora ',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: 'Live',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'بحث',
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () => showSearch(
              context: context,
              delegate: StreamSearchDelegate(context.read<StreamCubit>()),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const _FeedTab({required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StreamCubit, StreamState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => refreshStreams(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: _AppHeader()),
              ..._content(context, state),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, StreamState state) {
    switch (state) {
      case StreamInitial() || StreamLoading():
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case StreamError(:final message):
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'حدث خطأ أثناء تحميل الروابط',
              message: message,
              action: OutlinedButton.icon(
                onPressed: () => context.read<StreamCubit>().loadStreams(),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ),
          ),
        ];
      case StreamLoaded():
        return _loaded(context, state);
    }
  }

  List<Widget> _loaded(BuildContext context, StreamLoaded state) {
    final banner = _SyncBanner(state: state);

    if (state.allStreams.isEmpty) {
      return [
        SliverToBoxAdapter(child: banner),
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.stadium_outlined,
            title: 'لا توجد روابط بعد',
            message: 'أضف رابط مباراة أو قناة، أو اربط التطبيق بسيرفر لجلب الروابط تلقائياً.',
            action: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(140, 44)),
                  onPressed: () => showAddStreamSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة رابط'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onOpenTab(4),
                  icon: const Icon(Icons.cloud_sync_outlined),
                  label: const Text('ربط سيرفر'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final now = DateTime.now();
    final matches = state.matches;
    final channels = state.channels;
    final recent = state.recentlyWatched;
    final featured = _featured(matches, now);

    return [
      SliverToBoxAdapter(child: banner),
      if (featured.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: HeroCarousel(items: featured),
          ),
        ),
      if (recent.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: SectionHeader(
            title: 'تابع المشاهدة',
            icon: Icons.history_rounded,
            iconColor: AppColors.accent,
          ),
        ),
        SliverToBoxAdapter(
          child: _Rail(
            height: 110,
            children: [for (final s in recent) ChannelTile(stream: s)],
          ),
        ),
      ],
      if (matches.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'المباريات',
            icon: Icons.sensors,
            actionLabel: 'عرض الكل',
            onAction: () => onOpenTab(1),
          ),
        ),
        SliverToBoxAdapter(
          child: _Rail(
            height: 128,
            children: [
              for (final m in StreamCubit.applyFilters(
                matches,
                FilterOption.all,
                SortOption.dateAdded,
                '',
              ))
                MatchCard(stream: m),
            ],
          ),
        ),
      ],
      if (channels.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'القنوات',
            icon: Icons.live_tv,
            iconColor: AppColors.accent,
            actionLabel: 'عرض الكل',
            onAction: () => onOpenTab(2),
          ),
        ),
        SliverToBoxAdapter(
          child: _Rail(
            height: 110,
            children: [for (final c in channels) ChannelTile(stream: c)],
          ),
        ),
      ],
      const SliverToBoxAdapter(
        child: SectionHeader(title: 'كل الروابط', icon: Icons.list_rounded),
      ),
      SliverToBoxAdapter(child: _FilterBar(state: state)),
      if (state.filteredStreams.isEmpty)
        const SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: 'لا توجد روابط في هذا القسم',
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList.builder(
            itemCount: state.filteredStreams.length,
            itemBuilder: (context, i) =>
                StreamListTile(stream: state.filteredStreams[i]),
          ),
        ),
    ];
  }

  /// Live matches first, then upcoming today, falling back to the newest.
  static List<StreamLink> _featured(List<StreamLink> matches, DateTime now) {
    final live = matches.where((m) => m.isLiveAt(now)).toList();
    final upcoming = matches
        .where((m) =>
            m.startTime != null &&
            m.startTime!.isAfter(now) &&
            m.startTime!.difference(now) < const Duration(hours: 24))
        .toList()
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));
    final picked = [...live, ...upcoming];
    if (picked.isEmpty) {
      picked.addAll(
        [...matches]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
    return picked.take(5).toList();
  }
}

class _Rail extends StatelessWidget {
  final double height;
  final List<Widget> children;

  const _Rail({required this.height, required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final StreamLoaded state;

  const _SyncBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final message = state.lastSync?.message;
    if (!state.isSyncing && message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: AppCard(
        borderColor: AppColors.accent.withValues(alpha: 0.4),
        child: Row(
          children: [
            if (state.isSyncing)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            else
              const Icon(Icons.campaign_outlined, color: AppColors.accent, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                state.isSyncing ? 'جاري جلب أحدث الروابط من السيرفر...' : message!,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _sortLabels = {
  SortOption.dateAdded: 'الأحدث',
  SortOption.alphabetical: 'أبجدياً',
  SortOption.mostPlayed: 'الأكثر مشاهدة',
  SortOption.lastPlayed: 'آخر مشاهدة',
};

class _SortButton extends StatelessWidget {
  final SortOption current;

  const _SortButton({required this.current});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      tooltip: 'ترتيب',
      initialValue: current,
      onSelected: context.read<StreamCubit>().changeSort,
      itemBuilder: (_) => [
        for (final e in _sortLabels.entries)
          PopupMenuItem(value: e.key, child: Text(e.value)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _sortLabels[current]!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final StreamLoaded state;

  const _FilterBar({required this.state});

  static const _labels = {
    FilterOption.all: ('الكل', Icons.grid_view_rounded),
    FilterOption.koraMatches: ('مباريات', Icons.sports_soccer),
    FilterOption.tvChannels: ('قنوات', Icons.live_tv),
    FilterOption.favorites: ('المفضلة', Icons.star_rounded),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
              children: [
                for (final e in _labels.entries)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                    child: _FilterChip(
                      label: e.value.$1,
                      icon: e.value.$2,
                      selected: state.currentFilter == e.key,
                      onTap: () => context.read<StreamCubit>().changeFilter(e.key),
                    ),
                  ),
              ],
            ),
          ),
          _SortButton(current: state.currentSort),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textSecondary;
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg - 2,
            vertical: AppSpacing.sm - 1,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.cardFill,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full tab listing one category (matches, channels or favorites), with its
/// own inline search and the shared sort order.
class StreamListTab extends StatefulWidget {
  final String title;
  final FilterOption filter;
  final IconData emptyIcon;
  final String emptyTitle;
  final String? emptyMessage;
  final bool grid;

  const StreamListTab({
    super.key,
    required this.title,
    required this.filter,
    required this.emptyIcon,
    required this.emptyTitle,
    this.emptyMessage,
    this.grid = false,
  });

  @override
  State<StreamListTab> createState() => _StreamListTabState();
}

class _StreamListTabState extends State<StreamListTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StreamCubit, StreamState>(
      builder: (context, state) {
        if (state is! StreamLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = StreamCubit.applyFilters(
          state.allStreams,
          widget.filter,
          state.currentSort,
          _search.text,
        );
        final hasAny = StreamCubit.applyFilters(
          state.allStreams,
          widget.filter,
          state.currentSort,
          '',
        ).isNotEmpty;

        return RefreshIndicator(
          onRefresh: () => refreshStreams(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      _SortButton(current: state.currentSort),
                    ],
                  ),
                ),
              ),
              if (hasAny)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'ابحث في ${widget.title}...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح',
                                icon: const Icon(Icons.close),
                                onPressed: () => setState(_search.clear),
                              ),
                      ),
                    ),
                  ),
                ),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: hasAny ? Icons.search_off : widget.emptyIcon,
                    title: hasAny ? 'لا توجد نتائج مطابقة' : widget.emptyTitle,
                    message: hasAny ? null : widget.emptyMessage,
                  ),
                )
              else if (widget.grid)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 104,
                      mainAxisExtent: 112,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Center(child: ChannelTile(stream: items[i])),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) => StreamListTile(stream: items[i]),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        );
      },
    );
  }
}
