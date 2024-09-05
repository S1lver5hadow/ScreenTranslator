import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';

class TranslateHead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.rectangle,
        ),
        // This button is used to signal that the user wants to translate
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: BeveledRectangleBorder(),
          ),
          onPressed: () async {
            /* Sends a default message to the home server to tell it to choose
            an image */
            SendPort? homePort = IsolateNameServer.lookupPortByName("Home");
            homePort?.send("Hello");
          },
          child: Center(child: const Icon(Icons.translate)),
        ),
      )
    );
  }
}