import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/match_utils.dart';
import '../../domain/entities/stream_link.dart';
import '../blocs/stream/stream_cubit.dart';
import 'common_widgets.dart';
import 'stream_actions.dart';

/// Logo for a stream: the server-provided logo first, then a known
/// club/channel crest, then a gradient initial.
class StreamLogo extends StatelessWidget {
  final StreamLink stream;
  final String? name;
  final double size;

  const StreamLogo({super.key, required this.stream, this.name, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final label = name ?? stream.title;
    final url = name == null
        ? (stream.logoUrl ??
            (stream.isMatch ? teamLogoFor(label) : channelLogoFor(label)))
        : (teamLogoFor(label) ?? (label == stream.title ? stream.logoUrl : null));
    return LogoAvatar(
      url: url,
      name: label,
      size: size,
      fallbackIcon: stream.isMatch ? null : Icons.live_tv,
    );
  }
}

/// Subtitle line describing a stream: league, kick-off, last viewed...
String streamSubtitle(StreamLink stream, {DateTime? now}) {
  final parts = <String>[];
  if (stream.league != null) parts.add(stream.league!);
  if (stream.startTime != null) {
    parts.add(formatKickoff(stream.startTime!, now: now));
  } else if (stream.lastViewedAt != null) {
    parts.add('شوهد ${formatRelative(stream.lastViewedAt!, now: now)}');
  } else {
    parts.add(stream.isMatch ? 'مباراة' : 'قناة تلفزيونية');
  }
  if (stream.allSources.length > 1) {
    parts.add('${stream.allSources.length} سيرفرات');
  }
  return parts.join(' • ');
}

/// Full width list item used in every vertical list.
class StreamListTile extends StatelessWidget {
  final StreamLink stream;

  const StreamListTile({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    final teams = parseTeams(stream.title);
    final isLive = stream.isLiveAt(DateTime.now());
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => openStream(context, stream),
        onLongPress: () => showStreamActions(context, stream),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        borderColor: isLive ? AppColors.live.withValues(alpha: 0.5) : null,
        child: Row(
          children: [
            if (stream.isMatch && teams.hasAway)
              _StackedCrests(stream: stream, teams: teams)
            else
              StreamLogo(stream: stream, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          stream.title,
                          style: text.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLive) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const StatusPill.live(),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (stream.isRemote) ...[
                        const Icon(
                          Icons.cloud_outlined,
                          size: 13,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Text(
                          streamSubtitle(stream),
                          style: text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: stream.isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
              icon: Icon(
                stream.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: stream.isFavorite ? AppColors.favorite : AppColors.textMuted,
              ),
              onPressed: () => context.read<StreamCubit>().toggleFavorite(stream),
            ),
            IconButton(
              tooltip: 'المزيد',
              icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
              onPressed: () => showStreamActions(context, stream),
            ),
          ],
        ),
      ),
    );
  }
}

class _StackedCrests extends StatelessWidget {
  final StreamLink stream;
  final MatchTeams teams;

  const _StackedCrests({required this.stream, required this.teams});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 40,
      child: Stack(
        children: [
          PositionedDirectional(
            start: 0,
            top: 0,
            child: StreamLogo(stream: stream, name: teams.home, size: 28),
          ),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: StreamLogo(stream: stream, name: teams.away, size: 28),
          ),
        ],
      ),
    );
  }
}

/// Compact card for horizontal "matches" rails.
class MatchCard extends StatelessWidget {
  final StreamLink stream;

  const MatchCard({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    final teams = parseTeams(stream.title);
    final isLive = stream.isLiveAt(DateTime.now());
    final small = Theme.of(context).textTheme.labelSmall;

    return SizedBox(
      width: 156,
      child: AppCard(
        onTap: () => openStream(context, stream),
        onLongPress: () => showStreamActions(context, stream),
        borderColor: isLive ? AppColors.live.withValues(alpha: 0.5) : null,
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              height: 20,
              child: isLive
                  ? const StatusPill.live()
                  : Text(
                      stream.startTime != null
                          ? formatKickoff(stream.startTime!)
                          : (stream.league ?? 'مباراة'),
                      style: small,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                StreamLogo(stream: stream, name: teams.home, size: 32),
                if (teams.hasAway) ...[
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  StreamLogo(stream: stream, name: teams.away, size: 32),
                ],
              ],
            ),
            Text(
              teams.hasAway ? '${teams.home} • ${teams.away}' : teams.home,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Square tile for horizontal "channels" rails and the channels grid.
class ChannelTile extends StatelessWidget {
  final StreamLink stream;
  final double size;

  const ChannelTile({super.key, required this.stream, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 12,
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () => openStream(context, stream),
              onLongPress: () => showStreamActions(context, stream),
              child: Center(child: StreamLogo(stream: stream, size: size * 0.6)),
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            stream.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
