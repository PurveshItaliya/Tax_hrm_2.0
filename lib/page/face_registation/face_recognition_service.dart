// ignore_for_file: empty_catches, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';
import 'dart:math' show sqrt;
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  Interpreter? _recognitionInterpreter;
  Interpreter? _livenessInterpreter;
  bool _isInitialized = false;

  void _log(String message) {
    debugPrint("[FaceRecognitionService] $message");
  }

  final String _recModelPath = 'assets/models/mobilefacenet.tflite';
  final String _fasModelPath = 'assets/models/fas.tflite';

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // IMPORTANT: Set this to false ONLY when you have replaced the dummy
  // .tflite files in assets/models with the REAL, working model files!
  static const bool useMockModels = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _log("Initializing models. useMockModels: $useMockModels");
    if (useMockModels) {
      _recognitionInterpreter = null;
      _livenessInterpreter = null;
    } else {
      try {
        _recognitionInterpreter = await Interpreter.fromAsset(_recModelPath);
        _log("Recognition model loaded successfully.");
      } catch (e) {
        _log("Error loading recognition model: $e");
        debugPrint("Error loading recognition model: $e");
      }

      try {
        _livenessInterpreter = await Interpreter.fromAsset(_fasModelPath);
        _log("Liveness model loaded successfully.");
      } catch (e) {
        _log("Error loading liveness model: $e");
        debugPrint("Error loading liveness model: $e");
      }
    }

    _isInitialized = true;
    _log("Initialization complete.");
  }

  void dispose() {
    _log("Disposing FaceRecognitionService.");
    _faceDetector.close();
    _recognitionInterpreter?.close();
    _livenessInterpreter?.close();
  }

  /// Convert CameraImage to ML Kit InputImage
  InputImage? convertCameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // On Android, camera package returns YUV_420_888. On iOS, bgra8888.

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final InputImageRotation imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;

    // Fallback format if null (e.g. nv21 on Android)
    final InputImageFormat inputImageFormat =
        format ??
        (Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888);

    final planeData = image.planes.map((Plane plane) {
      return InputImageMetadata(
        bytesPerRow: plane.bytesPerRow,
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
      );
    }).toList();

    if (planeData.isEmpty) return null;

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: planeData.first,
    );
    return inputImage;
  }

  Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  /// Validates a face for enrollment or punch (size, angle, single face)
  String? validateFaceQuality(List<Face> faces, Size imageSize) {
    if (faces.isEmpty) return 'noFace';
    if (faces.length > 1) return 'multipleFaces';

    final face = faces.first;

    // Check face size (e.g. > 20% of image height)
    if (face.boundingBox.height < imageSize.height * 0.2) {
      return 'moveCloser';
    }

    // Check face tilt (yaw, pitch, roll)
    if (face.headEulerAngleY != null &&
        (face.headEulerAngleY! > 15 || face.headEulerAngleY! < -15)) {
      return 'straightenFace';
    }
    if (face.headEulerAngleZ != null &&
        (face.headEulerAngleZ! > 15 || face.headEulerAngleZ! < -15)) {
      return 'straightenFace';
    }

    return null; // Valid face
  }

  static img.Image _convertCameraImageToImageStatic(
    CameraImage cameraImage,
    int sensorOrientation,
  ) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    img.Image convertedImage;
    if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      convertedImage = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: cameraImage.planes[0].bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    } else if (cameraImage.planes.length == 1) {
      // NV21 packed in a single plane
      final bytes = cameraImage.planes[0].bytes;
      final int frameSize = width * height;
      convertedImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int yIndex = y * width + x;
          int uvIndex = frameSize + (y >> 1) * width + (x & ~1);

          if (uvIndex + 1 >= bytes.length) break;

          int yValue = bytes[yIndex] & 0xFF;
          int vValue = bytes[uvIndex] & 0xFF;
          int uValue = bytes[uvIndex + 1] & 0xFF;

          int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          int g =
              (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                  .round()
                  .clamp(0, 255);
          int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

          convertedImage.setPixelRgb(x, y, r, g, b);
        }
      }
    } else {
      // YUV420 to RGB
      final int uvRowStride = cameraImage.planes[1].bytesPerRow;
      final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

      convertedImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        int pY = y * cameraImage.planes[0].bytesPerRow;
        int pUV = (y >> 1) * uvRowStride;

        for (int x = 0; x < width; x++) {
          int yValue = cameraImage.planes[0].bytes[pY + x];
          int uvIndex = pUV + (x >> 1) * uvPixelStride;

          if (uvIndex >= cameraImage.planes[1].bytes.length ||
              uvIndex >= cameraImage.planes[2].bytes.length)
            break;

          int uValue = cameraImage.planes[1].bytes[uvIndex];
          int vValue = cameraImage.planes[2].bytes[uvIndex];

          int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          int g =
              (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                  .round()
                  .clamp(0, 255);
          int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

          convertedImage.setPixelRgb(x, y, r, g, b);
        }
      }
    }

    if (sensorOrientation != 0) {
      return img.copyRotate(convertedImage, angle: sensorOrientation);
    }
    return convertedImage;
  }

  /// Crop face from image using bounding box (clamped to image bounds)
  static img.Image _cropFaceStatic(img.Image image, Rect boundingBox) {
    double marginX = boundingBox.width * 0.15;
    double marginY = boundingBox.height * 0.15;

    int x = (boundingBox.left - marginX).toInt().clamp(0, image.width - 1);
    int y = (boundingBox.top - marginY).toInt().clamp(0, image.height - 1);
    int w = (boundingBox.width + marginX * 2).toInt().clamp(1, image.width - x);
    int h = (boundingBox.height + marginY * 2).toInt().clamp(
      1,
      image.height - y,
    );

    return img.copyCrop(image, x: x, y: y, width: w, height: h);
  }

  /// Preprocess image for TFLite (resize, normalize)
  static Float32List _imageToByteListFloat32Static(
    img.Image image,
    int inputSize,
    double mean,
    double std,
  ) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }
  
  static List<double> _l2NormalizeStatic(List<double> vec) {
    double sumSq = 0.0;
    for (double v in vec) sumSq += v * v;
    double norm = sqrt(sumSq);
    if (norm == 0) return vec;
    return vec.map((v) => v / norm).toList();
  }

  // --- Isolate Task Functions ---
  
  static Float32List? _processLivenessIsolate(Map<String, dynamic> params) {
    try {
      final cameraImage = params['cameraImage'] as CameraImage;
      final sensorOrientation = params['sensorOrientation'] as int;
      final boundingBox = params['boundingBox'] as Rect;

      final image = _convertCameraImageToImageStatic(cameraImage, sensorOrientation);
      final faceCrop = _cropFaceStatic(image, boundingBox);
      
      // Normalize lighting for better detection across different lighting conditions
      final normalizedCrop = img.normalize(faceCrop, min: 0, max: 255);
      
      final resized = img.copyResize(
        normalizedCrop,
        width: 80,
        height: 80,
      );
      
      return _imageToByteListFloat32Static(resized, 80, 0.0, 1.0);
    } catch (e) {
      debugPrint("Isolate Liveness Error: $e");
      return null;
    }
  }
  
  static dynamic _processRecognitionIsolate(Map<String, dynamic> params) {
    try {
      final cameraImage = params['cameraImage'] as CameraImage;
      final sensorOrientation = params['sensorOrientation'] as int;
      final boundingBox = params['boundingBox'] as Rect;
      final hasInterpreter = params['hasInterpreter'] as bool;

      final image = _convertCameraImageToImageStatic(cameraImage, sensorOrientation);
      final faceCrop = _cropFaceStatic(image, boundingBox);
      
      // Normalize lighting for better detection across different lighting conditions
      final normalizedCrop = img.normalize(faceCrop, min: 0, max: 255);

      if (!hasInterpreter) {
        final resized = img.copyResize(normalizedCrop, width: 8, height: 24);
        List<double> pseudoEmbedding = [];
        for (int i = 0; i < 24; i++) {
          for (int j = 0; j < 8; j++) {
            final pixel = resized.getPixel(j, i);
            double luma = pixel.r / 255.0;
            pseudoEmbedding.add(luma);
          }
        }
        return _l2NormalizeStatic(pseudoEmbedding);
      }

      final resized = img.copyResize(normalizedCrop, width: 112, height: 112);
      return _imageToByteListFloat32Static(resized, 112, 127.5, 127.5);
    } catch (e) {
      debugPrint("Isolate Recognition Error: $e");
      return null;
    }
  }

  /// Check Liveness using TFLite model
  Future<bool> checkLiveness(
    CameraImage cameraImage,
    Face face,
    CameraDescription camera,
  ) async {
    _log("checkLiveness called for face boundingBox: ${face.boundingBox}");
    if (!_isInitialized) {
      _log("Error: Service not initialized before calling checkLiveness");
      return false;
    }
    if (_livenessInterpreter == null) {
      _log("Warning: Liveness interpreter is null, bypassing liveness check.");
      return true; // Mock live
    }

    try {
      // Run heavy image processing on an Isolate to prevent UI freeze
      final Float32List? processedInput = await Isolate.run(() => _processLivenessIsolate({
        'cameraImage': cameraImage,
        'sensorOrientation': camera.sensorOrientation,
        'boundingBox': face.boundingBox,
      }));
      
      if (processedInput == null) {
        _log("Error: _processLivenessIsolate returned null");
        return false;
      }

      var input = processedInput.reshape([1, 80, 80, 3]);
      var output = List.filled(
        1 * 3,
        0.0,
      ).reshape([1, 3]); // Output: [fake_score_1, real_score, fake_score_2]

      _livenessInterpreter!.run(input, output);

      double fakeScore1 = output[0][0];
      double realScore = output[0][1];
      double fakeScore2 = output[0][2];

      _log("Liveness scores - real: $realScore, fake1: $fakeScore1, fake2: $fakeScore2");

      // The class with the highest score is the prediction
      if (realScore > fakeScore1 && realScore > fakeScore2) {
        return true;
      }
      return false;
    } catch (e) {
      _log("Liveness check error: $e");
      debugPrint("CheckLiveness Error: $e");
      return false;
    }
  }

  /// Generate embedding vector for the face
  Future<List<double>?> generateFaceEmbedding(
    CameraImage cameraImage,
    Face face,
    CameraDescription camera,
  ) async {
    _log("generateFaceEmbedding called for boundingBox: ${face.boundingBox}");
    if (!_isInitialized) {
      _log("Error: Service not initialized before calling generateFaceEmbedding");
      return null;
    }
    try {
      // Run heavy image processing on an Isolate to prevent UI freeze
      final dynamic processedResult = await Isolate.run(() => _processRecognitionIsolate({
        'cameraImage': cameraImage,
        'sensorOrientation': camera.sensorOrientation,
        'boundingBox': face.boundingBox,
        'hasInterpreter': _recognitionInterpreter != null,
      }));
      
      if (processedResult == null) {
        _log("Error: _processRecognitionIsolate returned null");
        return null;
      }
      
      if (_recognitionInterpreter == null) {
        final res = processedResult as List<double>;
        _log("Face embedding generated (mock/pseudo). Length: ${res.length}");
        return res; // pseudoEmbedding is already a List<double>
      }

      var input = (processedResult as Float32List).reshape([1, 112, 112, 3]);
      var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      _recognitionInterpreter!.run(input, output);

      List<double> embedding = List<double>.from(output[0]);
      final normalized = _l2NormalizeStatic(embedding);
      _log("Face embedding generated. Length: ${normalized.length}");
      return normalized;
    } catch (e) {
      _log("generateFaceEmbedding error: $e");
      debugPrint("generateFaceEmbedding Error: $e");
      return null;
    }
  }

  /// Generate embedding vector for a static File
  Future<List<double>?> generateFaceEmbeddingFromFile(File file) async {
    _log("generateFaceEmbeddingFromFile called for file: ${file.path}");
    if (!_isInitialized) {
      _log("Error: Service not initialized before calling generateFaceEmbeddingFromFile");
      return null;
    }
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await detectFaces(inputImage);

      if (faces.isEmpty) {
        _log("No face detected in the file.");
        return null;
      }

      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        _log("Error: Failed to decode image from bytes.");
        return null;
      }

      final faceCrop = _cropFaceStatic(image, faces.first.boundingBox);
      
      // Normalize lighting for better detection across different lighting conditions
      final normalizedCrop = img.normalize(faceCrop, min: 0, max: 255);

      if (_recognitionInterpreter == null) {
        final resized = img.copyResize(normalizedCrop, width: 8, height: 24);
        List<double> pseudoEmbedding = [];
        for (int i = 0; i < 24; i++) {
          for (int j = 0; j < 8; j++) {
            final pixel = resized.getPixel(j, i);
            double luma = pixel.r / 255.0;
            pseudoEmbedding.add(luma);
          }
        }
        final normalized = _l2NormalizeStatic(pseudoEmbedding);
        _log("Static file embedding generated (mock/pseudo). Length: ${normalized.length}");
        return normalized;
      }

      final resized = img.copyResize(normalizedCrop, width: 112, height: 112);
      var input = _imageToByteListFloat32Static(
        resized,
        112,
        127.5,
        127.5,
      ).reshape([1, 112, 112, 3]);
      var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      _recognitionInterpreter!.run(input, output);

      List<double> embedding = List<double>.from(output[0]);
      final normalized = _l2NormalizeStatic(embedding);
      _log("Static file embedding generated. Length: ${normalized.length}");
      return normalized;
    } catch (e) {
      _log("generateFaceEmbeddingFromFile error: $e");
      debugPrint("generateFaceEmbeddingFromFile Error: $e");
      return null;
    }
  }

  /// Encode array to Base64
  String embeddingToBase64(List<double> embedding) {
    final bytes = Float64List.fromList(embedding).buffer.asUint8List();
    return base64Encode(bytes);
  }

  /// Decode Base64 to array
  List<double> embeddingFromBase64(String base64Str) {
    final bytes = base64Decode(base64Str);
    return bytes.buffer.asFloat64List().toList();
  }

  /// Calculate Cosine Similarity (assuming already L2 normalized, it's just dot product)
  double calculateCosineSimilarity(List<double> e1, List<double> e2) {
    if (e1.length != e2.length) return 0.0;
    double dotProduct = 0.0;
    for (int i = 0; i < e1.length; i++) {
      dotProduct += e1[i] * e2[i];
    }
    return dotProduct;
  }
}
