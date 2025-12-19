import 'package:flutter/material.dart';
import 'package:flutterkeysaac/Variables/colors/color_variables.dart';
import 'package:flutterkeysaac/Variables/settings/settings_variables.dart';
import 'package:flutterkeysaac/Variables/variables.dart';
import 'package:flutterkeysaac/Variables/assorted_ui/ui_shortcuts.dart';
import 'package:flutterkeysaac/Variables/system_tts/tts_interface.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;


class ColorPickerWithHex extends StatefulWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerWithHex({
    super.key,
    required this.label,
    required this.color,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerWithHex> createState() => _ColorPickerWithHex();
}

class _ColorPickerWithHex extends State<ColorPickerWithHex> {
  late String _label;
  late Color _color;
  late ValueChanged<Color> _onColorChanged;

  @override
  void initState() {
    super.initState();
    _color = widget.color;
    _label = widget.label;
    _onColorChanged = widget.onColorChanged;
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(
        children: [
          Text(_label, style: Sv4rs.settingslabelStyle,),
          const Spacer(),
          CircleAvatar(
            backgroundColor: Cv4rs.themeColor3,
            radius: 20,
            child: Icon(Icons.circle, color: _color, size: 40, shadows: [
              Shadow(
                color: Cv4rs.themeColor4,
                blurRadius: 4,
              ),
            ],),
          ),
        ]
      ),
      collapsedBackgroundColor: Cv4rs.themeColor4,
      backgroundColor: Cv4rs.themeColor4,
      childrenPadding: EdgeInsets.symmetric(horizontal: 20),
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 40, vertical: 20),
          child: HexCodeInput(
            startValue: _color.toHexString(),
            textStyle: Sv4rs.settingslabelStyle,
            hintTextStyle: TextStyle(color: Cv4rs.themeColor3, fontSize: 16),
            onColorChanged: (color) {
              setState(() {
                _color = color;
                _onColorChanged(color);
              });
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(40, 0, 10, 10),
          child: ColorPicker(
            pickerColor: _color,
            enableAlpha: true,
            displayThumbColor: false,
            labelTypes: ColorLabelType.values,
            onColorChanged: (color) {
              setState(() {
                _color = color;
                widget.onColorChanged(color);
              });
            },
          ),
        ),
      ],
    );
  }
}

class HexCodeInput extends StatefulWidget {
  final String startValue; 
  final TextStyle textStyle;
  final TextStyle hintTextStyle;
  final Function(Color color)? onColorChanged; 

  const HexCodeInput({
    super.key,
    this.startValue = '#FFFFFF',
    this.textStyle = const TextStyle(color: Colors.black, fontSize: 16),
    this.hintTextStyle = const TextStyle(color: Colors.blueGrey, fontSize: 16),
    this.onColorChanged,
  });

  @override
  State<HexCodeInput> createState() => _HexCodeInputState();
}

class _HexCodeInputState extends State<HexCodeInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _updateColor(_controller.text);
  }

  void _updateColor(String hex) {
    try {
      Color color = _hexToColor(hex);

      if (widget.onColorChanged != null) {
        widget.onColorChanged!(color);
      }
    } catch (_) {
      //color is invalid
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Row (
      children: [
        Padding(
          padding: EdgeInsetsGeometry.all(10),
          child: Text('Input hex code:', style: widget.textStyle,),
        ),
        Expanded(child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: '#${widget.startValue.substring(2)}',
            hintStyle: widget.hintTextStyle
          ),
          onChanged: _updateColor,
        ))
      ],
    );
  }
}

class HexCodeInput2 extends StatefulWidget {
  final String startValue; 
  final TextStyle textStyle;
  final TextStyle hintTextStyle;
  final Function(Color color)? onColorChanged; 

  const HexCodeInput2({
    super.key,
    this.startValue = '#FFFFFF',
    this.textStyle = const TextStyle(color: Colors.black, fontSize: 16),
    this.hintTextStyle = const TextStyle(color: Colors.blueGrey, fontSize: 16),
    this.onColorChanged,
  });

