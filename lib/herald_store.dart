import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'due_time.dart';
import 'local_notifications.dart';

class HeraldItem {
  HeraldItem({
    required this.id,
    required this.type,
    required this.text,
    this.due = '',
    this.done = false,
    this.owner = 'me',
  });
  final String id;
  final String type;
  final String text;
  final String due;
  final bool done;
  final String owner;

  HeraldItem copyDone() => HeraldItem(
        id: id,
        type: type,
        text: text,
        due: due,
        done: true,
        owner: owner,
      );
}

class HeraldEvent {
  HeraldEvent({
    required this.id,
    required this.title,
    required this.whenText,
    this.itemId = '',
    this.confirmed = false,
  });
  final String id;
  final String title;
  final String whenText;
  final String itemId;
  final bool confirmed;
}

class HeraldLine {
  HeraldLine({
    required this.text,
    this.speaker = 'me',
    this.at = '',
  });
  final String text;
  final String speaker;
  final String at;
}

class HeraldStore {
  String last = '';
  String lastSpeaker = 'me';
  String nextSpeaker = 'me';
  final chat = <HeraldLine>[];
  final items = <HeraldItem>[];
  final events = <HeraldEvent>[];
  final weeklyDone = <HeraldItem>[];
  final memories = <String>[];
  bool dayOn = false;
  bool knowMyVoice = false;
  bool voiceEnrolled = false;
  String voicePhrase = '';
  bool laptopJoin = true;
  bool airplaneDemo = false;
  String lastLaptopAt = '';
  bool enrollPending = false;
  String lastPartial = '';
  String lastStamp = '';
  String sessionNote = '';
  void Function()? onUi;
  int _n = 0;

  void ping() {
    onUi?.call();
  }

  List<String> get lines => chat.map((e) => e.text).toList();
  List<Map<String, String>> get thread {
    final rows = chat.reversed.toList();
    return [
      for (final line in rows)
        {
          'clock': _clock(line.at),
          'who': line.speaker == 'other' ? 'them' : 'you',
          'text': line.text,
          'why': whyKept(line.text, line.speaker),
        }
    ];
  }

  String _clock(String iso) {
    final at = DateTime.tryParse(iso)?.toLocal();
    if (at == null) return '--:--';
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String whyKept(String raw, [String speaker = 'me']) {
    final t = raw.toLowerCase();
    if (t.contains('deadline') || t.contains('due by') || t.contains('due on')) {
      return 'Kept as a deadline so the date does not slip.';
    }
    if (t.contains('meet') || t.contains('meeting') || t.contains('sync with')) {
      return 'Kept as a meeting. It stays proposed until you confirm.';
    }
    if (t.contains('remind me') ||
        t.contains("don't forget") ||
        t.contains('dont forget')) {
      return 'Kept as a reminder you asked Herald to hold.';
    }
    if (t.contains('we decided') ||
        t.contains('decided to') ||
        t.contains('is handling') ||
        t.contains('in charge')) {
      return 'Kept as life memory — a fact about your world, not a task.';
    }
    if (t.contains("i'll") ||
        t.contains('i will') ||
        t.contains('i need') ||
        t.contains('need to') ||
        t.contains('have to') ||
        t.contains('make ') ||
        t.contains('call ') ||
        t.contains('send ')) {
      if (speaker == 'other') {
        return 'Kept as theirs. This is a follow-up, not your promise.';
      }
      return 'Kept as your commitment — a promise you made.';
    }
    return 'Heard and stored on this phone. Not a task.';
  }

  String _id(String p) {
    _n++;
    return '$p$_n';
  }

  void add(String raw, {String speaker = 'me', String source = 'typed'}) {
    final t = raw.trim();
    if (t.isEmpty) return;
    last = t;
    lastSpeaker = speaker;
    lastPartial = '';
    lastStamp = '';
    chat.insert(
      0,
      HeraldLine(
        text: t,
        speaker: speaker,
        at: DateTime.now().toIso8601String(),
      ),
    );
    _classify(t, speaker);
    persist();
  }

  void retagLast(String speaker) {
    if (chat.isEmpty) return;
    final old = chat.first;
    chat[0] = HeraldLine(text: old.text, speaker: speaker, at: old.at);
    lastSpeaker = speaker;
    persist();
  }

  void markDone(String id) {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final item = items.removeAt(i);
    weeklyDone.insert(0, item.copyDone());
    unawaited(heraldNotifications.cancel(item.id));
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
      itemId: e.itemId,
      confirmed: true,
    );
    persist();
  }

