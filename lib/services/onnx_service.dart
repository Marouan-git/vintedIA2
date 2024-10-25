import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import '../utils/input_ids.dart';

class OnnxService {
  // Singleton instance
  static final OnnxService _instance = OnnxService._internal();

  // Loaded ONNX session (kept in memory)
  late OrtSession _session;

  // Private constructor (singleton)
  OnnxService._internal();

  // Factory constructor to return the singleton instance
  factory OnnxService() {
    return _instance;
  }

  // Initialize the ONNX model (this should be called only once)
  Future<void> initializeModel() async {
    print('Initializing ONNX model...');

    try {
      // Initialize the ONNX Runtime environment
      OrtEnv.instance.init();

      // Load the model from assets (use your actual model path)
      const modelFileName = 'assets/model/clip_clothes_classification_quant.onnx';
      final rawAssetFile = await rootBundle.load(modelFileName);
      final modelBytes = rawAssetFile.buffer.asUint8List();

      // Create session options
      final sessionOptions = OrtSessionOptions();

      // Create and store the ONNX session in memory
      _session = OrtSession.fromBuffer(modelBytes, sessionOptions);
      print('ONNX model initialized successfully.');
    } catch (e) {
      print('Error initializing ONNX model: $e');
      throw Exception('Failed to initialize ONNX model');
    }
  }

  // Run inference using the pre-loaded ONNX model
  Future<String> runInference(List<List<List<List<double>>>> preprocessedImage) async {
    try {
      print('Running ONNX inference...');

      // Flatten the preprocessed image data
      List<List<double>> flattenedImage = preprocessedImage
          .expand((channel) => channel.expand((row) => row))
          .toList();

      // Convert the flattened image data to Float32List
      Float32List float32Image = Float32List.fromList(flattenedImage.map((e) => e.map((v) => v.toDouble()).toList()).expand((e) => e).toList());

      // Prepare input tensor for the image (1, 3, 224, 224)
      final imageTensor =
          OrtValueTensor.createTensorWithDataList(float32Image, [1, 3, 224, 224]);

      // Prepare input tensor for the image (1, 3, 224, 224)
      // final imageTensor =
      //     OrtValueTensor.createTensorWithDataList(flattenedImage, [1, 3, 224, 224]);

      final batchSize = inputIds.length; // Should be 8
      final sequenceLength = inputIds[0].length; // Should be 9

      // Prepare input tensor for input_ids (batch_size, 9)
      final inputIdsTensor = OrtValueTensor.createTensorWithDataList(
        inputIdsFlatten(), // Pass the entire input_ids
        [batchSize, sequenceLength] // Shape: [8, 9]
      );

      // Prepare input tensor for input_ids (1, input_length)
      // final inputIdsTensor =
      //     OrtValueTensor.createTensorWithDataList(flattenedInputIds, [1, flattenedInputIds.length]);

      // print inputIdsTensor shape

      print('Input tensor for image created with length: ${flattenedImage.length}');

      // Define the input map with tensor names and corresponding tensor values
      final inputs = {   
        'pixel_values': imageTensor,
        'input_ids': inputIdsTensor,
      };


      // Create OrtRunOptions object
      final runOptions = OrtRunOptions();

      print('Running inference...');

      // Run the model inference
      final outputs = _session.run(runOptions, inputs);

      print('Inference completed.');

      // Release the input tensors and run options after the inference
      imageTensor.release();
      inputIdsTensor.release();
      runOptions.release();

      // Extract the logits from the output (nested List<List<double>>)
    final logits = outputs[0]?.value as List<List<double>>?;

    if (logits == null || logits.isEmpty) {
      throw Exception('Failed to get logits from the model output.');
    }

    // The logits are nested as List<List<double>>, so we need to extract the inner list
    List<double> extractedLogits = logits.first; // Access the first element of the nested list

    print('Extracted logits: $extractedLogits');

    // Perform softmax to convert logits to probabilities
    List<double> probabilities = softmax(extractedLogits);

    // Map probabilities to categories
    List<String> categoriesFr = ["Robe", "T-shirt", "Pantalon", "Veste", "Sous-vêtements", "Chaussures", "Chapeau", "Pull"];

    // Find the category with the highest probability
    String mostProbableCategory = categoriesFr[probabilities.indexWhere((p) => p == probabilities.reduce((a, b) => a > b ? a : b))];

    print('Most probable category: $mostProbableCategory');

    return mostProbableCategory;
    } catch (e) {
      print('Error during ONNX inference: $e');
      throw Exception('Inference failed');
    }
  }

 // Helper function to return input_ids as a 2D tensor
  List<List<int>> inputIdsFlatten() {
    return inputIds; // Return the 2D list as-is
  }

  // Helper function for softmax
  List<double> softmax(List<double> logits) {
    double maxLogit = logits.reduce((a, b) => a > b ? a : b);
    List<double> expLogits = logits.map((logit) => exp(logit - maxLogit)).toList();
    double sumExpLogits = expLogits.reduce((a, b) => a + b);
    return expLogits.map((expLogit) => expLogit / sumExpLogits).toList();
  }
}