  @override
  State<HexCodeInput2> createState() => _HexCodeInput2State();
}

class _HexCodeInput2State extends State<HexCodeInput2> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _updateColor(_controller.text);
  }

  void _updateColor(String hex) {
    try {
      Color color = _hexToColor(hex);

      if (widget.onColorChanged != null) {
        widget.onColorChanged!(color);
      }
    } catch (_) {
      //color is invalid
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Column (
      children: [
        Padding(
          padding: EdgeInsetsGeometry.fromLTRB(10, 10, 10, 0),
          child: Text('Input hex code:', style: widget.textStyle,),
        ),
        TextField(
          textAlign: TextAlign.center,
          controller: _controller,
          decoration: InputDecoration(
            hintText: '#${widget.startValue.substring(2)}',
            hintStyle: widget.hintTextStyle
          ),
          onChanged: _updateColor,
        )
      ],
    );
  }
}


class SymbolColorCustomizer extends StatefulWidget {
  final bool invert;
  final Color overlay;
  final double saturation; 
  final double contrast;
  final ValueChanged<bool> onInvertChanged;
  final ValueChanged<Color> onOverlayChanged;
  final ValueChanged<double> onSaturationChanged;
  final ValueChanged<double> onContrastChanged;
  final TTSInterface tts;
  final Map<String, sherpa_onnx.OfflineTts?>? speakSelectSherpaOnnxSynth;
  final Future<void> Function() initForSS;
  final AudioPlayer playerForSS;

  const SymbolColorCustomizer({
    super.key,
    required this.invert,
    required this.overlay,
    required this.saturation,
    required this.contrast,
    required this.onContrastChanged,
    required this.onInvertChanged,
    required this.onOverlayChanged,
    required this.onSaturationChanged,
    required this.tts,
    required this.speakSelectSherpaOnnxSynth,
    required this.initForSS,
    required this.playerForSS,
  });

  @override
  State<SymbolColorCustomizer> createState() => _SymbolColorCustomizer();
}

class _SymbolColorCustomizer extends State<SymbolColorCustomizer> {
  late bool _invert;
  late Color _overlay;
  late double _saturation; 
  late double _contrast;

  late ValueChanged<bool> _onInvertChanged;
  late ValueChanged<Color> _onOverlayChanged;
  late ValueChanged<double> _onSaturationChanged;
  late ValueChanged<double> _onContrastChanged;
  late TTSInterface _tts;

  Widget image = Image.asset(
         'assets/interface_icons/interface_icons/iSymbol_sample.png',
          fit: BoxFit.fitWidth,
        );

