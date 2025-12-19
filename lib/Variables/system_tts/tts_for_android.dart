// lib/tts/tts_android.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutterkeysaac/Variables/variables.dart';
import 'tts_interface.dart';
import 'dart:async';

class TTSAndroid implements TTSInterface {
  FlutterTts _tts = FlutterTts();

  final StreamController<void> _doneController = StreamController.broadcast();

  @override
  Stream<void> get onDone => _doneController.stream;

  TTSAndroid() {
    _initializeTts();
  }

  void _initializeTts() {
    _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      notifyStart();
    });

    _tts.setCompletionHandler(() {
      notifyDone();
    });

    _tts.setCancelHandler(() {
      notifyDone();
    });

    _tts.setPauseHandler(() {
      V4rs.theIsSpeaking.value = false;
    });

    _tts.setContinueHandler(() {
      V4rs.theIsSpeaking.value = true;
    });
  }

  @override
  void notifyStart() {
    V4rs.theIsSpeaking.value = true;
  }

  @override
  void notifyDone() {
    V4rs.theIsSpeaking.value = false;
    if (!_doneController.isClosed) {
      _doneController.add(null);
    }
  }

  @override
  Future<void> speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      notifyDone();
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
      notifyDone();
    } catch (e) {
      notifyDone();
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (e) {
      stop();
    }
  }

  @override
  Future<void> resume() async {
    // flutter_tts does not support resume on Android
  }

  @override
  Future<void> setPitch(double pitch) async =>
      await _tts.setPitch(pitch);

  @override
  Future<void> setRate(double rate) async =>
      await _tts.setSpeechRate(rate);

  @override
  Future<void> setVoice(Map<String, dynamic> voice) async {
    if (voice.containsKey('identifier')) {
      final voices = await _tts.getVoices;
      final match = voices.firstWhere(
        (v) => v['identifier'] == voice['identifier'],
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        await _tts.setVoice(Map<String, String>.from(
          match.map((k, v) => MapEntry(k.toString(), v.toString())),
        ));
      }
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async =>
      await _tts.setLanguage(languageCode);

  @override
  Future<List<dynamic>> getVoices() async =>
      await _tts.getVoices;

  @override
  Future<void> configureVoice({
    required String voiceID,
    required double rate,
    required double pitch,
  }) async {
    await _tts.stop();

    // Reset TTS instance to apply fresh settings
    _tts = FlutterTts();
    _initializeTts();

    // Apply voice/rate/pitch
    final voices = await _tts.getVoices;
    final match = voices.firstWhere(
      (v) => v['identifier'] == voiceID,
      orElse: () => {},
    );
    if (match.isNotEmpty) {
      await _tts.setVoice(Map<String, String>.from(
        match.map((k, v) => MapEntry(k.toString(), v.toString())),
      ));
    }

    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
  }

  @override
  Stream<Map<String, dynamic>> get wordStream => const Stream.empty();
}