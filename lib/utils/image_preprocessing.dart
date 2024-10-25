import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';

const int imageSize = 224;
const List<double> mean = [0.48145466, 0.4578275, 0.40821073];
const List<double> std = [0.26862954, 0.26130258, 0.27577711];

// Center crop function to match CLIP preprocessing
img.Image centerCrop(img.Image image, int cropSize) {
  int xOffset = (image.width - cropSize) ~/ 2;
  int yOffset = (image.height - cropSize) ~/ 2;
  return img.copyCrop(image, x: xOffset, y: yOffset, width: cropSize, height: cropSize);
}

Future<List<List<List<List<double>>>>> preprocessImage(File imageFile) async {
  final imageBytes = await imageFile.readAsBytes();
  img.Image? image = img.decodeImage(imageBytes);

  if (image == null) {
    throw Exception('Failed to decode image');
  }

  // Step 1: Resize the image so that the smaller edge is 224 pixels
  img.Image resizedImage;
  if (image.width > image.height) {
    resizedImage = img.copyResize(image, height: imageSize);
  } else {
    resizedImage = img.copyResize(image, width: imageSize);
  }

  // Step 2: Center crop to (224, 224)
  img.Image croppedImage = centerCrop(resizedImage, imageSize);

  // Step 3: Prepare the output as [1, 3, 224, 224]
  List<List<double>> rChannel = List.generate(imageSize, (_) => List.filled(imageSize, 0.0));
  List<List<double>> gChannel = List.generate(imageSize, (_) => List.filled(imageSize, 0.0));
  List<List<double>> bChannel = List.generate(imageSize, (_) => List.filled(imageSize, 0.0));

  for (int y = 0; y < croppedImage.height; y++) {
    for (int x = 0; x < croppedImage.width; x++) {
      img.Pixel pixel = croppedImage.getPixel(x, y);
      double r = (pixel.r / 255.0 - mean[0]) / std[0];
      double g = (pixel.g / 255.0 - mean[1]) / std[1];
      double b = (pixel.b / 255.0 - mean[2]) / std[2];

      // Organize as separate channels
      rChannel[y][x] = r;
      gChannel[y][x] = g;
      bChannel[y][x] = b;
    }
  }

  // Return the final structure in the form [1, 3, 224, 224]
  return [
    [
      rChannel, // Red channel
      gChannel, // Green channel
      bChannel, // Blue channel
    ]
  ];
}