  @override
  void initState() {
    super.initState();
    _invert = widget.invert;
    _overlay = widget.overlay;
    _saturation = widget.saturation;
    _contrast = widget.contrast;
    _onInvertChanged = widget.onInvertChanged;
    _onOverlayChanged = widget.onOverlayChanged; 
    _onSaturationChanged = widget.onSaturationChanged;
    _onContrastChanged = widget.onContrastChanged;
    _tts = widget.tts;
  }


  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Row(children: [
        Flexible(flex: 20, child: 
        Row(children: [
        Text('Symbol Colors:',  style: Sv4rs.settingslabelStyle,), 
        Spacer(),
        ]
        )
        ),
        Flexible(flex: 1, child:
        ImageStyle1(
                image: image,
                defaultSymbolColorOverlay: _overlay,
                defaultSymbolContrast: _contrast,
                defaultSymbolInvert: _invert,
                defaultSymbolSaturation: _saturation,
                overlayColor: _overlay,
                symbolContrast: _contrast,
                symbolSaturation: _saturation,
                invertSymbolColors: _invert,
                matchOverlayColor: true,
                matchSymbolContrast: true,
                matchSymbolInvert: true,
                matchSymbolSaturation: true,
            ),
        )
        ]),
      collapsedBackgroundColor: Cv4rs.themeColor4,
      backgroundColor: Cv4rs.themeColor4,
      childrenPadding: EdgeInsets.symmetric(horizontal: 20),
      onExpansionChanged: (bool expanded) {  
        if (Sv4rs.speakInterfaceButtonsOnSelect) {
            V4rs.speakOnSelect(
              'symbol colors', 
              V4rs.selectedLanguage.value, 
              _tts,
              widget.speakSelectSherpaOnnxSynth,
              widget.initForSS,
              widget.playerForSS,
            );
          }},
      children: [

        // invert
        Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 20), child:
        Row(
          children: [
            Text(
              'Invert Colors:', style: Sv4rs.settingslabelStyle,),

           
            Switch(
              value: _invert,
              onChanged: (val) {
                setState(() => _invert = val);
                _onInvertChanged(val);
              },
            ),
          ],
        ),
        ),

        // Symbol Saturation
         Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 20), child:
        Row(
          children: [
            Text('Symbol Saturation:  $_saturation', style: Sv4rs.settingslabelStyle,),
            Expanded(
              child: Slider(
                value: _saturation,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                activeColor: Cv4rs.themeColor1,
                inactiveColor: Cv4rs.themeColor3,
                thumbColor: Cv4rs.themeColor1,
                onChanged: (val) {
                  setState(() => _saturation= val);
                  _onSaturationChanged(val);
                },
              ),
            ),
          ],
        ),
        ),

        //symbol contrast
        Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 20), child:
        Row(
          children: [
            Text('Symbol Contrast:  $_contrast', style: Sv4rs.settingslabelStyle,),
            Expanded(
              child: Slider(
                value: _contrast,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                activeColor: Cv4rs.themeColor1,
                inactiveColor: Cv4rs.themeColor3,
                thumbColor: Cv4rs.themeColor1,
                onChanged: (val) {
                  setState(() => _contrast= val);
                  _onContrastChanged(val);
                },
              ),
            ),
          ],
        ),
        ),
        //overlay
         ExpansionTile(
            title: Row(
              children: [
                Text('Color Overlay:', style: Sv4rs.settingslabelStyle,),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: Cv4rs.themeColor3,
                  radius: 20,
                  child: Icon(Icons.circle, color: _overlay, size: 40, shadows: [
                    Shadow(
                      color: Cv4rs.themeColor4,
                      blurRadius: 4,
                    ),
                  ],),
                ),
              ]
            ),
            children: [
              //hexcode input
              Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 40, vertical: 20),
                child: HexCodeInput(
                  startValue: _overlay.toHexString(),
                  textStyle: Sv4rs.settingslabelStyle,
                  hintTextStyle: TextStyle(color: Cv4rs.themeColor3, fontSize: 16),
                  onColorChanged:  (color) { setState(() {
                    _overlay = color;
                    _onOverlayChanged(color);
                   });
                   }
                ),
              ),
              //color picker
              Padding(
                padding: EdgeInsets.fromLTRB(40, 0, 10, 10),
                child: ColorPicker(
                  pickerColor: _overlay, 
                  enableAlpha: true,
                  displayThumbColor: false,
                  labelTypes: ColorLabelType.values,
                  onColorChanged: (color) { setState(() {
                    _overlay = color;
                    _onOverlayChanged(color);
                   });
                   }
                ),
            ),
            ],
          ),
      ],
    );
  }
}

class SymbolColorCustomizer2 extends StatefulWidget {
  final bool specialLabel;
  final double width;
  final double height;
  final double additionalHeight;
  final Widget widgety;
  final bool invert;
  final Color overlay;
  final double saturation; 
  final double contrast;

  final bool matchInvert;
  final bool matchOverlay;
  final bool matchSaturation;
  final bool matchContrast;

  final ValueChanged<bool> onInvertChanged;
  final ValueChanged<Color> onOverlayChanged;
  final ValueChanged<double> onSaturationChanged;
  final ValueChanged<double> onContrastChanged;

  final ValueChanged<bool> onMatchInvertChanged;
  final ValueChanged<bool> onMatchOverlayChanged;
  final ValueChanged<bool> onMatchSaturationChanged;
  final ValueChanged<bool> onMatchContrastChanged;

