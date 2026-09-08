import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
    persist();
  }

  void markDone(String id) {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    weeklyDone.insert(0, items.removeAt(i).copyDone());
    persist();
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
    persist();
  }

  void dismissEvent(String id) {
    events.removeWhere((e) => e.id == id);
    persist();
  }

  String ask(String q) {
    final s = q.toLowerCase();
    if (s.contains('promise') || s.contains('commit')) {
      final hits = items.where((e) => e.type == 'commitment').toList();
      if (hits.isEmpty) return 'You have no open commitments.';
      return 'You promised:\n${hits.map((e) => '• ${e.text}').join('\n')}';
    }
    if (s.contains('tomorrow')) {
      final hits = items.where((e) => e.due.toLowerCase().contains('tomorrow')).toList();
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
    String type = '';
    var due = '';
    if (t.contains('deadline') || t.contains('due by') || t.contains('due on')) {
      type = 'deadline';
      due = _due(raw);
    } else if (t.contains('meet') || t.contains('meeting') || t.contains('sync with')) {
      type = 'meeting';
      due = _due(raw).isEmpty ? 'proposed' : _due(raw);
    } else if (t.contains('remind me') || t.contains("don't forget") || t.contains('dont forget')) {
      type = 'reminder';
      due = _due(raw);
    } else if (t.contains('we decided') || t.contains('decided to') || t.contains('is handling') || t.contains('in charge')) {
      memories.insert(0, title);
    } else if (t.contains("i'll") ||
        t.contains('i will') ||
        t.contains('i need') ||
        t.contains('need to') ||
        t.contains('have to') ||
        t.contains('make ') ||
        t.contains('call ') ||
        t.contains('send ')) {
      type = 'commitment';
      due = _due(raw);
    }
    if (type.isEmpty || _isDuplicate(type, title, due)) return;
    items.insert(0, HeraldItem(id: _id('i'), type: type, text: title, due: due));
    if (type == 'meeting') {
      events.insert(0, HeraldEvent(id: _id('e'), title: title, whenText: due));
    }
  }

  bool _isDuplicate(String type, String text, String due) => items.any(
        (item) => item.type == type &&
            item.text.toLowerCase() == text.toLowerCase() &&
            item.due.toLowerCase() == due.toLowerCase(),
      );

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

  Map<String, dynamic> toJson() => {
    'last': last,
    'dayOn': dayOn,
    'n': _n,
    'lines': lines,
    'memories': memories,
    'items': items
        .map((e) => {
      'id': e.id,
      'type': e.type,
      'text': e.text,
      'due': e.due,
      'done': e.done,
    })
        .toList(),
    'events': events
        .map((e) => {
      'id': e.id,
      'title': e.title,
      'whenText': e.whenText,
      'confirmed': e.confirmed,
    })
        .toList(),
    'weeklyDone': weeklyDone
        .map((e) => {
      'id': e.id,
      'type': e.type,
      'text': e.text,
      'due': e.due,
      'done': true,
    })
        .toList(),
  };

  void loadJson(Map<String, dynamic> j) {
    last = '${j['last'] ?? ''}';
    dayOn = j['dayOn'] == true;
    _n = (j['n'] as num?)?.toInt() ?? _n;
    lines
      ..clear()
      ..addAll(((j['lines'] as List?) ?? []).map((e) => '$e'));
    memories
      ..clear()
      ..addAll(((j['memories'] as List?) ?? []).map((e) => '$e'));
    items
      ..clear()
      ..addAll(((j['items'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return HeraldItem(
          id: '${m['id']}',
          type: '${m['type']}',
          text: '${m['text']}',
          due: '${m['due'] ?? ''}',
          done: m['done'] == true,
        );
      }));
    events
      ..clear()
      ..addAll(((j['events'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return HeraldEvent(
          id: '${m['id']}',
          title: '${m['title']}',
          whenText: '${m['whenText'] ?? ''}',
          confirmed: m['confirmed'] == true,
        );
      }));
    weeklyDone
      ..clear()
      ..addAll(((j['weeklyDone'] as List?) ?? []).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return HeraldItem(
          id: '${m['id']}',
          type: '${m['type']}',
          text: '${m['text']}',
          due: '${m['due'] ?? ''}',
          done: true,
        );
      }));
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('herald_state', jsonEncode(toJson()));
  }

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('herald_state');
    if (raw == null || raw.isEmpty) return;
    loadJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

final store = HeraldStore();
