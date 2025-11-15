
import 'package:flutter/material.dart';
import 'package:flutterkeysaac/Variables/color_variables.dart';
import 'package:flutterkeysaac/Variables/variables.dart';
import 'package:flutterkeysaac/Variables/ui_shortcuts.dart';
import 'package:flutter/services.dart';
import 'package:flutterkeysaac/Variables/tts/tts_interface.dart';
import 'package:flutterkeysaac/Variables/more_font_variables.dart';
import 'package:flutterkeysaac/Variables/settings_variable.dart';
import 'package:flutterkeysaac/Variables/search_variables.dart';
import 'package:flutterkeysaac/Models/json_model_nav_and_root.dart';
import 'package:flutterkeysaac/Models/json_model_boards.dart';
import 'dart:async';

class MessageRow extends StatefulWidget {
  final TTSInterface synth;
  final int? highlightStart;
  final int? highlightLength;
  final Root? root;

  const MessageRow({
    super.key, 
    required this.synth,
    required this.root,
    this.highlightStart,
    this.highlightLength,
    });

  @override
  State<MessageRow> createState() => _MessageRowState();

}

class _MessageRowState extends State<MessageRow> {
  late final TextEditingController _controller;
  
  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];
  
  bool _internalChange = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: V4rs.message.value);
    _undoStack.add(_controller.value);
    _controller.addListener(() {
       if (_internalChange) return; 
        
        _undoStack.add(_controller.value);
        _redoStack.clear(); // Clear redo stack on new change
        
        if (_undoStack.length > 100) {
        _undoStack.removeAt(0);
        }

      setState(() {
         V4rs.message.value = _controller.text;
      });
    });
  }

  @override
  void dispose() {
     V4rs.message.value = _controller.text; // Save the message before disposing
    _controller.dispose();
    super.dispose();
  }

  // undo redo functions
  void _undo() {
    if (_undoStack.length < 2) return;

    _internalChange = true;
    _redoStack.add(_controller.value);
    _undoStack.removeLast(); // Discard current
    _controller.value = _undoStack.last;
    _internalChange = false;

    V4rs.message.value = _controller.text;
  }

  void _redo() {
    if (_redoStack.isEmpty) return;

    _internalChange = true;
    final value = _redoStack.removeLast();
    _undoStack.add(value);
    _controller.value = value;
    _internalChange = false;

    V4rs.message.value = _controller.text;
  }

 @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Flex(
          direction: Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 5.0),
                child: LeftOfMessageWindow(
                  controller: _controller,
                  synth: widget.synth, )
              ),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                  color: Cv4rs.themeColor4,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                  child: MessageWindow(
                    controller: _controller,
                    synth: widget.synth,
                    highlightLength: widget.highlightLength,
                    highlightStart: widget.highlightStart,
                    ),
              ),
              ),
            ),
            Expanded (
              flex: 3,
              child: ValueListenableBuilder(
                valueListenable: SeV4rs.openSearch, 
                builder: (context, openSearch, _) {
                  return (openSearch && (widget.root != null)) 
                    ? SearchDisplay(root: widget.root) 
                    : RightOfMessageWindow(
                      controller: _controller,
                      onUndo: _undo,
                      onRedo: _redo,
                      synth: widget.synth,
                    );
                }
            )
        ),
            
          ],
        );
      },
    );
  }
}

class LeftOfMessageWindow extends StatefulWidget {
  final TextEditingController controller;
  final TTSInterface synth;
  const LeftOfMessageWindow({super.key, required this.controller, required this.synth});

  @override
  State<LeftOfMessageWindow> createState() => _LeftOfMessageWindow();

}