  const SymbolColorCustomizer2({
    super.key,
    required this.height,
    required this.additionalHeight,
    required this.widgety,
    required this.width,
    required this.invert,
    required this.overlay,
    required this.saturation,
    required this.contrast,
    required this.matchInvert,
    required this.matchOverlay,
    required this.matchSaturation,
    required this.matchContrast,
    required this.onContrastChanged,
    required this.onInvertChanged,
    required this.onOverlayChanged,
    required this.onSaturationChanged,
    required this.onMatchContrastChanged,
    required this.onMatchInvertChanged,
    required this.onMatchOverlayChanged,
    required this.onMatchSaturationChanged,
    this.specialLabel = false,
  });

  @override
  State<SymbolColorCustomizer2> createState() => _SymbolColorCustomizer2();
}

class _SymbolColorCustomizer2 extends State<SymbolColorCustomizer2> {
  late double _width;
  late double _height;
  late Widget _widgety;
  late bool _invert;
  late Color _overlay;
  late double _saturation; 
  late double _contrast;

  late bool _matchInvert;
  late bool _matchOverlay;
  late bool _matchSaturation;
  late bool _matchContrast;

  late ValueChanged<bool> _onInvertChanged;
  late ValueChanged<Color> _onOverlayChanged;
  late ValueChanged<double> _onSaturationChanged;
  late ValueChanged<double> _onContrastChanged;

  late ValueChanged<bool> _onMatchInvertChanged;
  late ValueChanged<bool> _onMatchOverlayChanged;
  late ValueChanged<bool> _onMatchSaturationChanged;
  late ValueChanged<bool> _onMatchContrastChanged;

  Widget image = Image.asset(
         'assets/interface_icons/interface_icons/iSymbol_sample.png',
          fit: BoxFit.fitWidth,
        );

  @override
  void initState() {
    super.initState();
    _width = widget.width;
    _height = widget.height;
    _widgety = widget.widgety;

    _invert = widget.invert;
    _overlay = widget.overlay;
    _saturation = widget.saturation;
    _contrast = widget.contrast;
    
    _matchOverlay = widget.matchOverlay;
    _matchInvert = widget.matchInvert;
    _matchSaturation = widget.matchSaturation;
    _matchContrast = widget.matchContrast;

    _onInvertChanged = widget.onInvertChanged;
    _onOverlayChanged = widget.onOverlayChanged; 
    _onSaturationChanged = widget.onSaturationChanged;
    _onContrastChanged = widget.onContrastChanged;

    _onMatchInvertChanged = widget.onMatchInvertChanged;
    _onMatchOverlayChanged = widget.onMatchOverlayChanged; 
    _onMatchSaturationChanged = widget.onMatchSaturationChanged;
    _onMatchContrastChanged = widget.onMatchContrastChanged;
  }


