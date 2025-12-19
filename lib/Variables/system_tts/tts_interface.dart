import 'dart:async';
import 'package:flutterkeysaac/Variables/variables.dart';

abstract class TTSInterface {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> setPitch(double pitch);
  Future<void> setRate(double rate);
  Future<void> setVoice(Map<String, String> voiceID);
  Future<void> setLanguage(String languageCode);

  Future<void> configureVoice({
    required String voiceID,
    required double rate,
    required double pitch,
  });

  Future<List<dynamic>> getVoices();

  final StreamController<void> _doneController = StreamController.broadcast();
  Stream<void> get onDone => _doneController.stream;
  
  Stream<Map<String, dynamic>> get wordStream;

  void notifyStart() {
    V4rs.theIsSpeaking.value = true;
  }

  void notifyDone() {
    if (!_doneController.isClosed) {
      _doneController.add(null);
    }
    V4rs.theIsSpeaking.value = false;
  }
}