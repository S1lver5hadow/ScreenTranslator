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
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.rectangle,
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: BeveledRectangleBorder(),
          ),
          onPressed: () async {
            SendPort? homePort = IsolateNameServer.lookupPortByName("Home");
            homePort?.send("Hello");
          },
          child: Center(child: const Icon(Icons.translate)),
        ),
      )
    );
  }
}