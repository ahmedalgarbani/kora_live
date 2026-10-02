import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/match_utils.dart';
import '../../domain/entities/stream_link.dart';
import 'common_widgets.dart';
import 'stream_actions.dart';
import 'stream_cards.dart';

/// Featured matches carousel at the top of the home tab.
class HeroCarousel extends StatefulWidget {
  final List<StreamLink> items;

  const HeroCarousel({super.key, required this.items});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (_index >= items.length && items.isNotEmpty) _index = items.length - 1;

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: _HeroCard(stream: items[i]),
            ),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final StreamLink stream;

  const _HeroCard({required this.stream});

  @override
  Widget build(BuildContext context) {
    final teams = parseTeams(stream.title);
    final isLive = stream.isLiveAt(DateTime.now());

    return Material(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Ink(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: InkWell(
          onTap: () => openStream(context, stream),
          onLongPress: () => showStreamActions(context, stream),
          child: Stack(
            children: [
              // Decorative pitch circle
              PositionedDirectional(
                end: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 18,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (stream.league != null)
                          Expanded(
                            child: Text(
                              stream.league!,
                              style: Theme.of(context).textTheme.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        else
                          const Spacer(),
                        if (isLive)
                          const StatusPill.live(label: 'مباشر الآن')
                        else
                          StatusPill(
                            label: streamSubtitle(stream).split(' • ').last,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _Team(stream: stream, name: teams.home),
                        ),
                        if (teams.hasAway) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text(
                              'VS',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _Team(stream: stream, name: teams.away),
                          ),
                        ],
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs + 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            'شاهد الآن',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Team extends StatelessWidget {
  final StreamLink stream;
  final String name;

  const _Team({required this.stream, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamLogo(stream: stream, name: name, size: 48),
        const SizedBox(height: AppSpacing.xs + 2),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
