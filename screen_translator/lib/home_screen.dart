import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screen_translator/secret.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recievePort = ReceivePort();
  SendPort? homePort;
  final picker = ImagePicker();
  late OpenAI openAI;
  String translateTo = "English";
  String translateFailure = "FAILED TO GET IMAGE";

  @override
  void initState() {
    super.initState();

    openAI = OpenAI.instance.build(
    token: token,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 20),
      connectTimeout: const Duration(seconds: 20)),
    enableLog: true,
  );

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
          print(xfilepick.path);
          translateImage(File(xfilepick.path)).then((url) {
            if (url == translateFailure) {
              showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text("Failed to translate"),
                  content: const Text("Error: Failed to connect to translation servers. Please try again.")
                )
              );
            } else {
              showDialog(
                barrierDismissible: true,
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text("Translation"),
                  content: Text(url)
                ),
              );
            }
          });
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

  Future<String> translateImage(File inpImage) async {
    String image = base64Encode(inpImage.readAsBytesSync());
    final request = ChatCompleteText(
      messages: [
        {
          "role": "user",
          "content": [
            {"type": "text", "text": "Translate this image to $translateTo"},
            {
              "type": "image_url",
              "image_url": {
                "url": "data:image/jpg;base64,{$image}"
              }
            }
          ]
        }
      ],
      model: Gpt4oMiniChatModel(),
    );
    ChatCTResponse? response = await openAI.onChatCompletion(request: request);
    if (response == null) {
      return translateFailure;
    }
    return response.choices[0].message!.content;
  }
}

Future<XFile?> pickImage(ImagePicker picker) async {
  return await picker.pickImage(source: ImageSource.gallery);
}