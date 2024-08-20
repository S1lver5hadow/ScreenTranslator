import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recievePort = ReceivePort();
  SendPort? homePort;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    if (homePort != null) {
      return;
    }
    IsolateNameServer.registerPortWithName(
      _recievePort.sendPort, 
      "Home"
    );

    _recievePort.listen((message) {
      pickImage(picker).then((xfilepick) {
        if (xfilepick != null) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text("Translated Image"),
              content: Image.file(File(xfilepick.path))
            ),
          );
        } else {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text("Image Error"),
              content: const Text(
                "Error: Failed to select image"
              )
            ),
          );
        }
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () async {
                  final bool perm = await FlutterOverlayWindow.isPermissionGranted();
                  if (!perm) {
                    final bool? request = await FlutterOverlayWindow.requestPermission();
                    if ((request == null || request == false) && context.mounted) {
                      showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text("Missing Permission"),
                          content: const Text(
                            "Error: Missing permissions to run an overlay"
                          )
                        )
                      );
                    }
                  } else {
                    if (await FlutterOverlayWindow.isActive()) {
                      FlutterOverlayWindow.closeOverlay();
                    } else {
                      await FlutterOverlayWindow.showOverlay(
                        enableDrag: true,
                        overlayTitle: "Translate",
                        overlayContent: "TranslateCont",
                        alignment: OverlayAlignment.centerRight,
                        flag: OverlayFlag.defaultFlag,
                        visibility: NotificationVisibility.visibilityPublic,
                        positionGravity: PositionGravity.auto,
                        height: 1000,
                        width: 1000,
                        startPosition: const OverlayPosition(0, -259),
                      );
                    }
                  }
                },
                child: const Text("Start"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<XFile?> pickImage(ImagePicker picker) async {
  return await picker.pickImage(source: ImageSource.gallery);
}