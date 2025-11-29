import 'package:flutter/material.dart';
import 'package:flutterkeysaac/Variables/colors/color_variables.dart';
import 'package:flutterkeysaac/Variables/editing/save_indicator.dart';
import 'package:flutterkeysaac/Variables/settings/settings_variables.dart';
import 'package:flutterkeysaac/Variables/export_variables.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:typed_data';

//speak on select shortcut 
Future<void> showOptionsPopupForSpeakOnSelect(BuildContext context, {
  required List<String> optionLabels,
  required List<bool> optionValues,
  required void Function(List<bool> updatedValues) onDone,
}) async {
  // Local mutable copy so the checkboxes can toggle
  List<bool> tempValues = List.from(optionValues);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // expands if need
    backgroundColor: Cv4rs.themeColor4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Speak on Select Options",
                  style: Sv4rs.settingslabelStyle,
                ),
                const SizedBox(height: 12),

                // Checkbox list
                ...List.generate(optionLabels.length, (i) {
                  return CheckboxListTile(
                    title: Text(optionLabels[i], style: Sv4rs.settingslabelStyle,),
                    value: tempValues[i],
                    onChanged: (val) {
                      setState(() {
                        tempValues[i] = val ?? false;
                      });
                    },
                  );
                }),

                const SizedBox(height: 16),

                // Done button
                Row(children: [
                Expanded(child: 
                ElevatedButton(
                   style: ElevatedButton.styleFrom(
                      backgroundColor: Cv4rs.themeColor3,
                      elevation: 2, 
                      shape: RoundedRectangleBorder( 
                        borderRadius: BorderRadius.circular(10), 
                      ),
                      shadowColor: Cv4rs.themeColor4,
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5), 
                    ),
                  onPressed: () {
                    Navigator.pop(context);
                    onDone(tempValues); 
                  },
                  child: Text("Done", style: Sv4rs.settingslabelStyle,),
                ),
                ),
                ]),
              ],
            ),
          );
        },
      );
    },
  );
}

//print pop up
Future<void> showPrintPop(
  BuildContext context,
  Future<List<Uint8List?>> Function() captureAllForPrint,
) async { 
  await showDialog(
  context: context,
  builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SimpleDialog(
    title: Text("Print Options"),
    children: [
      Row(
        children: [
          Text('Include Message Row:'),
          Spacer(),
          DropdownButton<int>(
            value: ExV4rs.includeMessageRow,
            items: [
              DropdownMenuItem(value: 1, child: Text("Message Row")),
              DropdownMenuItem(value: 2, child: Text("Spacer")),
              DropdownMenuItem(value: 3, child: Text("None")),
            ],
            onChanged: (value) {
              setState(() {
                if (value!= null){
                  ExV4rs.includeMessageRow = value;
                }
              });
            },
          ),
        ]
      ),
      Row(
        children: [
          Text('Include Navigation Row:'),
          Spacer(),
          DropdownButton<int>(
            value: ExV4rs.includeNavRow,
            items: [
              DropdownMenuItem(value: 1, child: Text("Navigation Row")),
              DropdownMenuItem(value: 2, child: Text("Spacer")),
              DropdownMenuItem(value: 3, child: Text("None")),
            ],
            onChanged: (value) {
              setState(() {
                if (value!= null){
                  ExV4rs.includeNavRow = value;
                }
              });
            },
          ),
        ]
      ),
      Row(
        children: [
          Text('Include Grammar Row:'),
          Spacer(),
          DropdownButton<int>(
            value: ExV4rs.includeGrammerRow,
            items: [
              DropdownMenuItem(value: 1, child: Text("Grammar Row")),
              DropdownMenuItem(value: 2, child: Text("Spacer")),
              DropdownMenuItem(value: 3, child: Text("None")),
            ],
            onChanged: (value) {
              setState(() {
                if (value!= null){
                  ExV4rs.includeGrammerRow = value;
                }
              });
            },
          ),
        ]
      ),
      Row(
        children: [
          Text('Include Indicator Row:'),
          Spacer(),
          Switch(
            value: ExV4rs.includeIndicatorRow, 
            onChanged: (value) {
              setState(() {
                ExV4rs.includeIndicatorRow = value;
              });
            }
          ),
        ]
      ),
      if (ExV4rs.includeIndicatorRow)
       Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 0, 15),
        child: Row(
          children: [
            Text('1st Indicator Message:'),
            Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 20, 0), 
              child: TextField(
                onChanged: (value) {
                  ExV4rs.indicator1 = value;
                  ExV4rs.saveIndicator1(value);
                },
                decoration: InputDecoration(
                  hintText: ExV4rs.indicator1,
                ),
              ),
            ),
            ),
          ],
        ),
      ),
      if (ExV4rs.includeIndicatorRow)
      Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 0, 15),
        child: Row(
          children: [
            Text('2nd Indicator Message:'),
            Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 20, 0), 
              child: TextField(
                onChanged: (value) {
                  ExV4rs.indicator2 = value;
                  ExV4rs.saveIndicator2(value);
                },
                decoration: InputDecoration(
                  hintText: ExV4rs.indicator2,
                ),
              ),
            ),
            ),
          ],
        ),
      ),
      if (ExV4rs.includeIndicatorRow)
      Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 0, 15),
        child: Row(
          children: [
            Text('3rd Indicator Message:'),
            Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 20, 0), 
              child: TextField(
                onChanged: (value) {
                  ExV4rs.indicator3 = value;
                  ExV4rs.saveIndicator3(value);
                },
                decoration: InputDecoration(
                  hintText: ExV4rs.indicator3,
                ),
              ),
              ),
            ),
          ],
        ),
      ),
      // Done button
      Row(children: [
      Expanded(child: 
      ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Cv4rs.themeColor3,
            elevation: 2, 
            shape: RoundedRectangleBorder( 
              borderRadius: BorderRadius.circular(10), 
            ),
            shadowColor: Cv4rs.themeColor4,
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5), 
          ),
        onPressed: () async { if (ExV4rs.loadingPrint.value){} else {
            final pages =
                await captureAllForPrint();

            if (pages.isEmpty) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Failed to generate print image")),
              );
              return;
            }

            // Show print dialog
            await Printing.layoutPdf(
              onLayout: (PdfPageFormat format) async {
                final doc = pw.Document();

                for (final pageBytes in pages){
                  if (pageBytes != null) {
                final image = pw.MemoryImage(pageBytes);

                doc.addPage(
                  pw.Page(
                    pageFormat: format,
                    build: (pw.Context ctx) {
                      return pw.Center(
                        child: pw.FittedBox(
                          fit: pw.BoxFit.contain,
                          child: pw.Image(image),
                        ),
                      );
                    },
                  ),
                );
                }
                }
                return doc.save();
              },
            );
            if (!context.mounted) return;
            Navigator.of(context).pop();
          }
          },
        child: Row(children: [
          Text("Done", style: Sv4rs.settingslabelStyle,),
          LoadingIndicator(notifier: ExV4rs.loadingPrint),
        ]),
      ),
      ),
      ]),
    ],
  );
        });}
);
}

