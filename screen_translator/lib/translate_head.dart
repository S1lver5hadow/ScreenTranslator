import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';

class TranslateHead extends StatefulWidget {
  
  @override
  State<TranslateHead> createState() => _TranslateHeadState();
}

class _TranslateHeadState extends State<TranslateHead> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Color.fromRGBO(0, 0, 0, 0),
      child: OutlinedButton(
        onPressed: () async {
          SendPort? homePort;
          homePort = IsolateNameServer.lookupPortByName("Home");
          homePort?.send("Hello");
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.blue
        ),
        child: Text("Translate"),
      )
    );
  }
}