class _LeftOfMessageWindow extends State<LeftOfMessageWindow> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder ( 
       builder: (context, constraints) { 

        var totalHeight = constraints.maxHeight;
        var totalWidth = constraints.maxWidth;

      return Column (
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //settings and expand button 
          Row( 
              children: [
                SizedBox(
                  height: totalHeight * 0.33,
                  width: totalWidth * 0.5,
                  child: Padding (
                padding: const EdgeInsets.all(3.0),
                child: ButtonStyle1(
                  imagePath: 'assets/interface_icons/interface_icons/iSettings.png',
                  onPressed: () {
                    if (Sv4rs.speakInterfaceButtonsOnSelect) {
                          V4rs.speakOnSelect('settings', V4rs.selectedLanguage.value, widget.synth);
                          }
                    V4rs.showSettings.value = true;
                  },
                ),
                ),
                ),
                SizedBox(
                  height: totalHeight * 0.33,
                  width: totalWidth * 0.5,
                  child: Padding (
                  padding: const EdgeInsets.all(3.0),
                  child: ButtonStyle1(
                  imagePath: 'assets/interface_icons/interface_icons/iExpand.png',
                  onPressed: () {
                    if (Sv4rs.speakInterfaceButtonsOnSelect) {
                          V4rs.speakOnSelect('expand page', V4rs.selectedLanguage.value, widget.synth);
                          }
                    V4rs.showExpandPage.value = true;
                  },
                ),
                ),
                ),
              ],
            ),
          //copy and bookmark button 
          Row( 
            children: [
              SizedBox( 
                height: totalHeight * 0.33,
              width: totalWidth * 0.5,
              child: Padding (
              padding: const EdgeInsets.all(3.0),
              child: ButtonStyle1(
                imagePath: 'assets/interface_icons/interface_icons/iCopy.png',
                onPressed: () {
                  if (Sv4rs.speakInterfaceButtonsOnSelect) {
                        V4rs.speakOnSelect('copy', V4rs.selectedLanguage.value, widget.synth);
                        }
                    Clipboard.setData(ClipboardData(text: widget.controller.text));
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
              SizedBox(
                height: totalHeight * 0.33,
              width: totalWidth * 0.5,
              child: Padding (
              padding: const EdgeInsets.all(3.0),
              child: ButtonStyle1(
                imagePath: 'assets/interface_icons/interface_icons/iBookmark.png',
                onPressed: () {
                  if (Sv4rs.speakInterfaceButtonsOnSelect) {
                        V4rs.speakOnSelect('bookmark', V4rs.selectedLanguage.value, widget.synth);
                        }
                  // put action here
                },
              ),
              ),
              ),
            ],
          ),
          //boardset button 
          SizedBox(
            height: totalHeight * 0.33,
            width: totalWidth * 0.5,
            child: Padding (
              padding: const EdgeInsets.all(3.0),
              child: ButtonStyle1(
                imagePath: 'assets/interface_icons/interface_icons/iBoardset.png',
                onPressed: () {
                  if (Sv4rs.speakInterfaceButtonsOnSelect) {
                        V4rs.speakOnSelect('quick swap', V4rs.selectedLanguage.value, widget.synth);
                        }
                  // put action here
                },
              ),
              ),
        ),
         ],
        );
      },
    );
  }
}

class MessageWindow extends StatefulWidget {
  final TextEditingController controller;
  final TTSInterface synth;
  final int? highlightStart;
  final int? highlightLength;
      
  const MessageWindow({
    super.key, 
    required this.controller, 
    required this.synth,
    this.highlightLength,
    this.highlightStart,
    });

  @override
  State<MessageWindow> createState() => _MessageWindowState();
}

class _MessageWindowState extends State<MessageWindow> {
  int currentLanguageIndex = 0;

  late final ScrollController _scrollController;

  late final VoidCallback _clearListener;
  late final VoidCallback _mwChange;

    @override
    void initState() {
      super.initState();

      // Listen for clear requests
      _clearListener = () {
        if (V4rs.message.value == "") {
          widget.controller.clear();
          V4rs.wasPaused.value = false;
          if (mounted) setState(() {}); // reset notifier
        }
      };
      V4rs.message.addListener(_clearListener);

      //listen for changes in message generally
      _mwChange = () {
        final oldValue = widget.controller.value;
        final oldSelection = widget.controller.selection;
        final newText = V4rs.message.value;

        if (oldValue.text == newText) return;
        
        widget.controller.value = TextEditingValue(
          text: newText,
          selection: oldSelection, // preserve cursor
          composing: oldValue.composing, //preserve chinese typing
        );
        
        if (V4rs.changedMWfromButton) {
        _scrollToBottom();
        }

        if (mounted) setState(() {}); 
      };
      V4rs.message.addListener(_mwChange);

      //stuff for languages 
      final savedLanguage = V4rs.selectedLanguage.value;
      final languagesList = Sv4rs.myLanguages.toList();
      final index = languagesList.indexOf(savedLanguage);

      if (index != -1) {
        currentLanguageIndex = index;
      } else {
        currentLanguageIndex = 0;
      }
      

      //scrolling 
      _scrollController = ScrollController();
    }

    //remove clear after speak listener
    @override
    void dispose() {
      _scrollController.dispose();
      V4rs.message.removeListener(_mwChange);
      V4rs.message.removeListener(_clearListener);
      super.dispose();
    }

  //var for language functions
  String get currentLanguage => Sv4rs.myLanguages.elementAt(currentLanguageIndex);
 
  //scrolling 
  void _scrollOneLineDown() {
    final double lineHeight = Fv4rs.mwFontSize * 2;

    _scrollController.animateTo(_scrollController.offset + lineHeight, 
    duration: Duration(milliseconds: 300), 
    curve: Curves.easeOut,
    );
  }

  void _scrollOneLineUp() {
    final double lineHeight = Fv4rs.mwFontSize * 2;

    _scrollController.animateTo(_scrollController.offset - lineHeight, 
    duration: Duration(milliseconds: 300), 
    curve: Curves.easeOut,
    );
  }

  void _scrollToBottom() {
  _scrollController.animateTo(
    _scrollController.position.maxScrollExtent - 1,
    duration: Duration(milliseconds: 300), 
    curve: Curves.easeOut,
  );
}


//UI starts
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Message window
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                child: Stack(
                  children: [
                    ValueListenableBuilder<bool>(
                  valueListenable: widget.synth.isSpeaking,
                  builder: (context, isSpeaking, _) {
                     return isSpeaking
                          ? Positioned.fill(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: V4rs.highlightAsSpoken ? 8 : 10),
                               child:
                               SizedBox( child: 
                            V4rs.highlightAsSpoken ? 
                                 _highlightedTextWidget()
                              
                            : SizedBox(child:
                            SingleChildScrollView( child:
                            Text(V4rs.message.value, style: Fv4rs.mwLabelStyle,) ))
                          )
                          )
                          )
                           : 
                    Positioned.fill(
                      child: SizedBox( 
                      child: MessageWindowTextField(
                        controller: widget.controller, 
                        scrollController: _scrollController,
                        ),
                      )
                      );
                    },
                      ),
                    
                    //
                    // scroll buttons
                    //
                   
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: 
                     Visibility(
                      visible: V4rs.showScrollButtons,
                      child:   
                      Container( 
                        height: 37,
                        width: 50,
                        padding: EdgeInsets.all(5),
                        child:
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Cv4rs.themeColor3,
                          padding: EdgeInsets.all(2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _scrollOneLineDown,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Cv4rs.uiIconColor,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset("assets/interface_icons/interface_icons/iArrow.png"),
                        ),
                      ),
                      ),
                    ),
                    ),
                    
                    Positioned(
                      right: 0,
                      bottom: 37,
                      child: 
                    Visibility(
                      visible: V4rs.showScrollButtons,
                      child:   
                      Container( 
                        height: 37,
                        width: 50,
                        padding: EdgeInsets.all(5),
                        child:
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Cv4rs.themeColor3,
                          padding: EdgeInsets.all(2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _scrollOneLineUp,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Cv4rs.uiIconColor,
                            BlendMode.srcIn,
                          ),
                          child: RotatedBox(quarterTurns: 2, child:
                          Image.asset("assets/interface_icons/interface_icons/iArrow.png"),
                        ),
                        ),
                      ),
                      ),
                    ),
                    ),
                    //
                    //language selector slider
                    //
                    Positioned(
                      right: V4rs.showScrollButtons ? 50 : 0,
                      bottom: 0,
                      child: 
                     Visibility(
                      visible: V4rs.showLanguageSelectorSlider,
                      child:  
                      Container(
                        decoration: BoxDecoration(
                          color: Cv4rs.themeColor4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child:
                      languageSelectorSlider(),
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Alerts
            if (Sv4rs.alertCount > 0)
            Expanded(
              flex: 1,
              child: Alerts(
                tts: widget.synth,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget languageSelectorSlider() {
  final languages = Sv4rs.myLanguages.toList();
  
  final double sliderWidth = languages.length * 40.0;

  return Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      //slider
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: 
      SizedBox(
        width: sliderWidth, // You can adjust this
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Cv4rs.themeColor3,
            inactiveTrackColor: Cv4rs.themeColor3,
            overlayShape: SliderComponentShape.noOverlay,
            thumbColor: Cv4rs.themeColor3,
          ),
          child: Slider(
            min: 0,
            max: (languages.length - 1).toDouble(),
            divisions: languages.length == 1 ? 1 : languages.length - 1,
            value: currentLanguageIndex.toDouble(),
            onChanged: (value) async {
               currentLanguageIndex = value.round();
                final currentLanguage = languages[currentLanguageIndex];
                if (Sv4rs.speakInterfaceButtonsOnSelect) {
                  V4rs.speakOnSelect('selected language set to ${V4rs.languageToLocalePrefix_(currentLanguage).toUpperCase()}', V4rs.selectedLanguage.value, widget.synth);
                  }
              setState(() {
                V4rs.selectedLanguage.value = currentLanguage;
              });
              await V4rs.saveSelectedLang(currentLanguage);
            },
          ),
        ),
      ),
      ),
      Container(
        width: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        decoration: BoxDecoration(
          color: Cv4rs.themeColor3,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          V4rs.languageToLocalePrefix_(currentLanguage).toUpperCase(),
          style: TextStyle(
            color: Cv4rs.themeColor4,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    ],
  ),
  );
}
Widget _highlightedTextWidget() {
  final defaultStyle = Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
  final text = widget.controller.text;

  // A key for the highlighted part
  final highlightKey = GlobalKey();

  return ValueListenableBuilder<int>(
    valueListenable: V4rs.highlightStart,
    builder: (context, notifierStart, _) {
      final start = (widget.highlightStart ?? 0) + notifierStart;
      final length = widget.highlightLength ?? text.length;

      final safeStart = start.clamp(0, text.length);
      final safeEnd = (safeStart + length).clamp(0, text.length);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (highlightKey.currentContext != null) {
          Scrollable.ensureVisible(
            highlightKey.currentContext!,
            duration: Duration.zero, 
            alignment: 0.5,         
          );
        }
      });

      return SingleChildScrollView(
        controller: _scrollController,
        child: RichText(
          textScaler: MediaQuery.of(context).textScaler,
          text: TextSpan(
            style: defaultStyle.merge(Fv4rs.mwLabelStyle),
            children: [
              TextSpan(
                text: text.substring(0, safeStart),
                style: Fv4rs.mwLabelStyle,
              ),
              TextSpan(
        text: text.substring(safeStart, safeEnd),
        style: Fv4rs.highlightTextStyle,
      ),

      // anchor for scrolling
      WidgetSpan(
        child: SizedBox(
          key: highlightKey,
          width: 0,
          height: 0,
        ),
      ),

      TextSpan(
        text: text.substring(safeEnd),
        style: Fv4rs.mwLabelStyle,
      ),
    ],
  ),
        ),
);
    },
  );
}}

