import 'package:flutter/material.dart';
import 'package:flutterkeysaac/Screens/editor.dart';
import 'package:flutterkeysaac/Screens/onboarding.dart'; 
import 'package:flutterkeysaac/Screens/home.dart';
import 'package:flutterkeysaac/Variables/editing/editor_variables.dart';
import 'package:flutterkeysaac/Variables/assorted_ui/ui_pops.dart';
import 'package:flutterkeysaac/Variables/variables.dart'; 
import 'package:flutterkeysaac/Screens/expand_page.dart';
import 'package:flutterkeysaac/Variables/system_tts/tts_interface.dart';
import 'package:flutterkeysaac/Variables/system_tts/tts_factory.dart';
import 'package:flutterkeysaac/Variables/settings/settings_variables.dart';
import 'package:flutterkeysaac/Variables/settings/boardset_settings_variables.dart';
import 'dart:async';
import 'package:flutterkeysaac/Variables/settings/voice_variables.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
import 'package:flutterkeysaac/Variables/sherpa_onnx_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await V4rs.loadSavedValues();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {

  const MyApp({super.key}); 

  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  TTSInterface? synth;

  bool synthInitialized = false;
  bool speakSelectSherpaOnnxInitialized = false;
  bool sherpaOnnxInitialized = false;

  sherpa_onnx.OfflineTts? sherpaOnnxSynth;
  sherpa_onnx.OfflineTts? speakSelectSherpaOnnxSynth;

  late AudioPlayer openTtsPlayerSherpaOnnx;
  late AudioPlayer openTtsPlayerSpeakSelectSherpaOnnx;

  int? _highlightStart;
  int? _highlightLength;
  StreamSubscription? _wordSub;
  StreamSubscription? _doneSub;

  @override
  void initState() {
    super.initState();
    initSynth();
    initSherpaOnnx();
    initSpeakSelectSherpaOnnx();
  }

  Future<void> initSherpaOnnx() async {
     print('init sherpa onnx running');
    if (!sherpaOnnxInitialized) {
       print('init sherpa onnx not initialized');
      sherpa_onnx.initBindings();

      sherpaOnnxSynth?.free();
       print('init sherpa onnx free');
      sherpaOnnxSynth = await SherpaOnnxV4rs.loadSherpaOnnxEngine();

      openTtsPlayerSherpaOnnx = AudioPlayer();

      sherpaOnnxInitialized = true;
       print('init sherpa onnx ran, sherpa onnx synth is $sherpaOnnxSynth');
    }
  }

  Future<void> reloadSherpaOnnx() async {
    print('reload sherpa onnx running');
    sherpaOnnxInitialized = false;
      sherpa_onnx.initBindings();

      sherpaOnnxSynth?.free();
       print('reload sherpa onnx free');
      sherpaOnnxSynth = await SherpaOnnxV4rs.loadSherpaOnnxEngine();

      openTtsPlayerSherpaOnnx = AudioPlayer();

      sherpaOnnxInitialized = true;
       print('reload sherpa onnx ran, sherpa onnx synth is $sherpaOnnxSynth');
  }

  Future<void> initSpeakSelectSherpaOnnx() async {
    if (!speakSelectSherpaOnnxInitialized) {
      sherpa_onnx.initBindings();

      speakSelectSherpaOnnxSynth?.free();
      speakSelectSherpaOnnxSynth = await SherpaOnnxV4rs.loadSherpaOnnxSSEngine();

      openTtsPlayerSpeakSelectSherpaOnnx = AudioPlayer();

      speakSelectSherpaOnnxInitialized = true;
    }
  }
  

  Future<void> initSynth() async {
    final s = await TTSFactory.getTTS(languageCode: V4rs.selectedLanguage.value);

    if (!mounted) return;

    setState(() {
      synth = s;
      synthInitialized = true;
    });

    // Listen for word events (highlighting)
    subscribeWordStream();

    // Listen for speech done events
    _doneSub = synth?.onDone.listen((_) {
      if (!mounted) return;
      setState(() {
        _highlightStart = null;
        _highlightLength = null;
      });
    });
  }

  void subscribeWordStream() {
    if (synth?.wordStream == null) return;

    _wordSub = synth!.wordStream.listen((event) {
      if (!mounted) return;

      setState(() {
        _highlightStart = event['start'] as int?;
        _highlightLength = event['length'] as int?;
      });
    });
  }

  @override
  void dispose() {
    _wordSub?.cancel();
    _doneSub?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'FlutterKeysAAC',
      home: Builder(
        builder: (context) {
           print("main, start of builder: Vv4rs.sherpaOnnxLanguageVoice['English']: ${Vv4rs.sherpaOnnxLanguageVoice['English']}");
                  

           print("main after sherpa onnx init funcs: Vv4rs.sherpaOnnxLanguageVoice['English']: ${Vv4rs.sherpaOnnxLanguageVoice['English']}");
                   

          if (!synthInitialized || speakSelectSherpaOnnxInitialized == false || sherpaOnnxInitialized == false) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          return AnimatedBuilder(
            animation: Listenable.merge([
              V4rs.doOnboarding,
              V4rs.showExpandPage,
              V4rs.showSettings,
              Ev4rs.showEditor,
            ]), 
            builder: (context, _) {
            //=====: onboarding :====
              if (V4rs.doOnboarding.value) {
                return Onboarding();
            //=====: expand page :====
              } else if (V4rs.showExpandPage.value) {
                return ExpandPage(
                  speakSelectSherpaOnnxSynth: speakSelectSherpaOnnxSynth,
                  initForSS: initSpeakSelectSherpaOnnx,
                  playerForSS: openTtsPlayerSpeakSelectSherpaOnnx,
                );
            //=====: editor :====
              } else if (Ev4rs.showEditor.value) {
                return Editor(
                  synth: synth!,
                  speakSelectSherpaOnnxSynth: speakSelectSherpaOnnxSynth,
                    initForSS: initSpeakSelectSherpaOnnx,
                    playerForSS: openTtsPlayerSpeakSelectSherpaOnnx,
                );
              }
             //=====: home :====
              else {
                return GestureDetector( 
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                      showOptionsPopupForSpeakOnSelect(context, optionLabels: [
                        "Interface Buttons", 
                        "Navigation Buttons", 
                        "Grammer Buttons",
                        "Sub-Folder Buttons", 
                        "Buttons", 
                        "Typing Keys", 
                        "Folder Buttons", 
                        "Pocket Folder", 
                        "Audio Tile" 
                      ], 
                      optionValues: [
                        Sv4rs.speakInterfaceButtonsOnSelect, 
                        V4rs.intToBool(Bv4rs.navRowSpeakOnSelect),
                        V4rs.intToBool(Bv4rs.grammerRowSpeakOnSelect),
                        V4rs.intToBool(Bv4rs.subFolderSpeakOnSelect),
                        V4rs.intToBool(Bv4rs.buttonSpeakOnSelect),
                        V4rs.intToBool(Bv4rs.typingKeySpeakOnSelect),
                        V4rs.intToBool(Bv4rs.folderSpeakOnSelect),
                        V4rs.intToBool(Bv4rs.pocketFolderSpeakOnSelect),
                        V4rs.intToBool(Bv4rs.audioTileSpeakOnSelect),
                      ], onDone: (newVal) {
                        setState(() {
                          Sv4rs.speakInterfaceButtonsOnSelect = newVal[0];
                          Sv4rs.saveSpeakInterfaceButtonsOnSelect(newVal[0]);
                          Bv4rs.navRowSpeakOnSelect = V4rs.boolToInt2(newVal[1]);
                          Bv4rs.saveNavRowSpeakOnSelect(V4rs.boolToInt2(newVal[1]));
                          Bv4rs.grammerRowSpeakOnSelect = (V4rs.boolToInt3(newVal[2]));
                          Bv4rs.savegrammerRowSpeakOnSelect(V4rs.boolToInt2(newVal[2]));
                          Bv4rs.subFolderSpeakOnSelect = V4rs.boolToInt2(newVal[3]);
                          Bv4rs.saveSubFolderSpeakOnSelect(V4rs.boolToInt2(newVal[3]));
                          Bv4rs.buttonSpeakOnSelect = V4rs.boolToInt3(newVal[4]);
                          Bv4rs.saveButtonSpeakOnSelect(V4rs.boolToInt3(newVal[4]));
                          Bv4rs.typingKeySpeakOnSelect = V4rs.boolToInt3(newVal[5]);
                          Bv4rs.savetypingKeySpeakOnSelect(V4rs.boolToInt3(newVal[5]));
                          Bv4rs.folderSpeakOnSelect = V4rs.boolToInt2(newVal[6]);
                          Bv4rs.savefolderSpeakOnSelect(V4rs.boolToInt2(newVal[6]));
                          Bv4rs.pocketFolderSpeakOnSelect = V4rs.boolToInt3(newVal[7]);
                          Bv4rs.savepocketFolderSpeakOnSelect(V4rs.boolToInt3(newVal[7]));
                          Bv4rs.audioTileSpeakOnSelect = V4rs.boolToInt2(newVal[8]);
                          Bv4rs.saveaudioTileSpeakOnSelect(V4rs.boolToInt2(newVal[8]));
                        });
                      }
                      );
                    }
                  },
                  child: Home(
                    synth: synth!,
                    highlightLength: _highlightLength,
                    highlightStart: _highlightStart,
                    sherpaOnnxSynth: sherpaOnnxSynth,
                    openTTSPlayer: openTtsPlayerSherpaOnnx,
                    init: initSherpaOnnx,
                    speakSelectSherpaOnnxSynth: speakSelectSherpaOnnxSynth,
                    initForSS: initSpeakSelectSherpaOnnx,
                    playerForSS: openTtsPlayerSpeakSelectSherpaOnnx,
                    reloadSherpaOnnx: reloadSherpaOnnx,
                  )
                );
              }
            }
          );
        }
      ),
    );
  }
}
      