  void dismissEvent(String id) {
    final i = events.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final event = events.removeAt(i);
    unawaited(heraldNotifications.cancel(
      event.itemId.isEmpty ? event.id : event.itemId,
    ));
    if (event.itemId.isNotEmpty) {
      items.removeWhere((item) => item.id == event.itemId);
    }
    persist();
  }

  Iterable<String> get followUps => items
      .where((item) {
        final due = parseHeraldDue(item.due, rollPast: false);
        return (item.type == 'commitment' || item.type == 'followup') &&
            due != null &&
            due.isBefore(DateTime.now());
      })
      .map((item) => item.owner == 'other'
          ? "They said they'd ${item.text}. It isn't marked done."
          : "You said you'd ${item.text}. It isn't marked done.");

  String get dailySummary {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final open = items.length;
    final meets = events
        .where((e) =>
            _sameDay(parseHeraldDue(e.whenText, rollPast: false), now))
        .length;
    final mine = items.where((e) => e.owner != 'other').length;
    final theirs = items.where((e) => e.owner == 'other').length;
    final bits = <String>[
      '${days[now.weekday - 1]}.',
      if (open == 0)
        'Your plate is clear.'
      else
        '$open open ${open == 1 ? 'item' : 'items'}.',
      if (meets > 0) '$meets on the calendar today.',
      if (theirs > 0)
        '$theirs ${theirs == 1 ? 'is' : 'are'} theirs, not yours.',
      if (mine > 0 && open > 0) 'You still have $mine of your own.',
      if (weeklyDone.isNotEmpty)
        'You kept your word ${weeklyDone.length} ${weeklyDone.length == 1 ? 'time' : 'times'} this week.',
      if (memories.isNotEmpty)
        'Life memory is holding ${memories.length} ${memories.length == 1 ? 'fact' : 'facts'}.',
    ];
       return bits.join(' ');
  }

  String get eveningNote {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final day = days[DateTime.now().weekday - 1];
    final mine = items.where((e) => e.owner != 'other').toList();
    final theirs = items.where((e) => e.owner == 'other').toList();
    final proposed = events.where((e) => !e.confirmed).toList();
    final bits = <String>[
      '$day. ${items.length} still open.',
      if (mine.isNotEmpty) 'You still owe: ${mine.first.text}.',
      if (theirs.isNotEmpty) 'Theirs: ${theirs.first.text}.',
      if (proposed.isNotEmpty)
        'A meeting is still proposed: ${proposed.first.title}.'
      else if (events.isNotEmpty)
        'Calendar is confirmed.',
      if (weeklyDone.isNotEmpty)
        'You kept your word ${weeklyDone.length} ${weeklyDone.length == 1 ? 'time' : 'times'}.',
      if (memories.isNotEmpty) memories.first,
    ];
    return bits.take(5).join('\n');
  }

  void hearPartial(String text) {
    lastPartial = text.trim();
    ping();
  }

  void captureStop() {
    lastPartial = '';
    final bits = dailySummary.split('. ');
    sessionNote = bits.take(2).where((s) => s.trim().isNotEmpty).join('. ');
    if (sessionNote.isNotEmpty && !sessionNote.endsWith('.')) {
      sessionNote = '$sessionNote.';
    }
    if (sessionNote.isEmpty) {
      sessionNote = 'Stopped. Nothing stored yet.';
    }
    ping();
  }

  String ask(String q) {
    final s = q.toLowerCase();
    if (s.contains('promise') || s.contains('commit')) {
      final hits = items.where((e) => e.type == 'commitment').toList();
      if (hits.isEmpty) return 'You have no open commitments.';
      return 'You promised:\n${hits.map((e) => '• ${e.text}').join('\n')}';
    }
    if (s.contains('they') || s.contains('other') || s.contains('someone else')) {
      final hits = items
          .where((e) => e.owner == 'other' || e.type == 'followup')
          .toList();
      if (hits.isEmpty) return 'Nothing tagged as someone else.';
      return 'Theirs:\n${hits.map((e) => '• ${e.text}').join('\n')}';
    }
    if (s.contains('tomorrow')) {
      final hits = items.where((e) {
        final due = parseHeraldDue(e.due, rollPast: false);
        if (due == null) return e.due.toLowerCase().contains('tomorrow');
        final tom = DateTime.now().add(const Duration(days: 1));
        return due.year == tom.year &&
            due.month == tom.month &&
            due.day == tom.day;
      }).toList();
      if (hits.isEmpty) return 'Nothing dated tomorrow.';
      return 'Tomorrow:\n${hits.map((e) => '• ${e.text}').join('\n')}';
    }
    if (s.contains('today') || s.contains('summary') || s.contains('what do i')) {
      return dailySummary;
    }
    if (s.contains('open') || s.contains('left') || s.contains('need to')) {
      if (items.isEmpty) return 'Your plate is clear.';
      return 'Still open:\n${items.map((e) => '• ${e.text}').join('\n')}';
    }
    if (s.contains('decid') || s.contains('remember') || s.contains('handling')) {
      if (memories.isEmpty) return 'No life memory yet.';
      return 'From memory:\n${memories.map((e) => '• $e').join('\n')}';
    }
    if (s.contains('week') &&
        (s.contains('done') || s.contains('kept') || s.contains('finish'))) {
      if (weeklyDone.isEmpty) return 'Nothing marked done this week.';
      return 'You kept your word:\n${weeklyDone.map((e) => '• ${e.text}').join('\n')}';
    }
    return 'Ask about promises, tomorrow, today, open items, their promises, or decisions.';
  }