class Alerts extends StatelessWidget {
  final TTSInterface tts;
  

 const Alerts ({super.key, required this.tts});
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder ( 
       builder: (context, constraints) { 

      return Column (
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (Sv4rs.alertCount >= 1)
          Expanded(
            child: AlertStyle(
                  imagePath: 'assets/interface_icons/interface_icons/iAlertC.png',
                  invertColors: true,
                  onPressed: () async {
                    if (Sv4rs.speakInterfaceButtonsOnSelect) {
                      await Future.delayed(const Duration(milliseconds: 100));
                      await V4rs.speakOnSelect('first alert', V4rs.selectedLanguage.value, tts);
                      await Future.delayed(const Duration(milliseconds: 100));
                      await V4rs.universalSpeakWithSSRestore(Sv4rs.firstAlert, V4rs.selectedLanguage.toString(), tts);
                      } else {
                      await V4rs.universalSpeak(Sv4rs.firstAlert, V4rs.selectedLanguage.toString(), tts);
                      }
                  },
                ),
          ),
          if (Sv4rs.alertCount >= 2)
          Expanded(
            child: AlertStyle(
                  imagePath: 'assets/interface_icons/interface_icons/iAlertS.png',
                  invertColors: true,
                  onPressed: () async {
                    if (Sv4rs.speakInterfaceButtonsOnSelect) {
                      await V4rs.speakOnSelect('second alert', V4rs.selectedLanguage.value, tts);
                      await V4rs.universalSpeakWithSSRestore(Sv4rs.secondAlert, V4rs.selectedLanguage.toString(), tts);
                      } else {
                    await V4rs.universalSpeak(Sv4rs.secondAlert, V4rs.selectedLanguage.toString(), tts);
                      }
                  },
                ),
          ),
          if (Sv4rs.alertCount >= 3)
          Expanded(
            child: AlertStyle(
                  imagePath: 'assets/interface_icons/interface_icons/iAlertT.png',
                  invertColors: true,
                  onPressed: () async {
                    if (Sv4rs.speakInterfaceButtonsOnSelect) {
                        await V4rs.speakOnSelect('third alert', V4rs.selectedLanguage.value, tts);
                        await V4rs.universalSpeakWithSSRestore(Sv4rs.thirdAlert, V4rs.selectedLanguage.toString(), tts);
                      } else {
                     await V4rs.universalSpeak(Sv4rs.thirdAlert, V4rs.selectedLanguage.toString(), tts);
                      }
                  },
                ),
          ),
          ],
        );
      },
    );
  }
}

