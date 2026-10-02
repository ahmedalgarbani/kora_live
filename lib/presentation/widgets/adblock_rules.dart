import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Ad / popup network domains. Matched against the host only, so a page path
/// that merely contains one of these words is never blocked.
const List<String> adDomains = [
  'doubleclick.net',
  'googlesyndication.com',
  'google-analytics.com',
  'googletagservices.com',
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
  'onclickads.net',
  'onclkds.com',
  'adcash.com',
  'mgid.com',
  'revcontent.com',
  'a-ads.com',
];

List<ContentBlocker> getAdBlockerRules() {
  final domainPattern = adDomains
      .map((d) => d.replaceAll('.', r'\.'))
      .join('|');
  return [
    // 1. Block requests to known ad/popup hosts (scheme://[sub.]domain/...)
    ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: '^https?://([^/]+\\.)?($domainPattern)([:/?#]|\$)',
      ),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    ),
    // 2. Hide common ad containers. Selectors are deliberately specific:
    // broad patterns like [class*="ad-"] also match "header-", "download-"
    // or "loading-" and break the video player on many sites.
    ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: '.*'),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector:
            '.ad, .ads, .adsbygoogle, ins.adsbygoogle, .ad-banner, .adsbox, '
            '.ad-placement, .ad-wrapper, .ad-container, .popup-ad, '
            '#ad-container, #ad_layer, #pop-up, [id^="div-gpt-ad"], '
            'iframe[id^="google_ads"], iframe[src*="doubleclick.net"], '
            'iframe[src*="googlesyndication.com"]',
      ),
    ),
  ];
}

bool isAdOrPopupUrl(String url) {
  final uri = Uri.tryParse(url.toLowerCase());
  if (uri == null || uri.host.isEmpty) return false;

  final host = uri.host;
  for (final domain in adDomains) {
    if (host == domain || host.endsWith('.$domain')) {
      return true;
    }
  }
  return false;
}

/// Navigation to a non-web scheme (intent://, market://, tg://...) — these are
/// almost always ads trying to leave the app, and the WebView can't open them.
bool isExternalSchemeUrl(String url) {
  final scheme = Uri.tryParse(url)?.scheme.toLowerCase() ?? '';
  const allowed = {'http', 'https', 'about', 'data', 'blob', 'javascript', ''};
  return !allowed.contains(scheme);
}

/// Registrable domain approximation: `m.bein.com` → `bein.com`,
/// `live.example.co.uk` → `example.co.uk`.
String baseDomain(String host) {
  final parts = host.toLowerCase().split('.');
  if (parts.length <= 2) return parts.join('.');
  const secondLevel = {'co', 'com', 'net', 'org', 'gov', 'edu', 'ac'};
  final take =
      secondLevel.contains(parts[parts.length - 2]) && parts.last.length == 2
          ? 3
          : 2;
  return parts.sublist(parts.length - take).join('.');
}

bool isRedirectToDifferentDomain(String currentUrl, String targetUrl) {
  final currentUri = Uri.tryParse(currentUrl);
  final targetUri = Uri.tryParse(targetUrl);
  if (currentUri == null || targetUri == null) return false;

  // Nothing to compare against (e.g. about:blank on first load).
  if (currentUri.host.isEmpty || targetUri.host.isEmpty) return false;
  if (currentUri.host == targetUri.host) return false;

  return baseDomain(currentUri.host) != baseDomain(targetUri.host);
}
