String prettyWhen(String raw) {
  if (raw.isEmpty) return '';
  if (!raw.contains('T')) return raw;
  try {
    final d = DateTime.parse(raw).toLocal();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    var h = d.hour % 12;
    if (h == 0) h = 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '${days[d.weekday - 1]} · $h:$m $ap';
  } catch (_) {
    return raw;
  }
}
