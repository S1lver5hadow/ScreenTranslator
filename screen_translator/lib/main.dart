import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screen_translator/home_screen.dart';
import 'package:screen_translator/image_translation_pair.dart';
import 'package:screen_translator/translate_head.dart';

void main() {
  runApp(App());
}

// overlay entry point
@pragma("vm:entry-point")
void overlayMain() {
   SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
 ));
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(child: TranslateHead())
  ));
}

class AppState extends ChangeNotifier {
  final List<ImageTranslationPair> translations = [];

  void addTranslation(Image image, String translation) {
    translations.add(ImageTranslationPair(
      image: image, 
      translation: translation
    ));
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
