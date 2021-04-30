import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Screen/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Illik'Track",
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
        cupertinoOverrideTheme: CupertinoThemeData(
          primaryContrastingColor: Colors.tealAccent[200],
          primaryColor: Colors.tealAccent[200],
        ),
        bottomSheetTheme: BottomSheetThemeData(
            shape: OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            modalElevation: 10),
      ),
      home: Home(),
    );
  }
}
