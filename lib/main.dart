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

  Map<String, sherpa_onnx.OfflineTts?> sherpaOnnxSynth = {};
  Map<String, sherpa_onnx.OfflineTts?> speakSelectSherpaOnnxSynth = {};

  late AudioPlayer openTtsPlayerSherpaOnnx;
  late AudioPlayer openTtsPlayerSpeakSelectSherpaOnnx;

  int? _highlightStart;
  int? _highlightLength;
  StreamSubscription? _doneSub;

  @override
  void initState() {
    super.initState();
    initSynth();
    initSherpaOnnx();
    initSpeakSelectSherpaOnnx();
    V4rs.useWPM.addListener((){
      subscribeWordStream();
    });
  }

  Future<void> initSherpaOnnx() async {
    print('0. init sherpa onnx');
    if (!sherpaOnnxInitialized) {
      print('0. sherpa onnx is not initialized');
    sherpa_onnx.initBindings();
      for (final lang in Sv4rs.myLanguages){
        print('0. lang: $lang');
        sherpaOnnxSynth[lang]?.free(); 
        sherpaOnnxSynth[lang] = await SherpaOnnxV4rs.loadSherpaOnnxEngine(lang);
      }
      openTtsPlayerSherpaOnnx = AudioPlayer();
      sherpaOnnxInitialized = true;
    }
  }

  Future<void> reloadSherpaOnnx(bool forSS) async {
    sherpaOnnxInitialized = false;
    sherpa_onnx.initBindings();
    print('3. reload sherpa onnx');

    if (forSS){
      print('3. forSS');
      for (final lang in Sv4rs.myLanguages){
        print('3. lang $lang');
        speakSelectSherpaOnnxSynth[lang]?.free();
        print('3. free');
        speakSelectSherpaOnnxSynth[lang] = await SherpaOnnxV4rs.loadSherpaOnnxSSEngine(lang);
        print('3. speakSelectSherpaOnnxSynth?[lang] ${speakSelectSherpaOnnxSynth[lang]}');
      }
      openTtsPlayerSpeakSelectSherpaOnnx = AudioPlayer();
    } 

    else {
      print('3. not for ss');
      for (final lang in Sv4rs.myLanguages){
        print('3. lang $lang');
        sherpaOnnxSynth[lang]?.free();
        print('3. free');
        sherpaOnnxSynth[lang] = await SherpaOnnxV4rs.loadSherpaOnnxEngine(lang);
        print('3. sherpaOnnxSynth?[lang] ${sherpaOnnxSynth[lang]}');
      }
      openTtsPlayerSherpaOnnx = AudioPlayer();
    }

    sherpaOnnxInitialized = true;
  }

  Future<void> initSpeakSelectSherpaOnnx() async {
    if (!speakSelectSherpaOnnxInitialized) {
      sherpa_onnx.initBindings();
      for (final lang in Sv4rs.myLanguages){
        speakSelectSherpaOnnxSynth[lang]?.free();
        speakSelectSherpaOnnxSynth[lang] = await SherpaOnnxV4rs.loadSherpaOnnxSSEngine(lang);
      }
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
    print('subscribing');

    if (V4rs.useWPM.value) {
      final interval = Duration(milliseconds: (60000 / V4rs.currentWPM).round());
      final words = V4rs.message.value.split(' ');
        print('WORDS: $words');
        print('WORD COUNT: ${words.length}');
      int currentHighlightStart = 0;
      V4rs.theStream = null;

      V4rs.theStream = Stream<Map<String, int>?>.periodic(interval, (i) {
        if (i >= words.length) return null;

        String word = words[i];
        int start = V4rs.message.value.indexOf(word, currentHighlightStart);
        currentHighlightStart = start + word.length; 
        
        return {
          'start': start, 
          'length': word.length
        };
      })
      .take(words.length)
      .where((e) => e != null)
      .asBroadcastStream();


    } else {
      if (synth?.wordStream == null) return;
      V4rs.theStream = synth!.wordStream;
    }
    V4rs.streamVersion.value++;
  }

  @override
  void dispose() {
    _doneSub?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'FlutterKeysAAC',
      home: Builder(
        builder: (context) {
          if (!synthInitialized 
            || speakSelectSherpaOnnxInitialized == false 
            || sherpaOnnxInitialized == false
          ) {
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
      