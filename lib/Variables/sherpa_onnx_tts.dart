
import 'package:flutterkeysaac/Variables/settings/settings_variables.dart';
import 'package:flutterkeysaac/Variables/settings/voice_variables.dart';
import 'package:flutterkeysaac/Variables/variables.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import "dart:io";




//Flutterkeys supports vits, kokoro, and single onnx matcha files. 

class SherpaOnnxV4rs {

  static Future<sherpa_onnx.OfflineTts> createOfflineTts(String voiceId) async {
    print('start createOfflineTts');
    sherpa_onnx.initBindings();

    final base = p.join(
      (await getApplicationDocumentsDirectory()).path,
      "sherpaOnnx_models",
      voiceId,
    );

    final modelOnnx = p.join(base, "$voiceId.onnx");
    final voicesBin = p.join(base, "$voiceId-voices.bin");
    final tokens = p.join(base, "tokens.txt");
    final espeak = p.join(base, "eSpeak-ng");

    final dir = Directory(base);
    final entries = await dir.list(recursive: true).toList();

    final ruleFsts = entries
        .where((e) => e.path.endsWith(".fst"))
        .map((e) => e.path)
        .join(",");

    final ruleFars = entries
        .where((e) => e.path.endsWith(".far"))
        .map((e) => e.path)
        .join(",");

    final lexicons = entries
        .where((e) => p.basename(e.path).contains("lexicon"))
        .map((e) => e.path)
        .join(",");

    
    final isKokoro = File(voicesBin).existsSync();


    late final sherpa_onnx.OfflineTtsVitsModelConfig vits;
    late final sherpa_onnx.OfflineTtsKokoroModelConfig kokoro;

    print('createOfflineTts: variables set');

    if (isKokoro) {
      print('createOfflineTts: is kokoro');
      vits = sherpa_onnx.OfflineTtsVitsModelConfig(); // unused
      kokoro = sherpa_onnx.OfflineTtsKokoroModelConfig(
        model: modelOnnx,
        voices: voicesBin,
        tokens: tokens,
        dataDir: espeak,
        lexicon: lexicons,
      );
    } else {
      print('createOfflineTts: is not kokoro');
      kokoro = sherpa_onnx.OfflineTtsKokoroModelConfig(); // unused
      vits = sherpa_onnx.OfflineTtsVitsModelConfig(
        model: modelOnnx,
        tokens: tokens,
        lexicon: lexicons,
        dataDir: espeak,
      );
    }

    final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
      vits: vits, //settings for vits models
      kokoro: kokoro, //settings for kokoro models
      numThreads: 2, //number of cpu threads allowed
      debug: true, //how much to print (true = lots)
      provider: 'cpu', //what hardware backend to use
    );

    final config = sherpa_onnx.OfflineTtsConfig(
      model: modelConfig, //vits or kokoro
      ruleFsts: ruleFsts, 
      ruleFars: ruleFars,
      maxNumSenetences: 1, //sentance count for proccess per call
    );

    print('createOfflineTts: model configs set');

    final tts = sherpa_onnx.OfflineTts(config);
    print('createOfflineTts: done');

