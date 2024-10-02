import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'app_state.dart';

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {
              try {
                // Start polling for NFC tag
                NFCTag tag = await FlutterNfcKit.poll();

                // Retrieve detailed information about the tag
                String tagDetails = '''
                  UID: ${tag.id}
                  Standard: ${tag.standard}
                  ''';// Print the details of the NFC tag
                print(tagDetails); // Save UID to the app state
                appState.addUid(tag.id); // Display the details in a dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('NFC Tag Details'),
                      content: SingleChildScrollView(
                        child: Text(tagDetails),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                ).then((_) async {
                  // Ensure the NFC session is properly closed
                  await FlutterNfcKit.finish();
                });
              } catch (e) {
                print('Error reading NFC tag: $e');
                // Ensure the NFC session is properly closed in case of an error
                await FlutterNfcKit.finish();
              }
            },
            child: Text('Read NFC Tag'),
          ),
        ],
      ),
    );
  }
}
