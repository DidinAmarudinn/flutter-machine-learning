import 'dart:io';
import 'package:image/image.dart' as img;

class LoadImageClass {
  LoadImageClass() {}
  Future<img.Image> loadImage(String imagePath) async {
    var originData = File(imagePath).readAsBytesSync();
    var originImage = img.decodeImage(originData);

    return originImage;
  }
}
