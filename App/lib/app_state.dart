import 'package:flutter/material.dart';

class MyAppState extends ChangeNotifier {
  var uids = <String>[]; // List to store UIDs

  void addUid(String uid) {
    if (!uids.contains(uid)) {
      uids.add(uid);
    }
    notifyListeners();
  }

  void clearUids() {
    uids.clear();
    notifyListeners();
  }
}
