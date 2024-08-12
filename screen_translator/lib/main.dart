import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() {
  runApp(const MaterialApp(home: MainApp()));
}

// overlay entry point
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(child: Text("My overlay"))
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TextButton(
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
                    height: 200,
                    width: 200,
                    startPosition: const OverlayPosition(0, -259),
                  );
                }
              }
            },
            child: const Text("Start"),
          ),
        ),
      ),
    );
  }
}
