class HeraldItem {
  HeraldItem({
    required this.id,
    required this.type,
    required this.text,
    this.due = '',
    this.done = false,
  });
  final String id;
  final String type;
  final String text;
  final String due;
  final bool done;

  HeraldItem copyDone() => HeraldItem(
    id: id,
    type: type,
    text: text,
    due: due,
    done: true,
  );
}

class HeraldEvent {
  HeraldEvent({
    required this.id,
    required this.title,
    required this.whenText,
    this.confirmed = false,
  });
  final String id;
  final String title;
  final String whenText;
  final bool confirmed;
}

class HeraldStore {
  String last = '';
  final lines = <String>[];
  final items = <HeraldItem>[];
  final events = <HeraldEvent>[];
  final weeklyDone = <HeraldItem>[];
  final memories = <String>[];
  bool dayOn = false;
  int _n = 0;

  String _id(String p) {
    _n++;
    return '$p$_n';
  }

  void add(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    last = t;
    lines.insert(0, t);
    _classify(t);
  }

  void markDone(String id) {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    weeklyDone.insert(0, items.removeAt(i).copyDone());
  }

  void confirmEvent(String id) {
    final i = events.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final e = events[i];
    events[i] = HeraldEvent(
      id: e.id,
      title: e.title,
      whenText: e.whenText,
      confirmed: true,
    );
  }

  void dismissEvent(String id) {
    events.removeWhere((e) => e.id == id);
  }

  String ask(String q) {
    final s = q.toLowerCase();
    if (s.contains('promise') || s.contains('commit')) {
      final hits = items.where((e) => e.type == 'commitment').toList();
      if (hits.isEmpty) return 'You have no open commitments.';
      return 'You promised:\n${hits.map((e) => '• ${e.text}').join('\n')}';
    }
    if (s.contains('tomorrow')) {
      final hits = items.where((e) => e.due.contains('Tomorrow')).toList();
      if (hits.isEmpty) return 'Nothing dated tomorrow.';
      return 'Tomorrow:\n${hits.map((e) => '• ${e.text}').join('\n')}';
    }
    if (s.contains('open') || s.contains('left')) {
      if (items.isEmpty) return 'Your plate is clear.';
      return 'Still open:\n${items.map((e) => '• ${e.text}').join('\n')}';
    }
    if (s.contains('decid') || s.contains('remember') || s.contains('handling')) {
      if (memories.isEmpty) return 'No life memory yet.';
      return 'From memory:\n${memories.map((e) => '• $e').join('\n')}';
    }
    return 'Ask about promises, tomorrow, open items, or decisions.';
  }

  void _classify(String raw) {
    final t = raw.toLowerCase();
    final title = _clean(raw);
    if (t.contains('deadline') || t.contains('due by') || t.contains('due on')) {
      items.insert(0, HeraldItem(id: _id('i'), type: 'deadline', text: title, due: _due(raw)));
    } else if (t.contains('meet') || t.contains('meeting') || t.contains('sync with')) {
      final when = _due(raw).isEmpty ? 'proposed' : _due(raw);
      items.insert(0, HeraldItem(id: _id('i'), type: 'meeting', text: title, due: when));
      events.insert(0, HeraldEvent(id: _id('e'), title: title, whenText: when));
    } else if (t.contains('remind me') || t.contains("don't forget") || t.contains('dont forget')) {
      items.insert(0, HeraldItem(id: _id('i'), type: 'reminder', text: title, due: _due(raw)));
    } else if (t.contains('we decided') || t.contains('decided to') || t.contains('is handling') || t.contains('in charge')) {
      memories.insert(0, title);
    } else if (t.contains("i'll") || t.contains('i will') || t.contains('i need') || t.contains('need to') || t.contains('have to') || t.contains('make ') || t.contains('call ') || t.contains('send ')) {
      items.insert(0, HeraldItem(id: _id('i'), type: 'commitment', text: title, due: _due(raw)));
    }
  }

  String _clean(String text) {
    var s = text.trim().replaceAll(RegExp(r'[.!?]+$'), '');
    const prefixes = [
      'remind me to ',
      "don't forget to ",
      'dont forget to ',
      "i'll ",
      'i will ',
      'i need to ',
      'need to ',
      'have to ',
      "let's ",
      'let us ',
      'the project deadline is ',
      'deadline is ',
    ];
    final low = s.toLowerCase();
    for (final p in prefixes) {
      if (low.startsWith(p)) {
        s = s.substring(p.length);
        break;
      }
    }
    if (s.isEmpty) return text.trim();
    return s[0].toUpperCase() + s.substring(1);
  }

  String _due(String text) {
    final t = text.toLowerCase();
    if (t.contains('tonight')) return 'Tonight 8:00';
    if (t.contains('tomorrow') && t.contains('4')) return 'Tomorrow 4:00';
    if (t.contains('friday')) return 'Friday 6:00';
    final m = RegExp(r'\b(\d{1,2})\s*(am|pm)\b').firstMatch(t);
    if (m != null) return '${m.group(1)} ${m.group(2)!.toUpperCase()}';
    return '';
  }
}

final store = HeraldStore();