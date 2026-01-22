import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  
  bool _isListening = false;
  bool get isListening => _isListening;

  Future<void> init() async {
    // Initialize TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Slightly slower for that JARVIS calmness
    
    // Initialize STT
    // We don't initialize here because stt needs permissions which might not be ready on app start immediately
    // or we handle it in 'listen'. Better to init once.
    await _speechToText.initialize(
      onStatus: (status) => print('STT Status: $status'),
      onError: (error) => print('STT Error: $error'),
    );
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<void> listen({required Function(String) onResult}) async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        _isListening = true;
        _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              _isListening = false;
              onResult(result.recognizedWords);
            }
          },
          listenFor: Duration(seconds: 10),
          pauseFor: Duration(seconds: 3),
        );
      }
    } else {
      _isListening = false;
      _speechToText.stop();
    }
  }
  
  Future<void> stopListening() async {
    _isListening = false;
    await _speechToText.stop();
  }
}
