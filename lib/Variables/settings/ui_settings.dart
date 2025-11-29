import 'package:flutter/material.dart';
import 'package:flutterkeysaac/Variables/settings/settings_variables.dart';
import 'package:flutterkeysaac/Variables/tts/tts_interface.dart';
import 'package:flutterkeysaac/Variables/assorted_ui/ui_shortcuts.dart';
import 'package:flutterkeysaac/Variables/variables.dart';
import 'package:flutterkeysaac/Variables/editing/editor_variables.dart';
import 'package:flutterkeysaac/Models/json_model_nav_and_root.dart';
import 'package:flutterkeysaac/Variables/colors/color_variables.dart';

class TopRowForSettings extends StatefulWidget {
  final TTSInterface synth;
  final Root root;

  const TopRowForSettings({
    super.key, 
    required this.synth,
    required this.root,
    });

  @override
  State<TopRowForSettings> createState() => _TopRowForSettings();
}

class _TopRowForSettings extends State<TopRowForSettings> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return //back & edit
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 10, 20),
                  child: SizedBox(
                    height: 50,
                    width: 75,
                    child: ButtonStyle1(
                      imagePath: 'assets/interface_icons/interface_icons/iBack.png',
                      onPressed: () {
                          if (Sv4rs.speakInterfaceButtonsOnSelect) {
                          V4rs.speakOnSelect('back', V4rs.selectedLanguage.value, widget.synth);
                          }
                        V4rs.showSettings.value = false;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(5, 10, 5, 20),
                  child: SizedBox(
                    height: 50,
                    width: 60,
                    child: ButtonStyle1(
                      imagePath: 'assets/interface_icons/interface_icons/iEdit.png',
                      onPressed: () {
                          if (Sv4rs.speakInterfaceButtonsOnSelect) {
                          V4rs.speakOnSelect('edit', V4rs.selectedLanguage.value, widget.synth);
                          }
                          Ev4rs.updateJsonHistory(widget.root);
                          
                        V4rs.showSettings.value = false;
                        Ev4rs.showEditor.value = true;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(5, 10, 5, 20),
                  child: SizedBox(
                    height: 50,
                    width: 100,
                    child: ElevatedButton(onPressed: (){ setState(() {
                       V4rs.deleteLocalCopy();
                    });
                    }, 
                    child: Text('Reset JSON'))
                  ),
                ),
              ],
            );
  }
}


class OpenWelcomeScreen extends StatefulWidget {
  final TTSInterface synth;

  const OpenWelcomeScreen({
    super.key, 
    required this.synth,
    });

  @override
  State<OpenWelcomeScreen> createState() => _OpenWelcomeScreen();
}

class _OpenWelcomeScreen extends State<OpenWelcomeScreen> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            color: Cv4rs.themeColor4,
            child: TextButton(
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft
              ),
              child: Text('Open welcome screen', style: Sv4rs.settingslabelStyle),
              onPressed: ()  {
                  if (Sv4rs.speakInterfaceButtonsOnSelect) {
                          V4rs.speakOnSelect('open welcome screen', V4rs.selectedLanguage.value, widget.synth);
                        }
                setState(() {
                  V4rs.doOnboarding.value = true;
                  V4rs.setOnboardingCompleteStatus(true);
                });
              }, 
              ),
          ),
        ),
      ]
    );
  }
}

