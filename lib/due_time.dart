/// Converts Herald's human-friendly due labels into local device times.
DateTime? parseHeraldDue(
  String raw, {
  DateTime? now,
  bool rollPast = true,
}) {
  final value = raw.trim();
  if (value.isEmpty || value.toLowerCase() == 'proposed') return null;
  final current = now ?? DateTime.now();
  final iso = DateTime.tryParse(value);
  if (iso != null) return iso.toLocal();

  final lower = value.toLowerCase();
  if (lower.startsWith('tonight')) {
    var at = _at(current, 20, 0);
    if (rollPast && !at.isAfter(current)) at = at.add(const Duration(days: 1));
    return at;
  }
  if (lower.startsWith('tomorrow')) {
    final time = _clock(lower, defaultHour: 16);
    return _at(current.add(const Duration(days: 1)), time.$1, time.$2);
  }
  if (lower.startsWith('friday')) {
    final time = _clock(lower, defaultHour: 18);
    var days = (DateTime.friday - current.weekday) % 7;
    var at = _at(current.add(Duration(days: days)), time.$1, time.$2);
    if (rollPast && !at.isAfter(current)) at = at.add(const Duration(days: 7));
    return at;
  }
  final match = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b').firstMatch(lower);
  if (match == null) return null;
  var hour = int.parse(match.group(1)!);
  final minute = int.tryParse(match.group(2) ?? '') ?? 0;
  final meridiem = match.group(3)!;
  if (meridiem == 'pm' && hour != 12) hour += 12;
  if (meridiem == 'am' && hour == 12) hour = 0;
  var at = _at(current, hour, minute);
  if (rollPast && !at.isAfter(current)) at = at.add(const Duration(days: 1));
  return at;
}

(int, int) _clock(String value, {required int defaultHour}) {
  final match = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b')
      .allMatches(value)
      .lastOrNull;
  if (match == null) return (defaultHour, 0);
  var hour = int.parse(match.group(1)!);
  final minute = int.tryParse(match.group(2) ?? '') ?? 0;
  final meridiem = match.group(3);
  if (meridiem == 'pm' && hour != 12) hour += 12;
  if (meridiem == 'am' && hour == 12) hour = 0;
  if (meridiem == null && hour <= 7) hour += 12;
  return (hour, minute);
}

DateTime _at(DateTime day, int hour, int minute) =>
    DateTime(day.year, day.month, day.day, hour, minute);
