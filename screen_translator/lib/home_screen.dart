import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:screen_translator/history_screen.dart';
import 'package:screen_translator/main.dart';
import 'package:screen_translator/secret.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _recievePort = ReceivePort();
  SendPort? homePort;
  final _picker = ImagePicker();
  late OpenAI _openAI;
  String _translateTo = "English";
  String _translateFailure = "TRANSLATION FAILURE";
  String _lastTranslation = "Your last translation will be shown here";
  XFile? _lastImage;
  bool _saveImage = false;


  @override
  void initState() {
    super.initState();

    _openAI = OpenAI.instance.build(
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
      chooseFromGallery();
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
          title: const Text("Home"),
          centerTitle: true,
          backgroundColor: Colors.cyan,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
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
                            height: 125,
                            width: 200,
                            startPosition: const OverlayPosition(0, -259),
                          );
                        }
                      }
                    },
                    child: const Text("Start"),
                  ),
                  TextButton(
                    onPressed: () async {
                      chooseFromGallery();
                    },
                    child: const Text("Choose from Gallery"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryScreen()),
                      );
                    },
                    child: const Text("Saved Translations")
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          (_lastImage != null) ? Image.file(File(_lastImage!.path)) 
                                              : Text("No Image available"),
                          ListTile(
                            title: Text("Previous Translation"),
                            subtitle: Text(_lastTranslation),
                          ),
                        ],
                      )
                    ),
                  ),
                  TextButton(
                    onPressed: !_saveImage ? null : () {
                      Provider.of<AppState>(context, listen: false)
                      .addTranslation(Image.file(File(_lastImage!.path)), _lastTranslation);
                      setState(() { _saveImage = false; });
                    },
                    child: const Text("Save Previous Translation"),
                  )
                ],
              ),
            ),
          )
        )
      ),
    );
  }

  void chooseFromGallery() async {
    pickImage(_picker).then((xfilepick) {
      if (xfilepick != null) {
        translateImage(File(xfilepick.path)).then((translation) {
          if (translation == _translateFailure) {
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
              builder: (BuildContext context) { 
                return AlertDialog(
                  title: const Text("Translation"),
                  content: Text(translation)
                );
              }
            );

            setState(() {
              _lastTranslation = translation;
              _lastImage = xfilepick;
              _saveImage = true;
            });
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
  }

  Future<String> translateImage(File inpImage) async {
    String image = base64Encode(inpImage.readAsBytesSync());
    final request = ChatCompleteText(
      messages: [
        {
          "role": "user",
          "content": [
            {"type": "text", "text": "Translate this image to $_translateTo"},
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
    ChatCTResponse? response = await _openAI.onChatCompletion(request: request);
    if (response == null) {
      return _translateFailure;
    }
    return response.choices[0].message!.content;
  }
}

Future<XFile?> pickImage(ImagePicker picker) async {
  return await picker.pickImage(source: ImageSource.gallery);
}