class RightOfMessageWindow extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final TTSInterface synth;

  const RightOfMessageWindow({
    super.key, 
    required this.controller, 
    required this.onUndo,
    required this.onRedo,
    required this.synth,
    });

  @override
  State<RightOfMessageWindow> createState() => _RightOfMessageWindowState();
}

class _RightOfMessageWindowState extends State<RightOfMessageWindow> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder ( 
       builder: (context, constraints) { 

        var totalHeight = constraints.maxHeight;
        var totalWidth = constraints.maxWidth;

      return Column (
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          //undo, play, pause, redo
          Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: 
          Row( 
           children: [
              SizedBox(
                height: totalHeight * 0.35,
                width: totalWidth * 0.33,
                child: Padding (
                  padding: const EdgeInsets.all(3.0),
                    child: ButtonStyle1(
                      imagePath: 'assets/interface_icons/interface_icons/iUndo.png',
                      onPressed: () {
                        if (Sv4rs.speakInterfaceButtonsOnSelect) {
                          V4rs.speakOnSelect('undo', V4rs.selectedLanguage.value, widget.synth);
                          }
                        widget.onUndo();
                      },
                    ),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: widget.synth.isSpeaking,
                  builder: (context, isSpeaking, _) {
                  
                    return isSpeaking
                          ? SizedBox(
                            height: totalHeight * 0.35,
                            width: totalWidth * 0.33,
                            child:  Padding (
                            padding: const EdgeInsets.all(3.0),
                            child: ButtonStyle1(
                              imagePath: 'assets/interface_icons/interface_icons/iPause.png',
                              onPressed: () 
                                async {
                                  if (Sv4rs.speakInterfaceButtonsOnSelect) {
                                    await widget.synth.stop();
                                    V4rs.speakOnSelect('pause', V4rs.selectedLanguage.value, widget.synth);
                                    } else {
                                      await widget.synth.pause();
                                      V4rs.wasPaused.value = true;
                                    }
                                },
                              ),
                            ),
                          ) 
                        : SizedBox(
                            height: totalHeight * 0.35,
                            width: totalWidth * 0.33,
                            child:  Padding (
                            padding: const EdgeInsets.all(3.0),
                            child: ButtonStyle1(
                              imagePath: 'assets/interface_icons/interface_icons/iPlay.png',
                              onPressed: () 
                                async {
                                  if (Sv4rs.speakInterfaceButtonsOnSelect) {
                                    await V4rs.speakOnSelect('play', V4rs.selectedLanguage.value, widget.synth);
                                    await V4rs.mwSpeakWithSSRestore( V4rs.message.value, V4rs.selectedLanguage.value, widget.synth);
                                    } else {
                                  await V4rs.messageWindowSpeak( V4rs.message.value, V4rs.selectedLanguage.value, widget.synth);
                                    }
                                },
                              ),
                            ),
                          );
                        },
                      ),
        
              SizedBox(
                height: totalHeight * 0.35,
                width: totalWidth * 0.33,
                child:  Padding (
                padding: const EdgeInsets.all(3.0),
                child: ButtonStyle1(
                  imagePath: 'assets/interface_icons/interface_icons/iRe-do.png',
                  onPressed: () {
                    if (Sv4rs.speakInterfaceButtonsOnSelect) {
                          V4rs.speakOnSelect('redo', V4rs.selectedLanguage.value, widget.synth);
                          }
                    widget.onRedo();
                  },
                ),
                ),
              ),
            ],
          ),
          ),
            //rewind, search, and clear button 
            Row( 
              children: [
                SizedBox(
                  height: totalHeight * 0.35,
                  width: totalWidth * 0.3,
                  child: Padding (
                      padding: const EdgeInsets.all(3.0),
                      child: ButtonStyle1(
                        imagePath: 'assets/interface_icons/interface_icons/iRewind.png',
                        onPressed: () async {
                         
                            await widget.synth.stop();
                          
                          if (Sv4rs.speakInterfaceButtonsOnSelect) {
                            await V4rs.speakOnSelect('rewind', V4rs.selectedLanguage.value, widget.synth);
                            await V4rs.mwSpeakWithSSRestore( V4rs.message.value, V4rs.selectedLanguage.value, widget.synth);
                          } else {
                          await V4rs.messageWindowSpeak( V4rs.message.value, V4rs.selectedLanguage.value, widget.synth);
                          }
                        },
                      ),
                      ),
                      ),
                SizedBox(
                  height: totalHeight * 0.35,
                  width: totalWidth * 0.3,
                  child: Padding (
                    padding: const EdgeInsets.all(3.0),
                    child: ButtonStyle1(
                      imagePath: 'assets/interface_icons/interface_icons/iSearch.png',
                      onPressed: () { setState((){
                        if (Sv4rs.speakInterfaceButtonsOnSelect) {
                          V4rs.speakOnSelect('search', V4rs.selectedLanguage.value, widget.synth);
                          }
                          SeV4rs.openSearch.value = true;
                          SeV4rs.findAndPick.value = false;
                        // put action here
                      });
                      },
                    ),
                    ),
               ),
               SizedBox(
                height: totalHeight * 0.35,
                width: totalWidth * 0.4,
                child: Padding (
                  padding: const EdgeInsets.all(2.0),
                  child: ButtonStyle1(
                    imagePath: 'assets/interface_icons/interface_icons/iClear.png',
                    onPressed: () {
                      if (Sv4rs.speakInterfaceButtonsOnSelect) {
                          V4rs.speakOnSelect('clear', V4rs.selectedLanguage.value, widget.synth);
                          }
                      widget.controller.clear();
                    },
                  ),
                ),
               ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class SearchDisplay extends StatefulWidget {
  final Root? root;

  const SearchDisplay({
    super.key, 
    required this.root,
    });

  @override
  State<SearchDisplay> createState() => _SearchDisplay();
}

class _SearchDisplay extends State<SearchDisplay> {

  int searchIndex = 0;
  List<BoardObjects?> foundObjects = [];
  List<Widget> indexedChildren = [];
  

  void updateFoundObjects(List<BoardObjects?> objects) {
    foundObjects = objects;
    indexedChildren = foundObjects.map((obj) {
      return (obj != null) ? SizedBox.expand(child: PreveiwButton(obj: obj)) : SizedBox();
    }).toList();
    searchIndex = 0;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return 
          ValueListenableBuilder<bool>(valueListenable: SeV4rs.findAndPick, builder: (context, findAndPick, _) {
            return (findAndPick) 
              ? pickButton()
              : startSearch();
           }
          );
  }

  Widget startSearch(){
    return LayoutBuilder ( 
       builder: (context, constraints) { 

        var totalHeight = constraints.maxHeight;
        var totalWidth = constraints.maxWidth;

      return Column (
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          //search box
          Padding(
            padding: EdgeInsets.fromLTRB(3, 3, 3, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Cv4rs.themeColor4,
                borderRadius: BorderRadius.circular(10)
                ),
              child: SizedBox(
                height: totalHeight * 0.35,
                child: TextField(
                  style: Fv4rs.mwLabelStyle,
                  onChanged: (value){
                    SeV4rs.searchFor = value;
                    },
                  decoration: InputDecoration(
                    hintStyle: Fv4rs.mwLabelStyle.copyWith(
                      color: Cv4rs.themeColor2
                    ),
                    hintText: 'Search:',
                  ),
                )
              )
            ),
          ),
          
          //close and check 
          Row( 
            children: [
              SizedBox(
                height: totalHeight * 0.35,
                width: totalWidth * 0.3,
                child: Padding (
                    padding: const EdgeInsets.all(3.0),
                    child: ButtonStyle1(
                      imagePath: 'assets/interface_icons/interface_icons/iClose.png',
                      onPressed: () {
                        setState(() {
                          SeV4rs.openSearch.value = false;
                          SeV4rs.searchFor = '';
                        });
                      },
                    ),
                    ),
                    ),
              SizedBox(
                height: totalHeight * 0.35,
                width: totalWidth * 0.3
              ),
              SizedBox(
              height: totalHeight * 0.35,
              width: totalWidth * 0.4,
              child: Padding (
                padding: const EdgeInsets.all(2.0),
                child: ButtonStyle1(
                  imagePath: 'assets/interface_icons/interface_icons/iCheck.png',
                  onPressed: () { 
                    setState(() {
                      if (widget.root != null) {
                        foundObjects = SeV4rs.objectsReturned(
                          widget.root!, 
                          SeV4rs.findAllUUIDsForWord(widget.root!.boards, SeV4rs.searchFor)
                        );
                        updateFoundObjects(foundObjects);
                        SeV4rs.findAndPick.value = true;
                      }
                    });
                  },
                ),
              ),
              ),
            ],
          ),
          ],
        );
      },
    );
  }

  Widget pickButton(){
    bool start = true;
    bool end = false;

    void next() {
      setState(() {
        if (searchIndex < foundObjects.length - 1) {
          searchIndex++;
        } 
      });
    }

    void previous() {
      setState(() {
        if (searchIndex > 0) {
          searchIndex = 0;
        }
      });
    }

    void move(){
      setState((){
        if (searchIndex == 0){
          start = true;
          end = false;
        } else if (searchIndex == foundObjects.length - 1) {
          end = true;
          start = false;
        }

        if (start){
          next();
        } else if (end) {
          previous();
        }
      });
    }

    return LayoutBuilder ( 
       builder: (context, constraints) { 

        var totalHeight = constraints.maxHeight;
        var totalWidth = constraints.maxWidth;

      return Column (
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          //search box
           Padding(padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
            child: 
          Row( 
           children: [
              SizedBox(
                height: totalHeight * 0.35,
                width: totalWidth * 0.66,
                child: (widget.root != null) 
                 ? IndexedStack(
                      index: searchIndex,
                      children: indexedChildren,
                    )
                  : SizedBox(),
                ),
              SizedBox(
                height: totalHeight * 0.35,
                width: totalWidth * 0.33,
                child:  Padding (
                padding: const EdgeInsets.all(3.0),
                child: ButtonStyle1(
                  turn: 270,
                  imagePath: 'assets/interface_icons/interface_icons/iArrow.png',
                  onPressed: move,
                ),
                ),
              ),
            ],
          ),
          ),

          //close and check 
          Row( 
            children: [
              SizedBox(
                height: totalHeight * 0.35,
                width: totalWidth * 0.3,
                child: Padding (
                    padding: const EdgeInsets.all(3.0),
                    child: ButtonStyle1(
                      imagePath: 'assets/interface_icons/interface_icons/iClose.png',
                      onPressed: () {
                        setState(() {
                          SeV4rs.openSearch.value = false;
                          SeV4rs.findAndPick.value = false;
                          SeV4rs.searchFor = '';
                          V4rs.searchPathUUIDS.value = [];
                        });
                      },
                    ),
                    ),
                    ),
              SizedBox(
                height: totalHeight * 0.35,
                width: totalWidth * 0.3
              ),
              SizedBox(
              height: totalHeight * 0.35,
              width: totalWidth * 0.4,
              child: Padding (
                padding: const EdgeInsets.all(2.0),
                child: ButtonStyle1(
                  imagePath: 'assets/interface_icons/interface_icons/iCheck.png',
                  onPressed: () { 
                    setState(() {
                      SeV4rs.findThis = foundObjects[searchIndex];
                      if (widget.root != null && SeV4rs.findThis != null && V4rs.thisBoard != null){
                        SeV4rs.startBoard.add(V4rs.thisBoard!);
                        SeV4rs.startBoard.addAll(V4rs.thisBoard!.content);
                        
                        if (SeV4rs.startBoard.isNotEmpty) {
                         V4rs.searchPathUUIDS.value = 
                          SeV4rs.findWord(widget.root!, SeV4rs.findThis!.id, V4rs.thisBoard!.content).keys.toList();
                         if (!V4rs.searchPathUUIDS.value.contains(SeV4rs.findThis!.id)){
                          V4rs.searchPathUUIDS.value.add(SeV4rs.findThis!.id);
                         }
                        }
                      }
                    });
                  },
                ),
              ),
              ),
            ],
          ),
          ],
        );
      },
    );
  }

}




