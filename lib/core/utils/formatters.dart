/// Formats a time as "9:05 م" / "10:30 ص".
String formatClock(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'م' : 'ص';
  return '$hour:$minute $period';
}

/// Human friendly relative time in Arabic ("الآن", "منذ 5 دقائق", ...).
String formatRelative(DateTime dateTime, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(dateTime);
  if (diff.inSeconds < 60) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${_plural(diff.inMinutes, 'دقيقة', 'دقيقتين', 'دقائق')}';
  if (diff.inHours < 24) return 'منذ ${_plural(diff.inHours, 'ساعة', 'ساعتين', 'ساعات')}';
  if (diff.inDays < 30) return 'منذ ${_plural(diff.inDays, 'يوم', 'يومين', 'أيام')}';
  return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
}

/// Kick-off label: "اليوم 9:00 م", "غداً 8:00 م" or a date.
String formatKickoff(DateTime start, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(start.year, start.month, start.day);
  final days = day.difference(today).inDays;
  final clock = formatClock(start);
  if (days == 0) return 'اليوم $clock';
  if (days == 1) return 'غداً $clock';
  if (days == -1) return 'أمس $clock';
  return '${start.day}/${start.month} $clock';
}

String _plural(int n, String one, String two, String few) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n <= 10) return '$n $few';
  return '$n $one';
}
