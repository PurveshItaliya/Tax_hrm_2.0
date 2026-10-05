// ignore_for_file: empty_catches, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';
import 'dart:math' show sqrt;
import 'dart:typed_data';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  Interpreter? recognitionInterpreter;
  Interpreter? livenessInterpreter;
  bool isInitialized = false;

  void log(String message) {
    debugPrint("[FaceRecognitionService] $message");
  }

  final String recModelPath = 'assets/models/mobilefacenet.tflite';
  final String fasModelPath = 'assets/models/fas.tflite';

  final FaceDetector faceDetector = FaceDetector(
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
    if (isInitialized) return;

    log("Initializing models. useMockModels: $useMockModels");
    if (useMockModels) {
      recognitionInterpreter = null;
      livenessInterpreter = null;
    } else {
      try {
        recognitionInterpreter = await Interpreter.fromAsset(recModelPath);
        log("Recognition model loaded successfully.");
      } catch (e) {
        log("Error loading recognition model: $e");
        debugPrint("Error loading recognition model: $e");
      }

      try {
        livenessInterpreter = await Interpreter.fromAsset(fasModelPath);
        log("Liveness model loaded successfully.");
      } catch (e) {
        log("Error loading liveness model: $e");
        debugPrint("Error loading liveness model: $e");
      }
    }

    isInitialized = true;
    log("Initialization complete.");
  }

  void dispose() {
    log("Disposing FaceRecognitionService.");
    faceDetector.close();
    recognitionInterpreter?.close();
    livenessInterpreter?.close();
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
    return await faceDetector.processImage(inputImage);
  }

  /// Validates a face for enrollment or punch (size, angle, single face)
  String? validateFaceQuality(List<Face> faces, CameraImage image, CameraDescription camera) {
    if (faces.isEmpty) return 'noFace';
    if (faces.length > 1) return 'multipleFaces';

    final face = faces.first;

    // Calculate actual image size based on rotation
    bool isRotated = camera.sensorOrientation == 90 || camera.sensorOrientation == 270;
    double actualWidth = isRotated ? image.height.toDouble() : image.width.toDouble();
    double actualHeight = isRotated ? image.width.toDouble() : image.height.toDouble();

    // Check face size (e.g. > 20% of image height) - Relaxed slightly to 15%
    if (face.boundingBox.height < actualHeight * 0.15) {
      return 'moveCloser';
    }

    // Check face tilt (yaw, pitch, roll) - Relaxed from 15 degrees to 25 degrees
    if (face.headEulerAngleY != null &&
        (face.headEulerAngleY! > 25 || face.headEulerAngleY! < -25)) {
      return 'straightenFace';
    }
    if (face.headEulerAngleZ != null &&
        (face.headEulerAngleZ! > 25 || face.headEulerAngleZ! < -25)) {
      return 'straightenFace';
    }

    // Check if the entire face bounding box is within the central circular frame area.
    // We define a strict central region based on the camera image dimensions.
    // Relaxed by expanding the allowed area slightly so users don't have to be perfectly centered.
    double centerX = actualWidth / 2;
    double centerY = actualHeight / 2;
    
    double allowedRadiusX = actualWidth * 0.45; // Increased from 0.35
    double allowedRadiusY = actualHeight * 0.35; // Increased from 0.25
    
    bool isOutsideFrame = face.boundingBox.left < (centerX - allowedRadiusX) ||
                          face.boundingBox.right > (centerX + allowedRadiusX) ||
                          face.boundingBox.top < (centerY - allowedRadiusY) ||
                          face.boundingBox.bottom > (centerY + allowedRadiusY);

    if (isOutsideFrame) {
      return 'alignFace';
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
  static Float32List imageToByteListFloat32Static(
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
      
      return imageToByteListFloat32Static(resized, 80, 0.0, 1.0);
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
      return imageToByteListFloat32Static(resized, 112, 127.5, 127.5);
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
    log("checkLiveness called for face boundingBox: ${face.boundingBox}");
    if (!isInitialized) {
      log("Error: Service not initialized before calling checkLiveness");
      return false;
    }
    if (livenessInterpreter == null) {
      log("Warning: Liveness interpreter is null, bypassing liveness check.");
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
        log("Error: _processLivenessIsolate returned null");
        return false;
      }

      var input = processedInput.reshape([1, 80, 80, 3]);
      var output = List.filled(
        1 * 3,
        0.0,
      ).reshape([1, 3]); // Output: [fake_score_1, real_score, fake_score_2]

      livenessInterpreter!.run(input, output);

      double fakeScore1 = output[0][0];
      double realScore = output[0][1];
      double fakeScore2 = output[0][2];

      log("Liveness scores - real: $realScore, fake1: $fakeScore1, fake2: $fakeScore2");

      // The class with the highest score is the prediction
      if (realScore > fakeScore1 && realScore > fakeScore2) {
        return true;
      }
      return false;
    } catch (e) {
      log("Liveness check error: $e");
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
    log("generateFaceEmbedding called for boundingBox: ${face.boundingBox}");
    if (!isInitialized) {
      log("Error: Service not initialized before calling generateFaceEmbedding");
      return null;
    }
    try {
      // Run heavy image processing on an Isolate to prevent UI freeze
      final dynamic processedResult = await Isolate.run(() => _processRecognitionIsolate({
        'cameraImage': cameraImage,
        'sensorOrientation': camera.sensorOrientation,
        'boundingBox': face.boundingBox,
        'hasInterpreter': recognitionInterpreter != null,
      }));
      
      if (processedResult == null) {
        log("Error: _processRecognitionIsolate returned null");
        return null;
      }
      
      if (recognitionInterpreter == null) {
        final res = processedResult as List<double>;
        log("Face embedding generated (mock/pseudo). Length: ${res.length}");
        return res; // pseudoEmbedding is already a List<double>
      }

      var input = (processedResult as Float32List).reshape([1, 112, 112, 3]);
      var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      recognitionInterpreter!.run(input, output);

      List<double> embedding = List<double>.from(output[0]);
      final normalized = _l2NormalizeStatic(embedding);
      log("Face embedding generated. Length: ${normalized.length}");
      return normalized;
    } catch (e) {
      log("generateFaceEmbedding error: $e");
      debugPrint("generateFaceEmbedding Error: $e");
      return null;
    }
  }

  /// Generate embedding vector for a static File
  Future<List<double>?> generateFaceEmbeddingFromFile(File file) async {
    log("generateFaceEmbeddingFromFile called for file: ${file.path}");
    if (!isInitialized) {
      log("Error: Service not initialized before calling generateFaceEmbeddingFromFile");
      return null;
    }
    try {
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await detectFaces(inputImage);

      if (faces.isEmpty) {
        log("No face detected in the file.");
        return null;
      }

      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        log("Error: Failed to decode image from bytes.");
        return null;
      }

      final faceCrop = _cropFaceStatic(image, faces.first.boundingBox);
      
      // Normalize lighting for better detection across different lighting conditions
      final normalizedCrop = img.normalize(faceCrop, min: 0, max: 255);

      if (recognitionInterpreter == null) {
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
        log("Static file embedding generated (mock/pseudo). Length: ${normalized.length}");
        return normalized;
      }

      final resized = img.copyResize(normalizedCrop, width: 112, height: 112);
      var input = imageToByteListFloat32Static(
        resized,
        112,
        127.5,
        127.5,
      ).reshape([1, 112, 112, 3]);
      var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      recognitionInterpreter!.run(input, output);

      List<double> embedding = List<double>.from(output[0]);
      final normalized = _l2NormalizeStatic(embedding);
      log("Static file embedding generated. Length: ${normalized.length}");
      return normalized;
    } catch (e) {
      log("generateFaceEmbeddingFromFile error: $e");
      debugPrint("generateFaceEmbeddingFromFile Error: $e");
      return null;
    }
  }

  /// Encode array to Base64 (Quantized to Int8 for a 4x shorter string)
  String embeddingToBase64(List<double> embedding) {
    final int8List = Int8List(embedding.length);
    for (int i = 0; i < embedding.length; i++) {
      // The embeddings are L2 normalized, so values are roughly between -1.0 and 1.0.
      int val = (embedding[i] * 127.0).round();
      if (val > 127) val = 127;
      if (val < -128) val = -128;
      int8List[i] = val;
    }
    final bytes = int8List.buffer.asUint8List();
    return base64Encode(bytes);
  }

  /// Decode Base64 to array (Supports both new short Int8 format and legacy Float32/Float64)
  List<double> embeddingFromBase64(String base64Str) {
    final bytes = base64Decode(base64Str);
    
    // New 4x shorter format (192 bytes for 192 features)
    if (bytes.length == 192) {
      final int8List = bytes.buffer.asInt8List();
      return int8List.map((e) => e / 127.0).toList();
    }
    
    // Legacy Float32 format (768 bytes for 192 features)
    if (bytes.length == 768) {
      return bytes.buffer.asFloat32List().map((e) => e.toDouble()).toList();
    }
    
    // Legacy Float64 format
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

  /// Average multiple embeddings into a single normalized embedding
  List<double> averageEmbeddings(List<List<double>> embeddings) {
    if (embeddings.isEmpty) return [];
    if (embeddings.length == 1) return embeddings.first;
    
    int length = embeddings.first.length;
    List<double> avg = List.filled(length, 0.0);
    
    for (var emb in embeddings) {
      for (int i = 0; i < length; i++) {
        avg[i] += emb[i];
      }
    }
    
    for (int i = 0; i < length; i++) {
      avg[i] /= embeddings.length;
    }
    
    return _l2NormalizeStatic(avg);
  }
}
