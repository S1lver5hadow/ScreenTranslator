import 'package:flutter/material.dart';

class ImageTranslationPair {
  final Image _image;
  final String _translation;

  ImageTranslationPair({required Image image, required String translation}) : _image = image, _translation = translation;

  Image getImage() {return _image;}

  String getTranslation() {return _translation;}
}