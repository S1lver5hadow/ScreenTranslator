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
  // Ports used to communicate with the overlay
  final _recievePort = ReceivePort();
  SendPort? homePort;

  // Misc objects needed by libraries
  final _picker = ImagePicker();
  late OpenAI _openAI;

  // Stores the language the app is currently translating to
  String _translateTo = "English";

  final String _translateFailure = "TRANSLATION FAILURE";

  // Stores details about the last translation done by the user
  String _lastTranslation = "Your last translation will be shown here";
  XFile? _lastImage;

  // Determines if the user can save the last translation or not
  bool _saveImage = false;

  // List of all langauges supported to be translated to
  final List<String> _languages = [
    "English", "French", "Spanish", "German", "Punjabi", "Hindi"
  ];


  @override
  void initState() {
    super.initState();

    // Sets up the openAI API, the token used here is the API key kept private
    _openAI = OpenAI.instance.build(
      token: token,
      baseOption: HttpSetup(
        receiveTimeout: const Duration(seconds: 20),
        connectTimeout: const Duration(seconds: 20)),
      enableLog: true,
    );

    // Sets up the recieve port with the name of home
    if (homePort != null) {
      return;
    }
    IsolateNameServer.registerPortWithName(
      _recievePort.sendPort, 
      "Home"
    );

    // When the overlay sends a message we choose a picture from the gallery
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
                  // Used to start/stop the overlay
                  TextButton(
                    onPressed: () async {
                      final bool perm = await FlutterOverlayWindow
                        .isPermissionGranted();
                      if (!perm) {
                        final bool? request = await FlutterOverlayWindow
                          .requestPermission();
                        if ((request == null || request == false) && 
                        context.mounted) {
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

                  // Choose an image straight from the gallery to translate
                  TextButton(
                    onPressed: () async {
                      chooseFromGallery();
                    },
                    child: const Text("Choose from Gallery"),
                  ),

                  // Take a picture with the camera and translate that image
                  TextButton(
                    onPressed: () async {
                      chooseFromCamera();
                    },
                    child: const Text("Take a Picture")
                  ),

                  // Enter the screen storing the user's saved translations
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryScreen()),
                      );
                    },
                    child: const Text("Saved Translations")
                  ),

                  // Lets the user choose a different language to translate to
                  Container(
                    margin: const EdgeInsets.all(5),
                    child: Column(
                      children: [
                        DropdownMenu(
                          initialSelection: _translateTo,
                          onSelected: (String? value) {
                            if (value != null && _languages.contains(value)) {
                              setState(() { _translateTo = value; });
                            }
                          },
                          dropdownMenuEntries: _languages.map((value) => 
                            DropdownMenuEntry(value: value, label: value)).toList(),
                        ),
                        Text("Choose what language to translate to"),
                      ],
                    ),
                  ),

                  // Stores the previous translation with the image input
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

                  // Lets the user save the previous translation and image
                  TextButton(
                    onPressed: !_saveImage ? null : () {
                      Provider.of<AppState>(context, listen: false)
                      .addTranslation(Image.file(File(_lastImage!.path)), 
                        _lastTranslation);
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
      translateProcess(xfilepick);
    });
  }

  void chooseFromCamera() async {
    takePhoto(_picker).then((xfilepick) {
      translateProcess(xfilepick);
    });
  }

  // This function carries out the main translation process
  void translateProcess(XFile? xfilepick) async {
    if (xfilepick != null) {
      translateImage(File(xfilepick.path)).then((translation) { 
        if (translation == _translateFailure) {
          showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text("Failed to translate"),
              content: const Text(
                "Error: Failed to connect to translation servers. Please try " 
                "again."
              )
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

          // Updates the previous translation state to be the current inputs
          setState(() {
            _lastTranslation = translation;
            _lastImage = xfilepick;
            _saveImage = true;
          });
        }
      });
    } else {
      // If the image is null then the user didn't select an image
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
  }

  // Used to communicate with the openAI API to translate an image
  Future<String> translateImage(File inpImage) async {
    // The image is encoded in base64 so the API will accept it
    String image = base64Encode(inpImage.readAsBytesSync());

    /* This is the request sent to the API which requests the image to be
    translated into the _translateTo language */
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

    // This returns the response as either a failure or the translation
    ChatCTResponse? response = await _openAI.onChatCompletion(request: request);
    if (response == null) {
      return _translateFailure;
    }
    return response.choices[0].message!.content;
  }
}

// Functions that let the app use images from the gallery/camera
Future<XFile?> pickImage(ImagePicker picker) async {
  return await picker.pickImage(source: ImageSource.gallery);
}

Future<XFile?> takePhoto(ImagePicker picker) async {
  return await picker.pickImage(source: ImageSource.camera);
}