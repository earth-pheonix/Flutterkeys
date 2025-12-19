import 'package:flutter/services.dart';
import 'dart:async';
import 'tts_interface.dart';
import 'package:flutterkeysaac/Variables/variables.dart';

class TTSiOS implements TTSInterface {
  static const MethodChannel _methodChannel =
      MethodChannel('tts_highlighter_plugin');

  Completer<void>? _speakCompleter;

  final _highlighter = TtsHighlighter();

  double _currentPitch = 1.0;
  double _currentRate = 0.5;
  String? _currentVoiceIdentifier;

  final StreamController<void> _doneController = StreamController<void>.broadcast();

  @override
  Stream<void> get onDone => _doneController.stream;

  TTSiOS() {
    _setupHandlers();
  }

  void _setupHandlers() {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onStart':
          notifyStart();
          break;
        case 'onComplete':
          notifyDone();
          break;
        case 'onCancel':
          notifyDone();
          break;
        case 'onPause':
          V4rs.theIsSpeaking.value = false;
          break;
        case 'onResume':
          V4rs.theIsSpeaking.value = true;
          break;
      }
    });
  }

  @override
  void notifyDone() {
    if (!_doneController.isClosed) {
      _doneController.add(null);
    }

    if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
      _speakCompleter!.complete();
      _speakCompleter = null;
    }

    V4rs.theIsSpeaking.value = false;
  }

  @override
  void notifyStart() {
    V4rs.theIsSpeaking.value = true;
  }

  @override
  Future<void> speak(String text) async {
     _speakCompleter = Completer<void>();
    notifyStart();
    final normalizedText = _normalizeText(text);

    try {
      await _methodChannel.invokeMethod('speak', {
        'text': normalizedText,
        'pitch': _currentPitch,
        'rate': _currentRate,
        'voice': _currentVoiceIdentifier,
      });
      await _speakCompleter!.future;
    } catch (e) {
      await _speakCompleter!.future;
      notifyDone(); 
    }
  }

  String _normalizeText(String text) {
  text = text.trim();
  // Fix independent "I"
  if (text == 'I ') {
    return 'eye '; 
  }

  // Add more overrides here

  return text;
  }

  @override
  Future<void> stop() async {
    try {
      await _methodChannel.invokeMethod('stop');
      // Native will send didCancel; we also mark done as fail-safe:
      notifyDone();
    } catch (e) {
      notifyDone();
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _methodChannel.invokeMethod('pause');
      // Native delegate will send onPause -> isSpeaking=false
    } catch (e) {
      await stop();
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _methodChannel.invokeMethod('resume');
      // Native delegate will send onResume -> isSpeaking=true
    } catch (e) {
      print("Error resuming TTS: $e");
    }
  }

  @override
  Future<void> setPitch(double pitch) async {
    _currentPitch = pitch;
  }

  @override
  Future<void> setRate(double rate) async {
    _currentRate = rate;
  }

  @override
  Future<List<dynamic>> getVoices() async {
    final voices = await _methodChannel.invokeMethod<List>('getVoices');
    return voices ?? [];
  }

  @override
  Future<void> setVoice(Map<String, String> voice) async {
    if (voice.containsKey('identifier')) {
      _currentVoiceIdentifier = voice['identifier'];
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    await _methodChannel.invokeMethod('setLanguage', {'language': languageCode});
  }

  @override
  Future<void> configureVoice({
    required String voiceID,
    required double rate,
    required double pitch,
  }) async {
    _currentVoiceIdentifier = voiceID;
    _currentRate = rate;
    _currentPitch = pitch;
  }

  @override
  Stream<Map<String, dynamic>> get wordStream => _highlighter.wordStream;
}

class TtsHighlighter {
  static const EventChannel _eventChannel =
      EventChannel("tts_highlighter_events");

  Stream<Map<String, dynamic>> get wordStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }
}