import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

class UIDsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (appState.uids.isEmpty)
          Center(
            child: Text('No UIDs yet.'),
          )
        else
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('UIDs of tapped NFC tags:'),
                ),
                for (var uid in appState.uids)
                  ListTile(
                    leading: Icon(Icons.nfc),
                    title: Text(uid),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () {
              appState.clearUids();
            },
            child: Text('Clear UIDs'),
          ),
        ),
      ],
    );
  }
}
