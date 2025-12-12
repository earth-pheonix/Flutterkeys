import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;


class TtsApp extends StatelessWidget {
  const TtsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(child: TtsRunner()),
      ),
    );
  }
}

class TtsRunner extends StatefulWidget {
  const TtsRunner({super.key});

  @override
  State<TtsRunner> createState() => _TtsRunnerState();
}

class _TtsRunnerState extends State<TtsRunner> {
  late final AudioPlayer _player;
  sherpa_onnx.OfflineTts? _tts;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _generateAndSpeak();
  }

  // ----------------------------
  // Minimal helper functions
  // ----------------------------

  // Copies all assets to a writable directory
  Future<void> copyAllAssetFiles() async {
    final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allFiles = assetManifest.listAssets();
    final dir = await getApplicationSupportDirectory();

    for (final src in allFiles) {
      final dst = p.join(dir.path, p.basename(src));
      final data = await rootBundle.load(src);
      await File(dst)
          .create(recursive: true)
          .then((f) => f.writeAsBytes(data.buffer.asUint8List()));
    }
  }

  // Generates a timestamped WAV filename
  Future<String> generateWaveFilename([String suffix = '']) async {
    final dir = await getApplicationSupportDirectory();
    final now = DateTime.now();
    final filename =
        '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}-${now.hour.toString().padLeft(2,'0')}-${now.minute.toString().padLeft(2,'0')}-${now.second.toString().padLeft(2,'0')}$suffix.wav';
    return p.join(dir.path, filename);
  }

  // Creates the OfflineTts instance
  Future<sherpa_onnx.OfflineTts> createOfflineTts() async {
    await copyAllAssetFiles();
    sherpa_onnx.initBindings();

    // Example: replace with your selected model files in assets
    final modelDir = 'vits-piper-en_US-amy-low'; //id
    final modelName = 'en_US-amy-low.onnx'; //onnx
    final directory = await getApplicationSupportDirectory();
    final modelPath = p.join(directory.path, modelDir, modelName); //path to onnx

    final vits = sherpa_onnx.OfflineTtsVitsModelConfig( //any models with vits prefix use this wrapper
      model: modelPath, //model
    );

    final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
      vits: vits,
      kokoro: sherpa_onnx.OfflineTtsKokoroModelConfig(), //any models with kokoro prefix use this wrapper
      numThreads: 2,
    );

    final config = sherpa_onnx.OfflineTtsConfig(model: modelConfig);

    return sherpa_onnx.OfflineTts(config);
  }

  // ----------------------------
  // Core TTS logic
  // ----------------------------

  Future<void> _generateAndSpeak() async {
    _tts = await createOfflineTts();

    const text = "Hello world! This is a single-file offline TTS demo.";

    final audio = _tts!.generate(text: text, sid: 0, speed: 1.0);

    final filename = await generateWaveFilename('-example');

    final ok = sherpa_onnx.writeWave(
      filename: filename,
      samples: audio.samples,
      sampleRate: audio.sampleRate,
    );

    if (ok) {
      await _player.play(DeviceFileSource(filename));
    } else {
      print('Failed to save generated audio');
    }
  }

  @override
  void dispose() {
    _tts?.free();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Generating speech...'));
  }
}