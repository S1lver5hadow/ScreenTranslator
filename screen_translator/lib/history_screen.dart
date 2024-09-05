import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_translator/main.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
        title: const Text("Saved Translations"),
        centerTitle: true,
        backgroundColor: Colors.cyan,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Consumer<AppState>(
                builder: (BuildContext context, AppState state, Widget? child) {
                  
                  /* If the user has saved any translations then it returns them
                  in a list with their corresponding image otherwise return text
                  stating there are no saved translations */  
                  return (state.translations.isNotEmpty) ? Column(
                    children:  state.translations.reversed.map((pair) => Container(
                      margin: const EdgeInsets.all(10),
                      child: Card(
                        child: Column(
                          children: [
                            pair.getImage(),
                            ListTile(
                              subtitle: Text(pair.getTranslation()),
                            ),
                          ],
                        )
                      ),
                    )).toList()
                  )
                  : Text("No Translations Saved");
                },   
              )
            ],
          )
        )
      )
    );
  } 
}