import 'package:flutter_inappwebview/flutter_inappwebview.dart';

List<ContentBlocker> getAdBlockerRules() {
  return [
    // 1. Block common ad/popup domains
    ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter:
            '.*(google-analytics|doubleclick|googlesyndication|adservice|adnxs|amazon-adsystem|popads|popcash|exoclick|juicyads|propellerads|adsterra|yandex|criteo|pubmatic|rubiconproject|adroll|outbrain|taboola).*',
      ),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    ),
    // 2. Hide common ad containers and popups via CSS display: none
    ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: '.*'),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector:
            '.ad, .ads, .ad-banner, .adsbox, .ad-placement, .ad-wrapper, '
            '#ad-container, #ad_layer, .popup-ad, #pop-up, '
            'iframe[src*="ad"], iframe[src*="pop"], '
            '[class*="ad-"], [class*="ads-"], [id*="ad-"], [id*="ads-"]',
      ),
    ),
  ];
}

bool isAdOrPopupUrl(String url) {
  final uri = Uri.tryParse(url.toLowerCase());
  if (uri == null || uri.host.isEmpty) return false;

  final host = uri.host;

  // Specific ad network DOMAINS to block (match host, not full URL)
  final adDomains = [
    'doubleclick.net',
    'googlesyndication.com',
    'google-analytics.com',
    'adservice.google.com',
    'adnxs.com',
    'amazon-adsystem.com',
    'popads.net',
    'popcash.net',
    'exoclick.com',
    'juicyads.com',
    'propellerads.com',
    'adsterra.com',
    'criteo.com',
    'pubmatic.com',
    'rubiconproject.com',
    'adroll.com',
    'outbrain.com',
    'taboola.com',
    'adf.ly',
    'shorte.st',
    'linkbucks.com',
    'popunder.net',
    'clickadu.com',
    'hilltopads.com',
    'trafficjunky.com',
    'trafficfactory.biz',
  ];

  for (final domain in adDomains) {
    if (host == domain || host.endsWith('.$domain')) {
      return true;
    }
  }
  return false;
}

bool isRedirectToDifferentDomain(String currentUrl, String targetUrl) {
  try {
    final currentUri = Uri.parse(currentUrl);
    final targetUri = Uri.parse(targetUrl);

    // Allow empty or invalid target hosts to be checked elsewhere, but block if host changes completely
    if (targetUri.host.isNotEmpty && currentUri.host != targetUri.host) {
      // Check if they share base domain (e.g. m.bein.com and bein.com)
      final currentHostParts = currentUri.host.split('.');
      final targetHostParts = targetUri.host.split('.');

      if (currentHostParts.length >= 2 && targetHostParts.length >= 2) {
        final currentBase = currentHostParts
            .sublist(currentHostParts.length - 2)
            .join('.');
        final targetBase = targetHostParts
            .sublist(targetHostParts.length - 2)
            .join('.');
        if (currentBase == targetBase) {
          return false; // same base domain (allow navigation)
        }
      }
      return true; // completely different domain! (block)
    }
  } catch (_) {}
  return false;
}
