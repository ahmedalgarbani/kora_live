import 'package:flutter_test/flutter_test.dart';
import 'package:kora_live/core/utils/formatters.dart';
import 'package:kora_live/core/utils/match_utils.dart';
import 'package:kora_live/presentation/widgets/adblock_rules.dart';
import 'package:kora_live/presentation/widgets/common_widgets.dart';

void main() {
  group('parseTeams', () {
    test('supports common separators in any case', () {
      for (final title in [
        'Real Madrid vs Barcelona',
        'Real Madrid VS Barcelona',
        'Real Madrid Vs. Barcelona',
        'Real Madrid ضد Barcelona',
        'Real Madrid x Barcelona',
        'Real Madrid - Barcelona',
      ]) {
        final t = parseTeams(title);
        expect(t.home, 'Real Madrid', reason: title);
        expect(t.away, 'Barcelona', reason: title);
      }
    });

    test('keeps titles without a separator intact', () {
      final t = parseTeams('Paris Saint-Germain');
      expect(t.home, 'Paris Saint-Germain');
      expect(t.hasAway, isFalse);
      // "Vasco" must not be split on the "vs"-like prefix.
      expect(parseTeams('Vasco da Gama').hasAway, isFalse);
    });
  });

  test('logo lookup prefers the most specific club', () {
    expect(teamLogoFor('Inter Milan'), contains('Internazionale'));
    expect(teamLogoFor('انتر ميلان'), contains('Internazionale'));
    expect(teamLogoFor('AC Milan'), contains('AC_Milan'));
    expect(teamLogoFor('Unknown FC'), isNull);
    expect(channelLogoFor('beIN Sports 1'), contains('BeIN'));
  });

  test('initials skip the Arabic article', () {
    expect(initialOf('الهلال'), 'ه');
    expect(initialOf('النصر'), 'ن');
    expect(initialOf('real madrid'), 'R');
    expect(initialOf('  '), '?');
    expect(initialOf('ال'), 'ا');
  });

  group('adblock helpers', () {
    test('matches ad hosts, not paths', () {
      expect(isAdOrPopupUrl('https://ads.doubleclick.net/x'), isTrue);
      expect(isAdOrPopupUrl('https://doubleclick.net'), isTrue);
      expect(isAdOrPopupUrl('https://example.com/doubleclick.net'), isFalse);
      expect(isAdOrPopupUrl('https://notdoubleclick.net'), isFalse);
    });

    test('content blocker regex only targets ad hosts', () {
      final rule = getAdBlockerRules().first.trigger.urlFilter;
      final regex = RegExp(rule);
      expect(regex.hasMatch('https://pagead2.googlesyndication.com/x.js'), isTrue);
      expect(regex.hasMatch('https://popads.net'), isTrue);
      expect(regex.hasMatch('https://cdn.example.com/upload/player.js'), isFalse);
      expect(regex.hasMatch('https://example.com/?ref=doubleclick.net'), isFalse);
    });

    test('external schemes are detected', () {
      expect(isExternalSchemeUrl('intent://scan/#Intent;end'), isTrue);
      expect(isExternalSchemeUrl('market://details?id=x'), isTrue);
      expect(isExternalSchemeUrl('https://a.com'), isFalse);
      expect(isExternalSchemeUrl('about:blank'), isFalse);
    });

    test('redirect detection uses the registrable domain', () {
      expect(baseDomain('m.bein.com'), 'bein.com');
      expect(baseDomain('live.example.co.uk'), 'example.co.uk');
      expect(baseDomain('tv.example.com.sa'), 'example.com.sa');
      expect(isRedirectToDifferentDomain('https://m.bein.com', 'https://www.bein.com/x'), isFalse);
      expect(isRedirectToDifferentDomain('https://a.example.co.uk', 'https://b.other.co.uk'), isTrue);
      expect(isRedirectToDifferentDomain('https://a.com', 'https://ads.b.com'), isTrue);
      expect(isRedirectToDifferentDomain('about:blank', 'https://b.com'), isFalse);
    });
  });

  group('formatters', () {
    test('clock uses Arabic am/pm', () {
      expect(formatClock(DateTime(2026, 1, 1, 0, 5)), '12:05 ص');
      expect(formatClock(DateTime(2026, 1, 1, 12, 0)), '12:00 م');
      expect(formatClock(DateTime(2026, 1, 1, 21, 30)), '9:30 م');
    });

    test('kickoff and relative labels', () {
      final now = DateTime(2026, 10, 2, 12);
      expect(formatKickoff(DateTime(2026, 10, 2, 21), now: now), 'اليوم 9:00 م');
      expect(formatKickoff(DateTime(2026, 10, 3, 20), now: now), 'غداً 8:00 م');
      expect(formatRelative(now.subtract(const Duration(seconds: 5)), now: now), 'الآن');
      expect(formatRelative(now.subtract(const Duration(minutes: 2)), now: now), 'منذ دقيقتين');
      expect(formatRelative(now.subtract(const Duration(hours: 5)), now: now), 'منذ 5 ساعات');
    });
  });
}