  void _classify(String raw, String speaker) {
    final t = raw.toLowerCase();
    final title = _clean(raw);
    String type = '';
    var due = '';
    if (t.contains('deadline') || t.contains('due by') || t.contains('due on')) {
      type = 'deadline';
      due = _due(raw);
    } else if (t.contains('meet') ||
        t.contains('meeting') ||
        t.contains('sync with')) {
      type = 'meeting';
      due = _due(raw).isEmpty ? 'proposed' : _due(raw);
    } else if (t.contains('remind me') ||
        t.contains("don't forget") ||
        t.contains('dont forget')) {
      type = 'reminder';
      due = _due(raw);
    } else if (t.contains('we decided') ||
        t.contains('decided to') ||
        t.contains('is handling') ||
        t.contains('in charge')) {
      memories.insert(0, title);
      lastStamp = 'memory · on this phone';
    } else if (t.contains("i'll") ||
        t.contains('i will') ||
        t.contains('i need') ||
        t.contains('need to') ||
        t.contains('have to') ||
        t.contains('make ') ||
        t.contains('call ') ||
        t.contains('send ')) {
      type = speaker == 'other' ? 'followup' : 'commitment';
      due = _due(raw);
    }
    if (type.isEmpty || _isDuplicate(title, due)) {
      if (lastStamp.isEmpty) lastStamp = 'heard · on this phone';
      return;
    }
    lastStamp = [
      type,
      if (due.isNotEmpty) due,
      'on this phone',
    ].join(' · ');
    final item = HeraldItem(
      id: _id('i'),
      type: type,
      text: title,
      due: due,
      owner: speaker,
    );
    items.insert(0, item);
    unawaited(heraldNotifications.scheduleItem(item));
    if (type == 'meeting') {
      events.insert(
        0,
        HeraldEvent(
          id: _id('e'),
          title: title,
          whenText: due,
          itemId: item.id,
        ),
      );
    }
  }

  bool _isDuplicate(String text, String due) {
    final dueDay = _dueDay(due);
    return items.any((item) =>
        item.text.toLowerCase() == text.toLowerCase() &&
        _dueDay(item.due) == dueDay);
  }

  String _dueDay(String due) {
    final parsed = parseHeraldDue(due);
    if (parsed == null) return due.toLowerCase();
    return '${parsed.year}-${parsed.month}-${parsed.day}';
  }

