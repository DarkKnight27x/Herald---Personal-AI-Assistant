import 'dart:convert';

import 'package:http/http.dart' as http;

import 'herald_store.dart';

const backend = 'http://127.0.0.1:8765';

bool get _offline => store.airplaneDemo || !store.laptopJoin;

Future<Map<String, dynamic>?> _post(
  String path,
  Map<String, dynamic> body,
) async {
  if (_offline) return null;
  try {
    final res = await http
        .post(
          Uri.parse('$backend$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 4));
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      store.lastLaptopAt = DateTime.now().toIso8601String();
      return decoded;
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> sendChunk(String text, {String speaker = 'me', String source = 'typed'}) async {
  final t = text.trim();
  if (t.isEmpty) return;
  final chunk = {
    'id': DateTime.now().millisecondsSinceEpoch.toString(),
    'text': t,
    'timestamp': DateTime.now().toIso8601String(),
    'speaker': speaker,
    'source': source,
  };
  final snap = await _post('/api/chunks', {'chunks': [chunk]});
  if (snap != null && snap.containsKey('items')) {
    store.applySnapshot(snap);
  }
}

Future<void> markDoneRemote(String id) async {
  final snap = await _post('/api/done', {'item_id': id});
  if (snap != null && snap.containsKey('items')) {
    store.applySnapshot(snap);
  }
}

Future<void> confirmRemote(String id) async {
  final snap = await _post('/api/confirm', {'event_id': id});
  if (snap != null && snap.containsKey('calendar')) {
    store.applySnapshot(snap);
  }
}

Future<void> dismissRemote(String id) async {
  final snap = await _post('/api/dismiss', {'event_id': id});
  if (snap != null && snap.containsKey('calendar')) {
    store.applySnapshot(snap);
  }
}

Future<String?> askRemote(String question) async {
  final res = await _post('/api/ask', {'question': question});
  if (res == null) return null;
  final text = res['text'];
  return text == null ? null : '$text';
}

Future<bool> pullSnapshot() async {
  if (_offline) return false;
  try {
    final res = await http
        .get(Uri.parse('$backend/api/snapshot'))
        .timeout(const Duration(seconds: 3));
    if (res.statusCode != 200) return false;
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) return false;
    final empty = (decoded['items'] as List? ?? []).isEmpty &&
        (decoded['chat'] as List? ?? []).isEmpty &&
        (decoded['calendar'] as List? ?? []).isEmpty &&
        store.items.isNotEmpty;
    if (empty) return false;
    store.applySnapshot(decoded);
    return true;
  } catch (_) {
    return false;
  }
}