  @override
  Widget build(BuildContext context) {
    return 
          Container(
            width: _width,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Cv4rs.themeColor4,
              borderRadius: BorderRadius.circular(10)
              ),
            child: Column(children: [ 

        if (widget.specialLabel) 
          Text("--Not all match--", style: Sv4rs.settingslabelStyle),

        // invert
        Row(
          children: [
            Expanded(child: 
            Text(
              'Match Invert:', 
              style: Sv4rs.settingslabelStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            ),
            Switch(
              value: _matchInvert,
              onChanged: (val) {
                setState(() => _matchInvert = val);
                _onMatchInvertChanged(val);
              },
            ),
          ],
        ),
        
       
        Row(
          children: [
            Expanded(child: 
            Text(
              'Invert Colors:', 
              style: Sv4rs.settingslabelStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch(
              value: _invert,
              onChanged: (val) {
                setState(() => _invert = val);
                _onInvertChanged(val);
              },
            ),
          ],
        ),
        

        // Symbol Saturation
      
        Row(
          children: [
            Expanded(child:
            Text(
              'Match Saturation:',
              style: Sv4rs.settingslabelStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch(
              value: _matchSaturation,
              onChanged: (val) {
                setState(() => _matchSaturation = val);
                _onMatchSaturationChanged(val);
              },
            ),
          ],
        ),
        
        
        Column(
          children: [
            Padding(padding: EdgeInsetsGeometry.fromLTRB(0, 10, 0, 0), child:
            Text('Symbol Saturation:  $_saturation', 
            style: Sv4rs.settingslabelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
              ),
            ),
              Slider(
                padding: EdgeInsets.fromLTRB(5, 5, 5, 10),
                value: _saturation,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                activeColor: Cv4rs.themeColor1,
                inactiveColor: Cv4rs.themeColor3,
                thumbColor: Cv4rs.themeColor1,
                onChanged: (val) {
                  setState(() => _saturation= val);
                  _onSaturationChanged(val);
                },
              ),
          ],
        ),
        

        //symbol contrast
       
        Row(
          children: [
            Expanded(child: 
            Text(
              'Match Contrast:', 
              style: Sv4rs.settingslabelStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              ),
            ),
            Switch(
              value: _matchContrast,
              onChanged: (val) {
                setState(() => _matchContrast = val);
                _onMatchContrastChanged(val);
              },
            ),
          ],
        ),
        
       
        Column(
          children: [
            Padding(padding: EdgeInsetsGeometry.fromLTRB(0, 10, 0, 0), child:
            Text('Symbol Contrast:  $_contrast', 
              style: Sv4rs.settingslabelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              ),
              ),
              Slider(
                padding: EdgeInsets.fromLTRB(5, 5, 5, 10),
                value: _contrast,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                activeColor: Cv4rs.themeColor1,
                inactiveColor: Cv4rs.themeColor3,
                thumbColor: Cv4rs.themeColor1,
                onChanged: (val) {
                  setState(() => _contrast= val);
                  _onContrastChanged(val);
                },
              
            ),
          ],
        ),
        
        //overlay
      
        Row(
          children: [
            Expanded(child:
            Text(
              'Match Overlay Color:', 
              style: Sv4rs.settingslabelStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              ),
              ),
            Switch(
              value: _matchOverlay,
              onChanged: (val) {
                setState(() => _matchOverlay = val);
                _onMatchOverlayChanged(val);
              },
            ),
          ],
        ),
        
         ExpansionTile(
          tilePadding: EdgeInsets.all(2),
          title: Row(
              children: [
                Expanded(child:
                Text('Overlay Color:', 
                  style: Sv4rs.settingslabelStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Cv4rs.themeColor3,
                  radius: 20,
                  child: Icon(Icons.circle, color: _overlay, size: 40, shadows: [
                    Shadow(
                      color: Cv4rs.themeColor4,
                      blurRadius: 4,
                    ),
                  ],),
                ),
              ]
            ),
          children: [
              //hexcode input
              Padding(padding: EdgeInsetsGeometry.fromLTRB(0, 0, 0, 10), child: 
               HexCodeInput2(
                  startValue: _overlay.toHexString(),
                  textStyle: Sv4rs.settingslabelStyle,
                  hintTextStyle: TextStyle(color: Cv4rs.themeColor3, fontSize: 16),
                  onColorChanged:  (color) { setState(() {
                    _overlay = color;
                    _onOverlayChanged(color);
                   });
                   }
                ),
              ),
              //color picker
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                    Text('Scroll horizontally here...', 
                      style: Sv4rs.settingsSecondaryLabelStyle,
                      ),
                  SizedBox(height: 30,),
                  ]),
                  GestureDetector(
                    onVerticalDragStart: (_) {},
                    onVerticalDragUpdate: (_) {},
                    onVerticalDragEnd: (_) {},
                    child:
                SizedBox(
                  height: _height,
                  child: 
               ColorPicker(
                  pickerColor: _overlay, 
                  enableAlpha: true,
                  displayThumbColor: false,
                  labelTypes: ColorLabelType.values,
                  onColorChanged: (color) { setState(() {
                    _overlay = color;
                    _onOverlayChanged(color);
                   });
                }
               ),
                  ),
                  ),
                ]),
                
              ),
            ],
          ),
      _widgety,
      ],
                        ),
    );
  }
}

