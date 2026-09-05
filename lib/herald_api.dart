import 'dart:convert';
import 'package:http/http.dart' as http;
import 'herald_store.dart';

const backend = 'http://127.0.0.1:8765';

Future<void> sendChunk(String text) async {
  final t = text.trim();
  if (t.isEmpty) return;

  final chunk = {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'text': t,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'speaker': 'me',
    'source': 'typed',
  };

  try {
    final res = await http
        .post(
      Uri.parse('$backend/api/chunks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode([chunk]),
    )
        .timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) return;
    final data = jsonDecode(res.body);
    if (data is Map<String, dynamic>) applySnapshot(data);
  } catch (_) {
    // local classify already ran; Python is optional
  }
}

void applySnapshot(Map<String, dynamic> s) {
  store.items.clear();
  store.events.clear();
  store.memories.clear();
  store.weeklyDone.clear();
  store.lines.clear();

  for (final c in (s['chat'] as List? ?? [])) {
    final m = Map<String, dynamic>.from(c as Map);
    store.lines.add('${m['text'] ?? ''}');
  }
  for (final i in (s['items'] as List? ?? [])) {
    final m = Map<String, dynamic>.from(i as Map);
    store.items.add(
      HeraldItem(
        id: '${m['id']}',
        type: '${m['type'] ?? 'commitment'}',
        text: '${m['text'] ?? ''}',
        due: '${m['dueAt'] ?? ''}',
      ),
    );
  }
  for (final e in (s['calendar'] as List? ?? [])) {
    final m = Map<String, dynamic>.from(e as Map);
    store.events.add(
      HeraldEvent(
        id: '${m['id']}',
        title: '${m['title'] ?? ''}',
        whenText: '${m['startAt'] ?? ''}',
        confirmed: m['needsConfirm'] != true,
      ),
    );
  }
  for (final mem in (s['lifeMemory'] as List? ?? [])) {
    final m = Map<String, dynamic>.from(mem as Map);
    store.memories.add('${m['text'] ?? ''}');
  }
}
Future<void> markDoneRemote(String id) async {
  try {
    await http
        .post(
      Uri.parse('$backend/api/done'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'item_id': id}),
    )
        .timeout(const Duration(seconds: 4));
  } catch (_) {}
}