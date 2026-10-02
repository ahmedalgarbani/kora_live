class MatchTeams {
  final String home;
  final String away;

  const MatchTeams(this.home, this.away);

  bool get hasAway => away.isNotEmpty;
}

/// Splits a match title such as "Real Madrid vs Barcelona", "الهلال ضد النصر"
/// or "Arsenal x Chelsea" into its two teams. Titles without a separator are
/// returned as a single team.
MatchTeams parseTeams(String title) {
  final separator = RegExp(
    r'\s+(?:vs\.?|v\.?|ضد|x|×|-|–)\s+',
    caseSensitive: false,
  );
  final match = separator.firstMatch(title);
  if (match == null) return MatchTeams(title.trim(), '');
  return MatchTeams(
    title.substring(0, match.start).trim(),
    title.substring(match.end).trim(),
  );
}

const _wiki = 'https://upload.wikimedia.org/wikipedia';

const Map<List<String>, String> _teamLogos = {
  ['liverpool', 'ليفربول']:
      '$_wiki/en/thumb/0/0c/Liverpool_FC.svg/200px-Liverpool_FC.svg.png',
  ['manchester city', 'man city', 'مانشستر سيتي', 'مان سيتي']:
      '$_wiki/en/thumb/e/eb/Manchester_City_FC_badge.svg/200px-Manchester_City_FC_badge.svg.png',
  ['chelsea', 'تشيلسي']:
      '$_wiki/en/thumb/c/cc/Chelsea_FC.svg/200px-Chelsea_FC.svg.png',
  ['arsenal', 'أرسنال', 'ارسنال']:
      '$_wiki/en/thumb/5/53/Arsenal_FC.svg/200px-Arsenal_FC.svg.png',
  ['real madrid', 'ريال مدريد']:
      '$_wiki/en/thumb/5/56/Real_Madrid_CF.svg/200px-Real_Madrid_CF.svg.png',
  ['barcelona', 'برشلونة']:
      '$_wiki/en/thumb/4/47/FC_Barcelona_%28crest%29.svg/200px-FC_Barcelona_%28crest%29.svg.png',
  // Inter must come before Milan: "inter milan" contains "milan".
  ['inter milan', 'internazionale', 'إنتر', 'انتر']:
      '$_wiki/commons/thumb/0/05/FC_Internazionale_Milano_2021_logo.svg/200px-FC_Internazionale_Milano_2021_logo.svg.png',
  ['ac milan', 'milan', 'ميلان']:
      '$_wiki/commons/thumb/d/d1/AC_Milan_logo.svg/200px-AC_Milan_logo.svg.png',
  ['psg', 'paris saint', 'باريس']:
      '$_wiki/en/thumb/a/a7/Paris_Saint-Germain_F.C..svg/200px-Paris_Saint-Germain_F.C..svg.png',
  ['bayern', 'بايرن']:
      '$_wiki/commons/thumb/1/1b/FC_Bayern_M%C3%BCnchen_logo_%282017%29.svg/200px-FC_Bayern_M%C3%BCnchen_logo_%282017%29.svg.png',
};

const Map<List<String>, String> _channelLogos = {
  ['bein', 'بي ان', 'بين سبورت', 'بي إن']:
      '$_wiki/commons/thumb/c/c5/BeIN_Sports_logo.svg/200px-BeIN_Sports_logo.svg.png',
  ['ssc', 'اس اس سي', 'إس إس سي']:
      '$_wiki/commons/thumb/5/5b/SSC_Logo.svg/200px-SSC_Logo.svg.png',
  ['abu dhabi', 'أبوظبي', 'ابوظبي', 'أبو ظبي']:
      '$_wiki/commons/thumb/c/c5/Abu_Dhabi_Media_logo.svg/200px-Abu_Dhabi_Media_logo.svg.png',
  ['mbc', 'ام بي سي', 'إم بي سي']:
      '$_wiki/commons/thumb/3/3a/MBC_Group_Logo.svg/200px-MBC_Group_Logo.svg.png',
};

String? _lookup(Map<List<String>, String> table, String name) {
  final lower = name.toLowerCase();
  if (lower.trim().isEmpty) return null;
  for (final entry in table.entries) {
    if (entry.key.any(lower.contains)) return entry.value;
  }
  return null;
}

/// Best-effort crest for well known clubs, or null.
String? teamLogoFor(String teamName) => _lookup(_teamLogos, teamName);

/// Best-effort logo for well known channels, or null.
String? channelLogoFor(String channelName) =>
    _lookup(_channelLogos, channelName);
