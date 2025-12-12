// Copyright (c)  2024  Xiaomi Corporation
import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

import './model.dart';
import './utils.dart';

class TtsScreen extends StatefulWidget {
  const TtsScreen({super.key});

  @override
  State<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends State<TtsScreen> {
  late final TextEditingController controllerTextInput;
  late final TextEditingController controllerSid;
  late final TextEditingController controllerHint;
  late final AudioPlayer _player;
  String title = 'Text to speech';
  String _lastFilename = '';
  bool _isInitialized = false;
  int _maxSpeakerID = 0;
  double _speed = 1.0;

  sherpa_onnx.OfflineTts? _tts;

  @override
  void initState() {
    controllerTextInput = TextEditingController();
    controllerHint = TextEditingController();
    controllerSid = TextEditingController(text: '0');

    super.initState();
  }
 
  Future<void> _init() async {
    if (!_isInitialized) {
      sherpa_onnx.initBindings();

      _tts?.free();
      _tts = await createOfflineTts();

      _player = AudioPlayer();

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                  decoration: InputDecoration(
                    labelText: "Speaker ID (0-$_maxSpeakerID)",
                    hintText: 'Please input your speaker ID',
                  ),
                  keyboardType: TextInputType.number,
                  maxLines: 1,
                  controller: controllerSid,
                  onTapOutside: (PointerDownEvent event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]),
              Slider(
                // decoration: InputDecoration(
                //   labelText: "speech speed",
                // ),
                label: "Speech speed ${_speed.toStringAsPrecision(2)}",
                min: 0.5,
                max: 3.0,
                divisions: 25,
                value: _speed,
                onChanged: (value) {
                  setState(() {
                    _speed = value;
                  });
                },
              ),
              const SizedBox(height: 5),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Please enter your text here',
                ),
                maxLines: 5,
                controller: controllerTextInput,
                onTapOutside: (PointerDownEvent event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
              const SizedBox(height: 5),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                OutlinedButton(
                  child: Text("Generate"),
                  onPressed: () async {
                    await _init();
                    await _player?.stop();

                    setState(() {
                      _maxSpeakerID = _tts?.numSpeakers ?? 0;
                      if (_maxSpeakerID > 0) {
                        _maxSpeakerID -= 1;
                      }
                    });

                    if (_tts == null) {
                      controllerHint.value = TextEditingValue(
                        text: 'Failed to initialize tts',
                      );
                      return;
                    }

                    controllerHint.value = TextEditingValue(
                      text: '',
                    );

                    final text = controllerTextInput.text.trim();
                    if (text == '') {
                      controllerHint.value = TextEditingValue(
                        text: 'Please first input your text to generate',
                      );
                      return;
                    }

                    final sid = int.tryParse(controllerSid.text.trim()) ?? 0;

                    final stopwatch = Stopwatch();
                    stopwatch.start();
                    final audio = _tts!.generate(text: text, sid: sid, speed: _speed);
                    final suffix = '-sid-$sid-speed-${_speed.toStringAsPrecision(2)}';
                    final filename = await generateWaveFilename(suffix);

                    final ok = sherpa_onnx.writeWave(
                      filename: filename,
                      samples: audio.samples,
                      sampleRate: audio.sampleRate,
                    );

                    if (ok) {
                      stopwatch.stop();
                      double elapsed = stopwatch.elapsed.inMilliseconds.toDouble();

                      double waveDuration = audio.samples.length.toDouble() / audio.sampleRate.toDouble();

                      controllerHint.value = TextEditingValue(
                        text: 'Saved to\n$filename\n'
                            'Elapsed: ${(elapsed / 1000).toStringAsPrecision(4)} s\n'
                            'Wave duration: ${waveDuration.toStringAsPrecision(4)} s\n'
                            'RTF: ${(elapsed / 1000).toStringAsPrecision(4)}/${waveDuration.toStringAsPrecision(4)} '
                            '= ${(elapsed / 1000 / waveDuration).toStringAsPrecision(3)} ',
                      );
                      _lastFilename = filename;

                      await _player?.play(DeviceFileSource(_lastFilename));
                    } else {
                      controllerHint.value = TextEditingValue(
                        text: 'Failed to save generated audio',
                      );
                    }


                  },
                ),
                const SizedBox(width: 5),
                OutlinedButton(
                  child: Text("Clear"),
                  onPressed: () {
                    controllerTextInput.value = TextEditingValue(
                      text: '',
                    );

                    controllerHint.value = TextEditingValue(
                      text: '',
                    );
                  },
                ),
                const SizedBox(width: 5),
                OutlinedButton(
                  child: Text("Play"),
                  onPressed: () async {
                    if (_lastFilename == '') {
                      controllerHint.value = TextEditingValue(
                        text: 'No generated wave file found',
                      );
                      return;
                    }
                    await _player.stop();
                    await _player.play(DeviceFileSource(_lastFilename));
                    controllerHint.value = TextEditingValue(
                      text: 'Playing\n$_lastFilename',
                    );
                  },
                ),
                const SizedBox(width: 5),
                OutlinedButton(
                  child: Text("Stop"),
                  onPressed: () async {
                    await _player?.stop();
                    controllerHint.value = TextEditingValue(
                      text: '',
                    );
                  },
                ),
              ]),
              const SizedBox(height: 5),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Logs will be shown here.\n'
                      'The first run is slower due to model initialization.',
                ),
                maxLines: 6,
                controller: controllerHint,
                readOnly: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts?.free();
    super.dispose();
  }
}