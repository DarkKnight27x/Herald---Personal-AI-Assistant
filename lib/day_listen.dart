import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

import 'herald_api.dart';
import 'herald_store.dart';

const _modelAsset = 'assets/vosk/vosk-model-small-en-us-0.15.zip';
const _voicePackMissing = 'Voice pack missing. Use + to type.';

final _vosk = VoskFlutterPlugin.instance();
SpeechService? _speechService;
StreamSubscription<dynamic>? _results;
StreamSubscription<dynamic>? _partials;
bool _starting = false;
bool _busy = false;
Completer<String>? _once;

Future<String> startDayMode() async {
  if (_starting) return '';
  if (store.dayOn && _speechService != null) return '';
  _starting = true;
  try {
    await rootBundle.load(_modelAsset);
  } catch (_) {
    _starting = false;
    return _voicePackMissing;
  }
  try {
    await _prepareSpeechService();
    store.dayOn = true;
    store.lastPartial = '';
    store.sessionNote = '';
    await store.persist();
    store.ping();
    await _speechService!.start(onRecognitionError: (_) {
      unawaited(stopListen());
    });
    return '';
  } catch (_) {
    store.dayOn = false;
    await store.persist();
    store.ping();
    return 'Voice recognition is unavailable. Use + to type.';
  } finally {
    _starting = false;
  }
}

Future<String> listenOnce() async {
  final missing = await _ensureModel();
  if (missing != null) return missing;
  try {
    await _prepareSpeechService();
    final done = Completer<String>();
    _once = done;
    await _speechService!.start(onRecognitionError: (_) {
      if (!_once!.isCompleted) _once!.complete('');
    });
    final heard = await done.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => '',
    );
    _once = null;
    if (!store.dayOn) {
      await _speechService?.stop();
    }
    return heard;
  } catch (_) {
    _once = null;
    return 'Voice recognition is unavailable. Use + to type.';
  }
}

Future<String?> _ensureModel() async {
  try {
    await rootBundle.load(_modelAsset);
    return null;
  } catch (_) {
    return _voicePackMissing;
  }
}

Future<void> _prepareSpeechService() async {
  if (_speechService != null) return;
  final modelPath = await ModelLoader().loadFromAssets(_modelAsset);
  final model = await _vosk.createModel(modelPath);
  final recognizer = await _vosk.createRecognizer(
    model: model,
    sampleRate: 16000,
  );
  _speechService = await _vosk.initSpeechService(recognizer);
  _results = _speechService!.onResult().listen(_onFinalResult);
  _partials = _speechService!.onPartial().listen(_onPartial);
}

void _onPartial(dynamic raw) {
  if (_once != null) return;
  if (!store.dayOn) return;
  final heard = _partialText('$raw');
  if (heard.isEmpty) return;
  store.hearPartial(heard);
}

void _onFinalResult(dynamic raw) {
  final heard = _resultText('$raw');
  if (heard.isEmpty) return;
  if (_once != null && !_once!.isCompleted) {
    _once!.complete(heard);
    return;
  }
  if (!store.dayOn || _busy) return;
  unawaited(_accept(heard));
}

String _resultText(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final text = '${decoded['text'] ?? ''}'.trim();
      if (text.isNotEmpty && text.toLowerCase() != 'nun') return text;
    }
  } catch (_) {}
  final t = raw.trim();
  if (t.isEmpty || t.toLowerCase() == 'nun') return '';
  return t;
}

String _partialText(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final text = '${decoded['partial'] ?? decoded['text'] ?? ''}'.trim();
      if (text.isNotEmpty && text.toLowerCase() != 'nun') return text;
    }
  } catch (_) {}
  return '';
}

Future<void> _accept(String heard) async {
  _busy = true;
  try {
    if (store.enrollPending) {
      store.voicePhrase = heard;
      store.voiceEnrolled = true;
      store.knowMyVoice = true;
      store.enrollPending = false;
      store.last = heard;
      store.lastSpeaker = 'me';
      store.lastPartial = '';
      store.lastStamp = 'voice saved · on this phone';
      await store.persist();
      store.ping();
      return;
    }
    final speaker = store.knowMyVoice ? store.nextSpeaker : 'me';
    store.nextSpeaker = 'me';
    store.add(heard, speaker: speaker, source: 'stt');
    store.ping();
    await sendChunk(heard, speaker: speaker, source: 'stt');
  } finally {
    _busy = false;
  }
}

Future<void> stopListen() async {
  store.dayOn = false;
  store.enrollPending = false;
  store.captureStop();
  await store.persist();
  await _speechService?.stop();
}

Future<String> startListenOnce() => startDayMode();