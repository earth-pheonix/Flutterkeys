// lib/tts/tts_web.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_interface.dart';

class TTSWeb implements TTSInterface {
  FlutterTts _tts = FlutterTts();

  @override
  ValueNotifier<bool> isSpeaking = ValueNotifier(false);

  final StreamController<void> _doneController = StreamController.broadcast();

  @override
  Stream<void> get onDone => _doneController.stream;

  TTSWeb() {
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
      isSpeaking.value = false;
    });

    _tts.setContinueHandler(() {
      isSpeaking.value = true;
    });
  }

  @override
  void notifyStart() {
    isSpeaking.value = true;
  }

  @override
  void notifyDone() {
    if (!_doneController.isClosed) {
      _doneController.add(null);
    }
    isSpeaking.value = false;
  }

  @override
  Future<void> speak(String text) async {
    try {
      notifyStart();
      await _tts.speak(text);
    } catch (e) {
      notifyDone();
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } finally {
      notifyDone();
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _tts.pause();
      isSpeaking.value = false;
    } catch (e) {
      await _tts.stop();
    }
  }

  @override
  Future<void> resume() async {
    // Not supported on Web
  }

  @override
  Future<void> setPitch(double pitch) async =>
      await _tts.setPitch(pitch);

  @override
  Future<void> setRate(double rate) async =>
      await _tts.setSpeechRate(rate);

  @override
  Future<List<dynamic>> getVoices() async {
    final voices = await _tts.getVoices;
    return voices ?? [];
  }

  @override
  Future<void> setVoice(Map<String, String> voiceID) async {
    if (voiceID['identifier'] == 'default') {
      await _tts.stop();
      _tts = FlutterTts();
      return;
    }

    final voices = await _tts.getVoices ?? [];
    final voice = voices.firstWhere(
      (v) => v['identifier'] == voiceID['identifier'],
      orElse: () => {},
    );

    if (voice.isNotEmpty) {
      final formattedVoice = Map<String, String>.from(
        voice.map((k, v) => MapEntry(k.toString(), v.toString())),
      );
      await _tts.setVoice(formattedVoice);
    }
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    await _tts.setLanguage(languageCode);
  }

  @override
  Future<void> configureVoice({
    required String voiceID,
    required double rate,
    required double pitch,
  }) async {
    await setVoice({'identifier': voiceID});
    await setRate(rate);
    await setPitch(pitch);
  }

  @override
  Stream<Map<String, dynamic>> get wordStream => const Stream.empty();
}