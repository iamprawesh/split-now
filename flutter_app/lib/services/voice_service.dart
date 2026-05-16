import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  String? _lastError;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;
  String? get lastError => _lastError;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _lastError = null;
    try {
      final available = await _speech.initialize(
        onStatus: (_) {},
        onError: (error) => _lastError = error.errorMsg,
      );
      _initialized = available;
      return available;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<void> startListening(Function(String) onResult) async {
    _lastError = null;
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true),
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }
}