    return tts;
    }

  static Future<dynamic> loadSherpaOnnxEngine() async {
    print('loadSherpaOnnxEngine');
    //for (final lang in Sv4rs.myLanguages){
    //  print('loadSherpaOnnxEngine: engine: ${Vv4rs.sherpaOnnxLanguageVoice[lang]?.engine}');
    //  print('loadSherpaOnnxEngine: language: $lang');
      if (Vv4rs.myEngineForVoiceLang['English'] == 'sherpa-onnx'){
        print('loadSherpaOnnxEngine: engine is sherpa-onnx');
        if (Vv4rs.sherpaOnnxLanguageVoice['English'] != null){
          print('loadSherpaOnnxEngine: voice is not null');
          final tts = await createOfflineTts(
            Vv4rs.sherpaOnnxLanguageVoice['English']!.id ?? '',
          );
          print('loadSherpaOnnxEngine: done');
          return tts;
        }
    //  }
      print('loadSherpaOnnxEngine: engine isnt sherpa-onnx');
    }
  }

  static Future<dynamic> loadSherpaOnnxSSEngine() async {
    print('loadSherpaOnnxSSEngine');
    for (final lang in Sv4rs.myLanguages){
      if (Vv4rs.myEngineForSSVoiceLang[lang] == 'sherpa-onnx'){
        print('loadSherpaOnnxEngine: engine is sherpa onnx');
        if (Vv4rs.sherpaOnnxSSLanguageVoice[lang] != null){
          print('loadSherpaOnnxEngine: voice is not null');
          await createOfflineTts(
            Vv4rs.sherpaOnnxSSLanguageVoice[lang]!.id ?? '',
          );
          print('loadSherpaOnnxEngine: done');
        }
      }
    }
  }

  static Future<String> generateWaveFilename([String suffix = '']) async {
     print('generateWaveFilename: start');
    final Directory directory = await getApplicationSupportDirectory();
    print('generateWaveFilename: directory has been got');
    DateTime now = DateTime.now();
    print('generateWaveFilename: time has been got');
    final filename =
        '${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}$suffix.wav';
    print('generateWaveFilename: file name has been set, returning now');
    return p.join(directory.path, filename);
  }

  static Future<void> speak(
    bool forSS,
    String lang, 
    String text, 
    sherpa_onnx.OfflineTts sherpaOnnxSynth,
    Future<void> Function() init,
    AudioPlayer player,
  ) async {
    print('speak: start');
    await init();
    await player.stop();

    print('speak: init has run, player is ready');

    final stopwatch = Stopwatch();
      stopwatch.start();
    print('speak: stopwatch started');

      final speakerID = (forSS) 
        ? Vv4rs.sherpaOnnxSSLanguageVoice[lang]!.speakerID
        : Vv4rs.sherpaOnnxLanguageVoice[lang]!.speakerID;
      final rate = (forSS) 
        ? Vv4rs.sherpaOnnxSSLanguageVoice[lang]!.lengthScale
        : Vv4rs.sherpaOnnxLanguageVoice[lang]!.lengthScale;
    
    print('speak: speaker is and rate set');

      final audio = 
        sherpaOnnxSynth.generate(
          text: text, 
          sid: speakerID ?? 0, 
          speed: rate ?? 1.0,
        );

    print('speak: audio set');

      final suffix = '-sid-${speakerID ?? 0}-speed-${(rate ?? 1.0).toStringAsPrecision(2)}';
      final filename = await generateWaveFilename(suffix);
  
    print('speak: suffix and file name set');

      final wav = sherpa_onnx.writeWave(
        filename: filename,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );

    print('speak: ready for wav');

      if (wav) {
        print('speak: wav started');

        V4rs.currentSpeakingFile = filename;

        print('speak: current speaking file set');

        stopwatch.stop();
        print('speak: stopwatch stopped');
        double elapsed = stopwatch.elapsed.inMilliseconds.toDouble();
        int wordCount(String text) {
          return text
            .trim()
            .split(RegExp(r'\s+'))
            .length;
         }
        V4rs.wordsPerMinute = wordCount(text)/elapsed;

        print('speak: start playing');
        await player.play(DeviceFileSource(V4rs.currentSpeakingFile!));
        print('speak: done');

        } else {
          print('speak: Failed to generate (SherpaOnnxV4rs.speakSS.65)',);
        }
  }

  static Future<void> pause(
    AudioPlayer player, //ensure same player as speak!
  ) async {
    V4rs.pauseMoment = await player.getCurrentPosition();
    await player.stop();
  }

  static Future<void> resume(
    AudioPlayer player, //ensure same player as speak!
  ) async {
      if (V4rs.pauseMoment != null){
      await player.setSource(DeviceFileSource(V4rs.currentSpeakingFile!));
      await player.seek(V4rs.pauseMoment!);
      await player.resume();
    }
  }

  static Future<void> rewind(
    AudioPlayer player, //ensure same player as speak!
  ) async {
    if (V4rs.currentSpeakingFile != null) {
      player.stop;
      await player.play(DeviceFileSource(V4rs.currentSpeakingFile!));
    }
  }
}
