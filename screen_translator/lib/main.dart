import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_translator/home_screen.dart';
import 'package:screen_translator/translate_head.dart';

void main() {
  runApp(App());
}

// overlay entry point
@pragma("vm:entry-point")
void overlayMain() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(child: TranslateHead())
  ));
}

class AppState extends ChangeNotifier {
  Image? image;

  void addImage(Image image) {
    this.image = image;
    notifyListeners();
  }
}

class App extends StatelessWidget {
  const App({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen()
      )
    );
  } 
}
