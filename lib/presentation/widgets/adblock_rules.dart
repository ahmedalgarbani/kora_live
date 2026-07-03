import 'package:flutter_inappwebview/flutter_inappwebview.dart';

List<ContentBlocker> getAdBlockerRules() {
  return [
    // 1. Block common ad/popup domains
    ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: '.*(google-analytics|doubleclick|googlesyndication|adservice|adnxs|amazon-adsystem|popads|popcash|exoclick|juicyads|propellerads|adsterra|yandex|criteo|pubmatic|rubiconproject|adroll|outbrain|taboola).*',
      ),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.BLOCK,
      ),
    ),
    // 2. Hide common ad containers and popups via CSS display: none
    ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: '.*',
      ),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector: '.ad, .ads, .ad-banner, .adsbox, .ad-placement, .ad-wrapper, '
            '#ad-container, #ad_layer, .popup-ad, #pop-up, '
            'iframe[src*="ad"], iframe[src*="pop"], '
            '[class*="ad-"], [class*="ads-"], [id*="ad-"], [id*="ads-"]',
      ),
    ),
  ];
}

bool isAdOrPopupUrl(String url) {
  final lowerUrl = url.toLowerCase();
  
  // List of common ad networks and popup redirects
  final adPatterns = [
    'google-analytics', 'doubleclick', 'googlesyndication', 'adservice', 'adnxs',
    'amazon-adsystem', 'popads', 'popcash', 'exoclick', 'juicyads', 'propellerads',
    'adsterra', 'yandex', 'criteo', 'pubmatic', 'rubiconproject', 'adroll',
    'outbrain', 'taboola', 'adclick', 'adserver', 'banner', 'clickunder', 
    'traffic', 'redirect', 'click', 'onclick', 'popup', 'popunder', 'promotions',
    'betting', 'casino', 'playstore', 'itunes.apple.com', 'google.play', 'market://',
    'elif.news', 'bit.ly', 'tinyurl', 'shorte.st', 'adf.ly', 'linkbucks',
  ];
  
  for (final pattern in adPatterns) {
    if (lowerUrl.contains(pattern)) {
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
        final currentBase = currentHostParts.sublist(currentHostParts.length - 2).join('.');
        final targetBase = targetHostParts.sublist(targetHostParts.length - 2).join('.');
        if (currentBase == targetBase) {
          return false; // same base domain (allow navigation)
        }
      }
      return true; // completely different domain! (block)
    }
  } catch (_) {}
  return false;
}
