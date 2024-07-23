import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Moon App',
        theme: ThemeData(
          useMaterial3: false,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var uids = <String>[]; // List to store UIDs

  void addUid(String uid) {
    if (!uids.contains(uid)){
      uids.add(uid);
    }
    notifyListeners();
  }

  void clearUids() {
    uids.clear();
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = UIDsPage(); // Add UIDsPage as a case
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.nfc),
                    label: Text('UIDs'), // Add NFC logo for UIDsPage
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

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
