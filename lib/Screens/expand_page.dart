import 'package:flutter/material.dart';
import 'package:flutterkeysaac/Variables/assorted_ui/ui_shortcuts.dart';
import 'package:flutterkeysaac/Variables/variables.dart';
import 'package:flutterkeysaac/Variables/colors/color_variables.dart';
import 'package:flutter/services.dart';
import 'package:flutterkeysaac/Variables/fonts/font_variables.dart';
import 'package:flutterkeysaac/Variables/system_tts/tts_interface.dart';
import 'package:flutterkeysaac/Variables/system_tts/tts_factory.dart';
import 'package:flutterkeysaac/Variables/settings/settings_variables.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

class ExpandPage extends StatefulWidget {
  final Map<String, sherpa_onnx.OfflineTts?>? speakSelectSherpaOnnxSynth;
  final Future<void> Function() initForSS;
  final AudioPlayer playerForSS;

  const ExpandPage({
    super.key,
    required this.speakSelectSherpaOnnxSynth,
    required this.initForSS,
    required this.playerForSS,
  });

  @override
  State<ExpandPage> createState() => _ExpandPage();
}

class _ExpandPage extends State<ExpandPage> with WidgetsBindingObserver {
 late final TextEditingController _controller;
 
  TTSInterface? synth;
  bool synthInitialized = false;

 bool _isFlipped = false; 

  @override
  void initState() {
    initSynth();
    super.initState();
    _controller = TextEditingController(text:  V4rs.message.value);

    _controller.addListener(() {
      setState(() {
         V4rs.message.value = _controller.text;
      });
    });
  }

  Future<void> initSynth() async {
    synth = await TTSFactory.getTTS(
      languageCode: V4rs.selectedLanguage.value);
      setState(() {
        synthInitialized = true;
      });
  }