  bool _sameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
    if (t.contains('tomorrow') && (t.contains('4') || t.contains('four'))) {
      return 'Tomorrow 4:00';
    }
    if (t.contains('tomorrow')) return 'Tomorrow 4:00';
    if (t.contains('friday')) return 'Friday 6:00';
    final m = RegExp(r'\b(\d{1,2})\s*(am|pm)\b').firstMatch(t);
    if (m != null) return '${m.group(1)} ${m.group(2)!.toUpperCase()}';
    return '';
  }

  List<HeraldEvent> eventsOn(DateTime day) {
    return events.where((e) {
      final when = parseHeraldDue(e.whenText, rollPast: false);
      return _sameDay(when, day);
    }).toList();
  }

  List<HeraldItem> itemsOn(DateTime day) {
    return items.where((e) {
      final when = parseHeraldDue(e.due, rollPast: false);
      return _sameDay(when, day);
    }).toList();
  }

  Map<String, dynamic> toJson() => {
        'last': last,
        'lastSpeaker': lastSpeaker,
        'nextSpeaker': nextSpeaker,
        'dayOn': dayOn,
        'knowMyVoice': knowMyVoice,
        'voiceEnrolled': voiceEnrolled,
        'voicePhrase': voicePhrase,
        'laptopJoin': laptopJoin,
        'airplaneDemo': airplaneDemo,
        'lastLaptopAt': lastLaptopAt,
        'n': _n,
        'chat': chat
            .map((e) => {'text': e.text, 'speaker': e.speaker, 'at': e.at})
            .toList(),
        'memories': memories,
        'items': items
            .map((e) => {
                  'id': e.id,
                  'type': e.type,
                  'text': e.text,
                  'due': e.due,
                  'done': e.done,
                  'owner': e.owner,
                })
            .toList(),
        'events': events
            .map((e) => {
                  'id': e.id,
                  'title': e.title,
                  'whenText': e.whenText,
                  'itemId': e.itemId,
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
                  'owner': e.owner,
                })
            .toList(),
      };

  void loadJson(Map<String, dynamic> j) {
    last = '${j['last'] ?? ''}';
    lastSpeaker = '${j['lastSpeaker'] ?? 'me'}';
    nextSpeaker = '${j['nextSpeaker'] ?? 'me'}';
    dayOn = j['dayOn'] == true;
    knowMyVoice = j['knowMyVoice'] == true;
    voiceEnrolled = j['voiceEnrolled'] == true;
    voicePhrase = '${j['voicePhrase'] ?? ''}';
    laptopJoin = j['laptopJoin'] != false;
    airplaneDemo = j['airplaneDemo'] == true;
    lastLaptopAt = '${j['lastLaptopAt'] ?? ''}';
    _n = (j['n'] as num?)?.toInt() ?? _n;
    chat
      ..clear()
      ..addAll(((j['chat'] as List?) ?? (j['lines'] as List?) ?? []).map((e) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          return HeraldLine(
            text: '${m['text'] ?? ''}',
            speaker: '${m['speaker'] ?? 'me'}',
            at: '${m['at'] ?? ''}',
          );
        }
        return HeraldLine(text: '$e');
      }));
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
          due: '${m['due'] ?? m['dueAt'] ?? ''}',
          done: m['done'] == true,
          owner: '${m['owner'] ?? 'me'}',
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
          itemId: '${m['itemId'] ?? ''}',
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
          owner: '${m['owner'] ?? 'me'}',
        );
      }));
  }

  void applySnapshot(Map<String, dynamic> s) {
    chat.clear();
    items.clear();
    events.clear();
    memories.clear();
    weeklyDone.clear();

    for (final c in (s['chat'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(c as Map);
      chat.add(HeraldLine(
        text: '${m['text'] ?? ''}',
        speaker: '${m['speaker'] ?? 'me'}',
        at: '${m['timestamp'] ?? m['at'] ?? ''}',
      ));
    }
    if (chat.isNotEmpty) {
      last = chat.first.text;
      lastSpeaker = chat.first.speaker;
    }
    for (final i in (s['items'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(i as Map);
      items.add(
        HeraldItem(
          id: '${m['id']}',
          type: '${m['type'] ?? 'commitment'}',
          text: '${m['text'] ?? ''}',
          due: '${m['dueAt'] ?? m['due'] ?? ''}',
          owner: '${m['owner'] ?? 'me'}',
        ),
      );
    }
    for (final e in (s['calendar'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(e as Map);
      events.add(
        HeraldEvent(
          id: '${m['id']}',
          title: '${m['title'] ?? ''}',
          whenText: '${m['startAt'] ?? m['whenText'] ?? ''}',
          itemId: '${m['relatedItemId'] ?? m['itemId'] ?? ''}',
          confirmed: m['needsConfirm'] != true && m['status'] != 'proposed',
        ),
      );
    }
    for (final mem in (s['lifeMemory'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(mem as Map);
      memories.add('${m['text'] ?? ''}');
    }
    for (final d in (s['weeklyDone'] as List? ?? [])) {
      final m = Map<String, dynamic>.from(d as Map);
      weeklyDone.add(
        HeraldItem(
          id: '${m['id']}',
          type: '${m['type'] ?? 'commitment'}',
          text: '${m['text'] ?? ''}',
          due: '${m['dueAt'] ?? m['due'] ?? ''}',
          done: true,
          owner: '${m['owner'] ?? 'me'}',
        ),
      );
    }
    lastLaptopAt = DateTime.now().toIso8601String();
    persist();
    unawaited(heraldNotifications.rescheduleOpen(items));
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