
import 'package:flutterkeysaac/Variables/settings/voice_variables.dart';
import 'package:flutterkeysaac/Variables/variables.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import "dart:io";

//supports vits, kokoro, and matcha

class SherpaOnnxV4rs {

  late final String globalVocoderPath;

  static Future<sherpa_onnx.OfflineTts> createOfflineTts(String voiceId) async {
    print('creating offline TTS');
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
    final acoustic = p.join(base, 'voice.id-acoustic.onnx');
    final vocodor = p.join(base, 'voice.id-vocodor.onnx');

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

    final espeakDir = Directory(p.join(base, "eSpeak-ng"));
    final isEspeakEmpty = !espeakDir.existsSync() || espeakDir.listSync().isEmpty;
    final isMatcha = isEspeakEmpty;
    final isMultiMatcha = isEspeakEmpty && Directory(vocodor).existsSync();

    late final sherpa_onnx.OfflineTtsVitsModelConfig vits;
    late final sherpa_onnx.OfflineTtsKokoroModelConfig kokoro;
    late final sherpa_onnx.OfflineTtsMatchaModelConfig matcha;

    if (isKokoro) {
      print('is kokoro');
      vits = sherpa_onnx.OfflineTtsVitsModelConfig(); // unused
      kokoro = sherpa_onnx.OfflineTtsKokoroModelConfig(
        model: modelOnnx,
        voices: voicesBin,
        tokens: tokens,
        dataDir: espeak,
        lexicon: lexicons,
      );
      matcha = sherpa_onnx.OfflineTtsMatchaModelConfig(); //unused
    } else if (isMultiMatcha){
      print('is multi matcha');
      vits = sherpa_onnx.OfflineTtsVitsModelConfig(); //unused
      kokoro = sherpa_onnx.OfflineTtsKokoroModelConfig(); // unused
      matcha = sherpa_onnx.OfflineTtsMatchaModelConfig(
        acousticModel: acoustic,
        vocoder: vocodor,
        tokens: tokens,
        dataDir: '',
        lexicon: lexicons,
      );
    } else if (isMatcha){
      print('is matcha');
      vits = sherpa_onnx.OfflineTtsVitsModelConfig(); //unused
      kokoro = sherpa_onnx.OfflineTtsKokoroModelConfig();
      matcha = sherpa_onnx.OfflineTtsMatchaModelConfig(
        acousticModel: modelOnnx,
        vocoder: Vv4rs.globalVocoderPath,
        tokens: tokens,
        dataDir: '',
        lexicon: lexicons,
      );
    } else {
      print('is vits');
      vits = sherpa_onnx.OfflineTtsVitsModelConfig(
        model: modelOnnx,
        tokens: tokens,
        lexicon: lexicons,
        dataDir: espeak,
      );
      kokoro = sherpa_onnx.OfflineTtsKokoroModelConfig(); // unused
      matcha = sherpa_onnx.OfflineTtsMatchaModelConfig(); //unused
    }

    final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
      vits: vits, //settings for vits models
      kokoro: kokoro, //settings for kokoro models
      matcha: matcha, //settings for matcha models
      
      numThreads: 2, //number of cpu threads allowed
      debug: true, //print info? yes or no
      provider: 'cpu', //what hardware backend to use
    );

    final config = sherpa_onnx.OfflineTtsConfig(
      model: modelConfig, //vits, kokoro, matcha
      ruleFsts: 
        (isMatcha || isMultiMatcha) 
        ? ''
        : ruleFsts, 
      ruleFars: 
        (isMatcha || isMultiMatcha) 
        ? ''
        : ruleFars,
      maxNumSenetences: 1, //sentance count for proccess per call
    );


    final tts = sherpa_onnx.OfflineTts(config);

    return tts;
    }

  static Future<dynamic> loadSherpaOnnxEngine(String lang) async {
    print('4. loading sherpa onnx');
      print('4. lang $lang');
      if (Vv4rs.myEngineForVoiceLang[lang] == 'sherpa-onnx'){
        print('4. engine is sherpa onnx');
        print('4. (Vv4rs.sherpaOnnxLanguageVoice[lang] ${Vv4rs.sherpaOnnxLanguageVoice[lang]}');
        if (Vv4rs.sherpaOnnxLanguageVoice[lang] != null){
          final tts = await createOfflineTts(
            Vv4rs.sherpaOnnxLanguageVoice[lang]!.id ?? '',
          );
          return tts;
        }
    }
  }

  static Future<dynamic> loadSherpaOnnxSSEngine(String language) async {
      if (Vv4rs.myEngineForSSVoiceLang[language] == 'sherpa-onnx'){
        if (Vv4rs.sherpaOnnxSSLanguageVoice[language] != null){
          final tts = await createOfflineTts(
            Vv4rs.sherpaOnnxSSLanguageVoice[language]!.id ?? '',
          );
          return tts;
        }
      }
  }

  static Future<String> generateWaveFilename([String suffix = '']) async {
    final Directory directory = await getApplicationSupportDirectory();
    DateTime now = DateTime.now();
    final filename =
        '${now.year.toString()}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}$suffix.wav';
    return p.join(directory.path, filename);
  }

  static Future<void> speak(
    bool forSS,
    String lang, 
    String text, 
    Map<String, sherpa_onnx.OfflineTts?>? sherpaOnnxSynth,
    AudioPlayer player,
  ) async {
    await player.stop();


    final speakerID = (forSS) 
      ? Vv4rs.sherpaOnnxSSLanguageVoice[lang]?.speakerID
      : Vv4rs.sherpaOnnxLanguageVoice[lang]?.speakerID;
    final rate = (forSS) 
      ? Vv4rs.sherpaOnnxSSLanguageVoice[lang]?.lengthScale
      : Vv4rs.sherpaOnnxLanguageVoice[lang]?.lengthScale;
  
    final audio = 
      sherpaOnnxSynth?[lang]?.generate(
        text: text, 
        sid: speakerID ?? 0, 
        speed: rate ?? 1.0,
      );

    final suffix = '-sid-${speakerID ?? 0}-speed-${(rate ?? 1.0).toStringAsPrecision(2)}';
    final filename = await generateWaveFilename(suffix);

    if (audio != null){
      final wav = sherpa_onnx.writeWave(
        filename: filename,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );

      if (wav) {
        V4rs.currentSpeakingFile = filename;

        double time = audio.samples.length / audio.sampleRate; //in seconds
        double minutes = time * 60;
        int wordCount(String text) {
          return text
            .trim()
            .split(RegExp(r'\s+'))
            .length;
          }

        V4rs.currentWPM = wordCount(text)/minutes;

        final completer = Completer<void>();
        player.onPlayerComplete.listen((event) {
          if (!completer.isCompleted) completer.complete();
        });
        await player.play(DeviceFileSource(V4rs.currentSpeakingFile!));
        await completer.future; 
      }
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