  @override
  void dispose() {
     V4rs.message.value = _controller.text; // Save the message before disposing
    _controller.dispose();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cv4rs.expandColor2,
      body: SafeArea(
        bottom: false, // Ignore keyboard
        child: Padding (
          padding: EdgeInsets.all(V4rs.paddingValue(5)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              var totalHeight = constraints.maxHeight;
              var totalWidth = constraints.maxWidth;

              return Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                 if (!_isFlipped) 
                  SizedBox (
                    height: V4rs.xSmallModeWidth 
                      ? totalHeight *  0.05
                      : totalHeight *  0.06,
                    width: V4rs.xSmallModeWidth 
                      ? totalWidth *  0.2
                      : totalWidth *  0.09,
                    child: ExpandButtonStyle(
                      imagePath: 'assets/interface_icons/interface_icons/iClear.png',
                      onPressed: () {
                            if (Sv4rs.speakInterfaceButtonsOnSelect) {
                            V4rs.speakOnSelect(
                              'clear', 
                              V4rs.selectedLanguage.value, 
                              synth!,
                              widget.speakSelectSherpaOnnxSynth,
                              widget.initForSS,
                              widget.playerForSS,
                              );
                            }
                          _controller.clear();
                        },
                    ),
                  ),
                // Expanded Message Window
                Expanded(
                  flex: 15,
                  child: Padding ( 
                    padding: EdgeInsets.fromLTRB(
                      V4rs.paddingValue(5),
                      5,
                      V4rs.paddingValue(5),
                      V4rs.paddingValue(5),
                    ),
                    child: 
                        Container(
                            decoration: BoxDecoration(
                              color: Cv4rs.expandColor4,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: _isFlipped 
                                  ? Matrix4.rotationZ(3.1415)// 180 degrees in radians
                                  : Matrix4.identity(),
                              child: TextField(
                                controller: _controller,
                                minLines: 12,
                                maxLines: null,
                                style: Fv4rs.expandedLabelStyle,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Cv4rs.expandColor3),
                                    hintText: 'Message Window...',
                                    contentPadding: EdgeInsets.fromLTRB(
                                      V4rs.paddingValue(20), 
                                      V4rs.paddingValue(50), 
                                      V4rs.paddingValue(20), 
                                      V4rs.paddingValue(20)
                                    ),
                                  ),
                                  textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                  ),
                ),
              
                //bottom row
                Expanded(
                  flex: 2,
                  child: Padding(padding: EdgeInsets.all(V4rs.paddingValue(5)),
                  child: Row( 
                    children: [
                      //back button 
                    Expanded(
                      flex: 1,
                      child:
                    FractionallySizedBox(
                        heightFactor: 0.8,
                        widthFactor: 1,
                        child: Padding(
                          padding: EdgeInsets.all(V4rs.xSmallMode ? 3 : 5),
                          child: ExpandButtonStyle(
                            imagePath: 'assets/interface_icons/interface_icons/iBack.png',
                            onPressed: () {
                              if (Sv4rs.speakInterfaceButtonsOnSelect) {
                                    V4rs.speakOnSelect(
                                      'back', V4rs.selectedLanguage.value, 
                                      synth!,
                                      widget.speakSelectSherpaOnnxSynth,
                                      widget.initForSS,
                                      widget.playerForSS,
                                      );
                                    }
                              V4rs.showExpandPage.value = false;
                            },
                          ),
                        ),
                    ),
                    ),
                    //slider for font size
                    Expanded(
                      flex: V4rs.xSmallMode ? 6 : 10,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                         overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: Fv4rs.expandedFontSize,
                          min: 20.0,
                          max: 150.0,
                          activeColor: Cv4rs.expandColor4,
                          inactiveColor: Cv4rs.expandColor1,
                          thumbColor: Cv4rs.expandColor4, 
                          label: 'Font Size: ${Fv4rs.expandedFontSize.round()}',
                          onChangeEnd: (value) {
                             if (Sv4rs.speakInterfaceButtonsOnSelect) {
                              V4rs.speakOnSelect(
                                'font size ${Fv4rs.expandedFontSize.round()}', 
                                V4rs.selectedLanguage.value, 
                                synth!,
                                widget.speakSelectSherpaOnnxSynth,
                                widget.initForSS,
                                widget.playerForSS,
                              );
                            }
                          },
                          onChanged: (value)  {
                            setState(() {
                              Fv4rs.expandedFontSize = value;
                            });
                          },
                        ),
                        ),
                    ),
                    //copy text button
                    Expanded(
                      flex: 1, 
                      child:
                    FractionallySizedBox(
                        heightFactor: 0.8,
                        widthFactor: 1,
                        child: Padding(
                          padding: EdgeInsets.all(V4rs.xSmallMode ? 3 : 5),
                          child: ExpandButtonStyle(
                            imagePath: 'assets/interface_icons/interface_icons/iCopy.png',
                            onPressed: () {
                              if (Sv4rs.speakInterfaceButtonsOnSelect) {
                                    V4rs.speakOnSelect(
                                      'copy', 
                                      V4rs.selectedLanguage.value, 
                                      synth!,
                                      widget.speakSelectSherpaOnnxSynth,
                                      widget.initForSS,
                                      widget.playerForSS,
                                      );
                                    }
                              Clipboard.setData(ClipboardData(text: _controller.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Text copied to clipboard'), 
                                  duration: Duration(milliseconds: 750),
                                  ),
                              );
                            },
                          ),
                        ),
                    ),
                    ),
                    //flip text button
                    Expanded(
                      flex: 1, 
                      child:
                    FractionallySizedBox(
                        heightFactor: 0.8,
                        widthFactor: 1,
                        child: Padding(
                          padding: EdgeInsets.all(V4rs.xSmallMode ? 3 : 5),
                          child: ExpandButtonStyle(
                            imagePath: 'assets/interface_icons/interface_icons/iFlip.png',
                            onPressed: () {
                              setState(() {
                                if (Sv4rs.speakInterfaceButtonsOnSelect) {
                                    V4rs.speakOnSelect(
                                      'flip', 
                                      V4rs.selectedLanguage.value, 
                                      synth!,
                                      widget.speakSelectSherpaOnnxSynth,
                                      widget.initForSS,
                                      widget.playerForSS,
                                      );
                                    }
                                _isFlipped = !_isFlipped;
                              });
                            },
                          ),
                        ),
                    ),
                    ),
                  ],
                    ),

                  ),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }
}