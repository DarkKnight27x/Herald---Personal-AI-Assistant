import 'package:speech_to_text/speech_to_text.dart';
import 'herald_store.dart';

final _stt = SpeechToText();
bool _starting = false;
bool _resumeQueued = false;

/// Starts Day Mode. Speech-to-text owns the Android microphone permission
/// prompt, which avoids a second plugin and keeps this usable after rebuilds.
Future<String> startListening() async {
  if (_starting || _stt.isListening) return '';
  _starting = true;

  final ok = await _stt.initialize(
    onStatus: _onStatus,
    onError: (_) => _queueResume(),
  );
  if (!ok) {
    _starting = false;
    return 'Microphone or speech recognition is unavailable. Try + and type.';
  }

  store.dayOn = true;
  await store.persist();
  _starting = false;
  await _listen();
  return '';
}

Future<void> _listen() async {
  if (!store.dayOn || _stt.isListening) return;
  await _stt.listen(
    pauseFor: const Duration(seconds: 2),
    onResult: (r) {
      if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
        store.add(r.recognizedWords);
      }
    },
  );
}

void _onStatus(String status) {
  if (status == 'done' || status == 'notListening') _queueResume();
}

void _queueResume() {
  if (!store.dayOn || _resumeQueued) return;
  _resumeQueued = true;
  Future<void>.delayed(const Duration(milliseconds: 350), () async {
    _resumeQueued = false;
    await _listen();
  });
}

Future<void> stopListen() async {
  _resumeQueued = false;
  await _stt.stop();
  store.dayOn = false;
  await store.persist();
}
