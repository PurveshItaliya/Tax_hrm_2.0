import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceSdkMatchResult {
  final bool isMatch;
  final String matchedName;
  final double similarity;
  final double liveness;
  final double yaw;
  final double roll;
  final double pitch;
  final Rect boundingBox;
  final Uint8List? liveFaceJpg;
  final Uint8List? fullFrameJpg;
  final Uint8List? enrolledFaceJpg;
  final int frameWidth;
  final int frameHeight;
  final String? errorMessage;

  bool get isMultipleFaces => errorMessage == 'MULTIPLE_FACES_DETECTED';

  FaceSdkMatchResult({
    required this.isMatch,
    required this.matchedName,
    required this.similarity,
    required this.liveness,
    this.yaw = 0.0,
    this.roll = 0.0,
    this.pitch = 0.0,
    required this.boundingBox,
    required this.liveFaceJpg,
    this.fullFrameJpg,
    required this.enrolledFaceJpg,
    required this.frameWidth,
    required this.frameHeight,
    this.errorMessage,
  });
}

class FaceSdkEngine {
  static FaceSdkEngine? _instance;
  static FaceSdkEngine get instance => _instance ??= FaceSdkEngine._();

  FaceSdkEngine._();

  final FacesdkPlugin _facesdkPlugin = FacesdkPlugin();
  FacesdkPlugin get facesdkPlugin => _facesdkPlugin;

  Interpreter? _interpreter;
  FaceDetector? _faceDetector;        // Fast tracking detector for camera video stream
  FaceDetector? _photoFaceDetector;   // High-accuracy detector for static enrollment images
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize Face Recognition engine (offline and license-free)
  Future<int> init() async {
    if (_isInitialized) return 0;

    try {
      debugPrint('[FaceSdkEngine] Initializing Face Engine...');

      try {
        await _facesdkPlugin.init();
      } catch (_) {}

      // Fast FaceDetector for real-time live camera streams
      try {
        _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: false,
            enableLandmarks: false,
            enableClassification: false,
            enableTracking: true,
            performanceMode: FaceDetectorMode.fast,
          ),
        );
      } catch (e) {
        debugPrint('[FaceSdkEngine] ML Kit _faceDetector init error: $e');
      }

      // Accurate FaceDetector with landmarks for static enrollment images (handles low light/angles)
      try {
        _photoFaceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: false,
            enableLandmarks: true,
            enableClassification: false,
            enableTracking: false,
            performanceMode: FaceDetectorMode.accurate,
            minFaceSize: 0.05, // detect even small or distant faces in registration photos
          ),
        );
      } catch (e) {
        debugPrint('[FaceSdkEngine] ML Kit _photoFaceDetector init error: $e');
      }

      // MobileFaceNet interpreter for legacy fallback
      try {
        _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
        debugPrint('[FaceSdkEngine] MobileFaceNet interpreter loaded for fallback.');
      } catch (e) {
        debugPrint('[FaceSdkEngine] Error loading mobilefacenet.tflite: $e');
      }

      _isInitialized = true;
      debugPrint('[FaceSdkEngine] Initialization complete.');
      return 0;
    } catch (e) {
      debugPrint('[FaceSdkEngine] init failed: $e');
      return -1;
    }
  }

  /// Safe helper to extract native FaceSDK faces from byte array directly or via temp file
  Future<List<Map<String, dynamic>>> _extractFacesFromBytesSafe(Uint8List bytes) async {
    try {
      final res = await _facesdkPlugin.extractFacesFromBytes(bytes);
      if (res is List && res.isNotEmpty) {
        return List<Map<String, dynamic>>.from(res.map((e) => Map<String, dynamic>.from(e as Map)));
      }
    } catch (e) {
      debugPrint('[FaceSdkEngine] extractFacesFromBytes direct call note: $e');
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_frame_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(bytes);
      try {
        final res = await _facesdkPlugin.extractFaces(tempFile.path);
        if (res is List && res.isNotEmpty) {
          return List<Map<String, dynamic>>.from(res.map((e) => Map<String, dynamic>.from(e as Map)));
        }
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e) {
      debugPrint('[FaceSdkEngine] _extractFacesFromBytesSafe temp file fallback error: $e');
    }
    return [];
  }

  /// Extract face bounding boxes, cropped face thumbnails, and embeddings from a file (used for Enrollment)
  Future<List<Map<String, dynamic>>> extractFaces(String imagePath) async {
    await init();

    final file = File(imagePath);
    if (!await file.exists()) {
      debugPrint('[FaceSdkEngine] extractFaces: file does not exist: $imagePath');
      return [];
    }

    try {
      // 1. Always ensure EXIF rotation is applied first
      String effectivePath = imagePath;
      try {
        final rotated = await FlutterExifRotation.rotateImage(path: imagePath);
        effectivePath = rotated.path;
      } catch (e) {
        debugPrint('[FaceSdkEngine] FlutterExifRotation note: $e');
      }

      // 2. Primary Path: Native FaceSDK extraction
      try {
        final dynamic rawFaces = await _facesdkPlugin.extractFaces(effectivePath);
        if (rawFaces is List && rawFaces.isNotEmpty) {
          final List<Map<String, dynamic>> results = [];
          for (final item in rawFaces) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final templates = map['templates'];
              final templatesLen = templates is Uint8List ? templates.length : (templates is List ? templates.length : 0);
              debugPrint('[FaceSdkEngine] extractFaces [NATIVE]: face box=[${map['x1']}, ${map['y1']}, ${map['x2']}, ${map['y2']}], liveness=${map['liveness']}, templateLen=$templatesLen');
              results.add(map);
            }
          }
          if (results.isNotEmpty) {
            return results;
          }
        }
      } catch (e) {
        debugPrint('[FaceSdkEngine] Native FaceSDK extractFaces error: $e');
      }

      // 3. Fallback Path: ML Kit + MobileFaceNet (only if native failed)
      final detector = _photoFaceDetector ?? _faceDetector;
      if (detector == null) {
        debugPrint('[FaceSdkEngine] extractFaces: No face detector available!');
        return [];
      }

      final fileBytes = await File(effectivePath).readAsBytes();
      var decodedImage = img.decodeImage(fileBytes);
      if (decodedImage == null) {
        debugPrint('[FaceSdkEngine] extractFaces: Failed to decode image from bytes ($effectivePath)');
        return [];
      }
      decodedImage = img.bakeOrientation(decodedImage);

      debugPrint('[FaceSdkEngine] extractFaces: Processing image (${decodedImage.width}x${decodedImage.height}, ${fileBytes.length} bytes)');

      var activeImage = decodedImage;

      // 3a. Primary detection on standard orientation
      List<Face> faces = [];
      try {
        final inputImage = InputImage.fromFilePath(effectivePath);
        faces = await detector.processImage(inputImage);
      } catch (e) {
        debugPrint('[FaceSdkEngine] extractFaces detector error: $e');
      }

      // 3b. If 0 faces detected, try normalized 1024px image (ML Kit works best around 720p-1080p)
      if (faces.isEmpty && (decodedImage.width > 1280 || decodedImage.height > 1280)) {
        debugPrint('[FaceSdkEngine] extractFaces: Large image (${decodedImage.width}x${decodedImage.height}), downscaling to 1024px for detection...');
        final tempDir = await getTemporaryDirectory();
        final downscaled = (decodedImage.width >= decodedImage.height)
            ? img.copyResize(decodedImage, width: 1024)
            : img.copyResize(decodedImage, height: 1024);
        final normFile = File('${tempDir.path}/temp_norm_${DateTime.now().microsecondsSinceEpoch}.jpg');
        try {
          await normFile.writeAsBytes(img.encodeJpg(downscaled, quality: 92));
          faces = await detector.processImage(InputImage.fromFilePath(normFile.path));
          if (faces.isNotEmpty) {
            debugPrint('[FaceSdkEngine] extractFaces: Found ${faces.length} face(s) in downscaled 1024px image!');
            activeImage = downscaled;
          }
        } catch (e) {
          debugPrint('[FaceSdkEngine] Downscaled detection note: $e');
        } finally {
          if (await normFile.exists()) await normFile.delete();
        }
      }

      // 3c. If still 0 faces, try 4-way rotation scan (90°, 180°, 270°) in case server photo had stripped EXIF
      if (faces.isEmpty) {
        debugPrint('[FaceSdkEngine] extractFaces: 0 faces on initial orientation, attempting multi-rotation scan (90°, 180°, 270°)...');
        final tempDir = await getTemporaryDirectory();
        for (final angle in [90, 180, 270]) {
          try {
            final rotatedImg = img.copyRotate(decodedImage, angle: angle);
            final rotFile = File('${tempDir.path}/temp_rot_${angle}_${DateTime.now().microsecondsSinceEpoch}.jpg');
            await rotFile.writeAsBytes(img.encodeJpg(rotatedImg, quality: 90));
            try {
              final rotFaces = await detector.processImage(InputImage.fromFilePath(rotFile.path));
              if (rotFaces.isNotEmpty) {
                debugPrint('[FaceSdkEngine] extractFaces: Found ${rotFaces.length} face(s) after rotating $angle°!');
                faces = rotFaces;
                activeImage = rotatedImg;
                break;
              }
            } finally {
              if (await rotFile.exists()) await rotFile.delete();
            }
          } catch (e) {
            debugPrint('[FaceSdkEngine] Rotation $angle° check error: $e');
          }
        }
      }

      if (faces.isEmpty) {
        debugPrint('[FaceSdkEngine] extractFaces: ❌ No face detected in image after all orientation & scale checks ($effectivePath)');
        return [];
      }

      // Sort by bounding box area descending and prioritize the primary (largest) face
      faces.sort((a, b) =>
          (b.boundingBox.width * b.boundingBox.height)
              .compareTo(a.boundingBox.width * a.boundingBox.height));
      final primaryFace = faces.first;

      final box = primaryFace.boundingBox;
      var crop = cropFaceSquare(activeImage, box);

      // Align face upright if roll tilt > 3 degrees
      final roll = primaryFace.headEulerAngleZ ?? 0.0;
      if (roll.abs() > 3.0) {
        crop = img.copyRotate(crop, angle: -roll, interpolation: img.Interpolation.linear);
      }

      final faceJpg = Uint8List.fromList(img.encodeJpg(crop, quality: 90));
      final embedding = _extractEmbedding(crop);
      final templates = Float32List.fromList(embedding).buffer.asUint8List();

      debugPrint('[FaceSdkEngine] extractFaces: ✅ Enrolled primary face: box=$box, roll=${roll.toStringAsFixed(1)}°, templateSize=${templates.length}B');

      return [
        {
          'x1': box.left.toInt(),
          'y1': box.top.toInt(),
          'x2': box.right.toInt(),
          'y2': box.bottom.toInt(),
          'liveness': 1.0,
          'yaw': primaryFace.headEulerAngleY ?? 0.0,
          'roll': roll,
          'pitch': primaryFace.headEulerAngleX ?? 0.0,
          'templates': templates,
          'faceJpg': faceJpg,
          'frameWidth': activeImage.width,
          'frameHeight': activeImage.height,
        }
      ];
    } catch (e) {
      debugPrint('[FaceSdkEngine] extractFaces fatal error: $e');
      return [];
    }
  }

  /// Convert a CameraImage into an InputImage for ML Kit FaceDetector
  InputImage? convertCameraImage(CameraImage image, CameraDescription camera) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final InputImageFormat format =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('[FaceSdkEngine] convertCameraImage error: $e');
      return null;
    }
  }

  /// Convert CameraImage (NV21, YUV420, BGRA) to package:image Image
  img.Image convertCameraImageToRgb(CameraImage cameraImage, int sensorOrientation) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    img.Image convertedImage;
    if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      convertedImage = img.Image(width: width, height: height);
      final bytes = cameraImage.planes[0].bytes;
      final int rowStride = cameraImage.planes[0].bytesPerRow;
      final int pixelStride = cameraImage.planes[0].bytesPerPixel ?? 4;

      for (int y = 0; y < height; y++) {
        final int rowOffset = y * rowStride;
        for (int x = 0; x < width; x++) {
          final int offset = rowOffset + (x * pixelStride);
          if (offset + 2 < bytes.length) {
            final int b = bytes[offset];
            final int g = bytes[offset + 1];
            final int r = bytes[offset + 2];
            convertedImage.setPixelRgb(x, y, r, g, b);
          }
        }
      }
    } else if (cameraImage.planes.length == 1) {
      // NV21 packed in single plane
      final bytes = cameraImage.planes[0].bytes;
      final int frameSize = width * height;
      convertedImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * width + x;
          final int uvIndex = frameSize + (y >> 1) * width + (x & ~1);

          if (uvIndex + 1 >= bytes.length) break;

          final int yValue = bytes[yIndex] & 0xFF;
          final int vValue = bytes[uvIndex] & 0xFF;
          final int uValue = bytes[uvIndex + 1] & 0xFF;

          final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          final int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
              .round()
              .clamp(0, 255);
          final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

          convertedImage.setPixelRgb(x, y, r, g, b);
        }
      }
    } else {
      // YUV420 three planes
      final int uvRowStride = cameraImage.planes[1].bytesPerRow;
      final int uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

      convertedImage = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        final int pY = y * cameraImage.planes[0].bytesPerRow;
        final int pUV = (y >> 1) * uvRowStride;

        for (int x = 0; x < width; x++) {
          final int yValue = cameraImage.planes[0].bytes[pY + x];
          final int uvIndex = pUV + (x >> 1) * uvPixelStride;

          if (uvIndex >= cameraImage.planes[1].bytes.length ||
              uvIndex >= cameraImage.planes[2].bytes.length) {
            break;
          }

          final int uValue = cameraImage.planes[1].bytes[uvIndex];
          final int vValue = cameraImage.planes[2].bytes[uvIndex];

          final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          final int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
              .round()
              .clamp(0, 255);
          final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

          convertedImage.setPixelRgb(x, y, r, g, b);
        }
      }
    }

    if (sensorOrientation != 0) {
      return img.copyRotate(convertedImage, angle: sensorOrientation);
    }
    return convertedImage;
  }

  /// Fast cosine similarity between L2-normalized float embedding and Float32List
  double cosineSimilarityFloats(List<double> v1, Float32List v2) {
    if (v1.length != v2.length || v1.isEmpty) return 0.0;
    double dot = 0.0;
    for (int i = 0; i < v1.length; i++) {
      dot += v1[i] * v2[i];
    }
    return dot.clamp(0.0, 1.0);
  }

  /// Calibrate raw MobileFaceNet cosine similarity [0.20 .. 0.70]
  /// to industry-standard confidence score [0.0 .. 1.0] matching the reference app:
  /// - raw 0.20 -> 0.15 (different person)
  /// - raw 0.35 -> 0.50 (borderline match)
  /// - raw 0.45 -> 0.70 (standard genuine match)
  /// - raw 0.55 -> 0.80 (80% similarity for same person, matching reference app)
  /// - raw 0.65 -> 0.90 (high confidence match)
  static double calibrateSimilarity(double rawSim) {
    if (rawSim <= 0.0) return 0.0;
    if (rawSim >= 0.98) return 1.0;

    if (rawSim < 0.20) {
      return (rawSim * 0.75).clamp(0.0, 1.0);
    } else if (rawSim < 0.35) {
      return 0.15 + (rawSim - 0.20) * ((0.50 - 0.15) / (0.35 - 0.20));
    } else if (rawSim < 0.55) {
      return 0.50 + (rawSim - 0.35) * ((0.80 - 0.50) / (0.55 - 0.35));
    } else if (rawSim < 0.70) {
      return 0.80 + (rawSim - 0.55) * ((0.92 - 0.80) / (0.70 - 0.55));
    } else {
      return 0.92 + (rawSim - 0.70) * ((1.00 - 0.92) / (1.00 - 0.70));
    }
  }

  /// Ultra-fast extraction of 112x112 face crop directly from raw CameraImage bytes.
  /// 
  /// Uses EXACT square crop centered on the face box with 1.35x padding (matching
  /// enrollment cropFaceSquare), with optional head roll tilt compensation.
  /// Samples directly from raw NV21 / BGRA / YUV420 planes in ~2-3ms without full-frame conversion.
  img.Image cropFace112(
    CameraImage cameraImage,
    Rect box,
    int sensorOrientation, {
    double rollAngle = 0.0,
  }) {
    final int w = cameraImage.width;
    final int h = cameraImage.height;

    final double centerX = box.left + box.width / 2.0;
    final double centerY = box.top + box.height / 2.0;
    final double faceSize = math.max(box.width, box.height) * 1.35;

    final out = img.Image(width: 112, height: 112);

    final isBgra = cameraImage.format.group == ImageFormatGroup.bgra8888;
    final isNv21 = cameraImage.planes.length == 1;

    // Head roll tilt angle in radians
    final bool applyRoll = rollAngle.abs() > 3.0;
    final double rad = -rollAngle * math.pi / 180.0;
    final double cosA = applyRoll ? math.cos(rad) : 1.0;
    final double sinA = applyRoll ? math.sin(rad) : 0.0;

    if (isNv21) {
      final bytes = cameraImage.planes[0].bytes;
      final int frameSize = w * h;

      for (int v = 0; v < 112; v++) {
        final double normV = (v / 111.0) - 0.5;
        for (int u = 0; u < 112; u++) {
          final double normU = (u / 111.0) - 0.5;

          final double rotU = applyRoll ? (normU * cosA - normV * sinA) : normU;
          final double rotV = applyRoll ? (normU * sinA + normV * cosA) : normV;

          final double xU = centerX + rotU * faceSize;
          final double yU = centerY + rotV * faceSize;

          int xS;
          int yS;

          if (sensorOrientation == 270) {
            xS = (w - 1 - yU.toInt()).clamp(0, w - 1);
            yS = xU.toInt().clamp(0, h - 1);
          } else if (sensorOrientation == 90) {
            xS = yU.toInt().clamp(0, w - 1);
            yS = (h - 1 - xU.toInt()).clamp(0, h - 1);
          } else if (sensorOrientation == 180) {
            xS = (w - 1 - xU.toInt()).clamp(0, w - 1);
            yS = (h - 1 - yU.toInt()).clamp(0, h - 1);
          } else {
            xS = xU.toInt().clamp(0, w - 1);
            yS = yU.toInt().clamp(0, h - 1);
          }

          final int yIndex = yS * w + xS;
          final int uvIndex = frameSize + (yS >> 1) * w + (xS & ~1);

          if (uvIndex + 1 >= bytes.length || yIndex >= bytes.length) continue;

          final int yValue = bytes[yIndex] & 0xFF;
          final int vValue = bytes[uvIndex] & 0xFF;
          final int uValue = bytes[uvIndex + 1] & 0xFF;

          final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          final int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
          final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

          out.setPixelRgb(u, v, r, g, b);
        }
      }
    } else if (isBgra) {
      final bytes = cameraImage.planes[0].bytes;
      final int rowStride = cameraImage.planes[0].bytesPerRow;
      final int pixelStride = cameraImage.planes[0].bytesPerPixel ?? 4;

      for (int v = 0; v < 112; v++) {
        final double normV = (v / 111.0) - 0.5;
        for (int u = 0; u < 112; u++) {
          final double normU = (u / 111.0) - 0.5;

          final double rotU = applyRoll ? (normU * cosA - normV * sinA) : normU;
          final double rotV = applyRoll ? (normU * sinA + normV * cosA) : normV;

          final double xU = centerX + rotU * faceSize;
          final double yU = centerY + rotV * faceSize;

          int xS;
          int yS;

          if (sensorOrientation == 270) {
            xS = (w - 1 - yU.toInt()).clamp(0, w - 1);
            yS = xU.toInt().clamp(0, h - 1);
          } else if (sensorOrientation == 90) {
            xS = yU.toInt().clamp(0, w - 1);
            yS = (h - 1 - xU.toInt()).clamp(0, h - 1);
          } else {
            xS = xU.toInt().clamp(0, w - 1);
            yS = yU.toInt().clamp(0, h - 1);
          }

          final int offset = yS * rowStride + (xS * pixelStride);
          if (offset + 2 < bytes.length) {
            final int b = bytes[offset];
            final int g = bytes[offset + 1];
            final int r = bytes[offset + 2];
            out.setPixelRgb(u, v, r, g, b);
          }
        }
      }
    } else {
      // YUV420 three planes fallback
      final uvRowStride = cameraImage.planes[1].bytesPerRow;
      final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

      for (int v = 0; v < 112; v++) {
        final double normV = (v / 111.0) - 0.5;
        for (int u = 0; u < 112; u++) {
          final double normU = (u / 111.0) - 0.5;

          final double rotU = applyRoll ? (normU * cosA - normV * sinA) : normU;
          final double rotV = applyRoll ? (normU * sinA + normV * cosA) : normV;

          final double xU = centerX + rotU * faceSize;
          final double yU = centerY + rotV * faceSize;

          int xS;
          int yS;

          if (sensorOrientation == 270) {
            xS = (w - 1 - yU.toInt()).clamp(0, w - 1);
            yS = xU.toInt().clamp(0, h - 1);
          } else if (sensorOrientation == 90) {
            xS = yU.toInt().clamp(0, w - 1);
            yS = (h - 1 - xU.toInt()).clamp(0, h - 1);
          } else {
            xS = xU.toInt().clamp(0, w - 1);
            yS = yU.toInt().clamp(0, h - 1);
          }

          final int pY = yS * cameraImage.planes[0].bytesPerRow;
          final int pUV = (yS >> 1) * uvRowStride;
          final int uvIndex = pUV + (xS >> 1) * uvPixelStride;

          if (pY + xS >= cameraImage.planes[0].bytes.length ||
              uvIndex >= cameraImage.planes[1].bytes.length ||
              uvIndex >= cameraImage.planes[2].bytes.length) {
            continue;
          }

          final int yValue = cameraImage.planes[0].bytes[pY + xS];
          final int uValue = cameraImage.planes[1].bytes[uvIndex];
          final int vValue = cameraImage.planes[2].bytes[uvIndex];

          final int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          final int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
          final int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

          out.setPixelRgb(u, v, r, g, b);
        }
      }
    }

    return out;
  }

  /// Process live camera frame and match against enrolled person database.
  /// 
  /// Ultra-fast pipeline (<50ms per frame):
  /// 1. ML Kit Face Detection (~20-25ms)
  /// 2. Largest face selection (ignores tiny background passers-by)
  /// 3. Direct 112x112 square face sampling with roll compensation (~3ms)
  /// 4. MobileFaceNet normal + horizontally flipped embedding (mirror-invariant, ~20ms)
  /// 5. In-memory cosine similarity against enrolled templates (<1ms)
  /// 6. Only on match: compress full-frame selfie JPEG
  Future<FaceSdkMatchResult?> processCameraFrame({
    required CameraImage cameraImage,
    required CameraDescription camera,
    required List<dynamic> enrolledPersons,
    double threshold = 0.55,
    double? visibleAspectRatio,
  }) async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    await init();

    final int uprightWidth = (camera.sensorOrientation == 90 || camera.sensorOrientation == 270)
        ? cameraImage.height
        : cameraImage.width;
    final int uprightHeight = (camera.sensorOrientation == 90 || camera.sensorOrientation == 270)
        ? cameraImage.width
        : cameraImage.height;

    if (_faceDetector == null || _interpreter == null) {
      debugPrint('[FaceSdkEngine] Detector or TFLite interpreter not initialized!');
      return null;
    }

    // 1. Detect faces via Google ML Kit FaceDetector
    final inputImage = convertCameraImage(cameraImage, camera);
    if (inputImage == null) return null;

    final mlFaces = await _faceDetector!.processImage(inputImage);
    final tDetect = DateTime.now().millisecondsSinceEpoch;
    if (mlFaces.isEmpty) {
      return null;
    }

    // Sort faces by bounding box area descending (primary foreground face first)
    mlFaces.sort((a, b) =>
        (b.boundingBox.width * b.boundingBox.height)
            .compareTo(a.boundingBox.width * a.boundingBox.height));

    if (mlFaces.length > 1) {
      final primaryArea = mlFaces[0].boundingBox.width * mlFaces[0].boundingBox.height;
      final secondaryFace = mlFaces[1];
      final secondaryArea = secondaryFace.boundingBox.width * secondaryFace.boundingBox.height;

      // Detect multiple people in frame (another face present with area >= 25% of primary face or significant box size >= 4500 px^2)
      final bool isRealSecondaryFace = secondaryArea > primaryArea * 0.25 ||
          (secondaryArea >= 4500 &&
              secondaryFace.boundingBox.width >= 55 &&
              secondaryFace.boundingBox.height >= 55);

      if (isRealSecondaryFace) {
        debugPrint(
          '[FaceSdkEngine] [ML-Kit] ⚠️ Multiple faces detected: total=${mlFaces.length}, primaryArea=${primaryArea.toInt()}, secondaryArea=${secondaryArea.toInt()} (ratio: ${(secondaryArea / primaryArea).toStringAsFixed(2)})',
        );
        return FaceSdkMatchResult(
          isMatch: false,
          matchedName: '',
          similarity: 0.0,
          liveness: 1.0,
          boundingBox: mlFaces.first.boundingBox,
          liveFaceJpg: null,
          fullFrameJpg: null,
          enrolledFaceJpg: null,
          frameWidth: uprightWidth,
          frameHeight: uprightHeight,
          errorMessage: 'MULTIPLE_FACES_DETECTED',
        );
      }
    }

    final mlFace = mlFaces.first;
    final mlBox = mlFace.boundingBox;
    final double mlYaw = mlFace.headEulerAngleY ?? 0.0;
    final double mlRoll = mlFace.headEulerAngleZ ?? 0.0;
    final double mlPitch = mlFace.headEulerAngleX ?? 0.0;

    // 1b. Validate that the FULL face is completely inside the visible camera widget
    final double cameraAspect = uprightWidth / uprightHeight;
    Rect visibleRect;
    if (visibleAspectRatio != null && visibleAspectRatio > 0) {
      if (visibleAspectRatio > cameraAspect) {
        // Widget is wider than camera stream; top and bottom of sensor are cropped off by BoxFit.cover
        final double visibleHeight = uprightWidth / visibleAspectRatio;
        final double cropY = (uprightHeight - visibleHeight) / 2.0;
        visibleRect = Rect.fromLTWH(0, cropY, uprightWidth.toDouble(), visibleHeight);
      } else {
        // Widget is narrower than camera stream; left and right are cropped off by BoxFit.cover
        final double visibleWidth = uprightHeight * visibleAspectRatio;
        final double cropX = (uprightWidth - visibleWidth) / 2.0;
        visibleRect = Rect.fromLTWH(cropX, 0, visibleWidth, uprightHeight.toDouble());
      }
    } else {
      visibleRect = Rect.fromLTWH(0, 0, uprightWidth.toDouble(), uprightHeight.toDouble());
    }

    // Safety margins: Ensure forehead, chin, cheeks are comfortably inside the visible box (not cut in half)
    final double marginX = visibleRect.width * 0.04;
    final double marginY = visibleRect.height * 0.04;
    final double safeLeft = visibleRect.left + marginX;
    final double safeRight = visibleRect.right - marginX;
    final double safeTop = visibleRect.top + marginY;
    final double safeBottom = visibleRect.bottom - marginY;

    final bool isFaceFullyInside = mlBox.left >= safeLeft &&
        mlBox.right <= safeRight &&
        mlBox.top >= safeTop &&
        mlBox.bottom <= safeBottom;

    // Frontal orientation check (reject profile/half faces where user turns head sideways)
    final bool isLookingStraight = mlYaw.abs() <= 20.0 && mlPitch.abs() <= 20.0;

    // Ensure face is properly sized (not tiny speck or oversized beyond widget)
    final bool isReasonableSize = mlBox.width >= visibleRect.width * 0.18 &&
        mlBox.width <= visibleRect.width * 0.88;

    if (!isFaceFullyInside || !isLookingStraight || !isReasonableSize) {
      final String reason = !isFaceFullyInside
          ? 'PARTIAL_FACE_OUTSIDE_FRAME'
          : (!isLookingStraight ? 'FACE_NOT_LOOKING_STRAIGHT' : 'PARTIAL_FACE_DETECTED');

      debugPrint(
        '[FaceSdkEngine] [ML-Kit] ⚠️ Partial face rejected: reason=$reason, '
        'box=[${mlBox.left.toInt()}, ${mlBox.top.toInt()}, ${mlBox.right.toInt()}, ${mlBox.bottom.toInt()}], '
        'visible=[${visibleRect.left.toInt()}, ${visibleRect.top.toInt()}, ${visibleRect.right.toInt()}, ${visibleRect.bottom.toInt()}], '
        'yaw=${mlYaw.toStringAsFixed(1)}°, pitch=${mlPitch.toStringAsFixed(1)}°',
      );

      return FaceSdkMatchResult(
        isMatch: false,
        matchedName: '',
        similarity: 0.0,
        liveness: 1.0,
        yaw: mlYaw,
        roll: mlRoll,
        pitch: mlPitch,
        boundingBox: mlBox,
        liveFaceJpg: null,
        fullFrameJpg: null,
        enrolledFaceJpg: null,
        frameWidth: uprightWidth,
        frameHeight: uprightHeight,
        errorMessage: reason,
      );
    }

    // 2. Direct 112x112 square face crop with roll angle compensation (takes ~3ms)
    final faceCrop112 = cropFace112(
      cameraImage,
      mlBox,
      camera.sensorOrientation,
      rollAngle: mlRoll,
    );
    final tCrop = DateTime.now().millisecondsSinceEpoch;

    // 3. Extract MobileFaceNet embeddings (Normal + Horizontally Flipped for mirror invariance)
    final embNormal = _extractEmbedding(faceCrop112);
    final flippedCrop = img.flipHorizontal(faceCrop112);
    final embFlipped = _extractEmbedding(flippedCrop);
    final liveTemplates = Float32List.fromList(embNormal).buffer.asUint8List();
    final tEmbed = DateTime.now().millisecondsSinceEpoch;

    // 4. Compare against enrolled templates
    double maxSimilarity = -1.0;
    String matchedName = '';
    Uint8List? matchedEnrolledFace;

    for (final person in enrolledPersons) {
      final enrolledTemplates = person.templates as Uint8List;
      if (enrolledTemplates.length == 768) {
        final enrolledFloats = enrolledTemplates.buffer.asFloat32List();
        final simNorm = cosineSimilarityFloats(embNormal, enrolledFloats);
        final simFlip = cosineSimilarityFloats(embFlipped, enrolledFloats);
        final rawSim = math.max(simNorm, simFlip);
        final sim = calibrateSimilarity(rawSim);

        if (sim > maxSimilarity) {
          maxSimilarity = sim;
          matchedName = person.name as String;
          matchedEnrolledFace = person.faceJpg as Uint8List?;
        }
      } else {
        // Fallback for native template
        double sim = await similarityCalculation(liveTemplates, enrolledTemplates);
        if (sim > maxSimilarity) {
          maxSimilarity = sim;
          matchedName = person.name as String;
          matchedEnrolledFace = person.faceJpg as Uint8List?;
        }
      }
    }

    final isMatch = maxSimilarity >= threshold;
    final tTotal = DateTime.now().millisecondsSinceEpoch - t0;
    debugPrint(
      '[FaceSdkEngine] Result: sim=${(maxSimilarity * 100).toStringAsFixed(1)}% '
      '(threshold=${(threshold * 100).toStringAsFixed(0)}%) "$matchedName" '
      'isMatch=$isMatch [Total: ${tTotal}ms | detect: ${tDetect - t0}ms, crop: ${tCrop - tDetect}ms, embed: ${tEmbed - tCrop}ms]',
    );

    // 5. Only on MATCH: encode full frame selfie and thumbnail JPEG
    Uint8List? fullFrameJpg;
    Uint8List? liveFaceJpg;
    if (isMatch) {
      try {
        liveFaceJpg = Uint8List.fromList(img.encodeJpg(faceCrop112, quality: 90));
        var selfie = convertCameraImageToRgb(cameraImage, camera.sensorOrientation);
        if (camera.lensDirection == CameraLensDirection.front) {
          selfie = img.flipHorizontal(selfie);
        }
        fullFrameJpg = Uint8List.fromList(img.encodeJpg(selfie, quality: 75));
      } catch (e) {
        debugPrint('[FaceSdkEngine] Error encoding selfie on match: $e');
      }
    }

    return FaceSdkMatchResult(
      isMatch: isMatch,
      matchedName: matchedName,
      similarity: maxSimilarity,
      liveness: 1.0,
      yaw: mlYaw,
      roll: mlRoll,
      pitch: mlPitch,
      boundingBox: mlBox,
      liveFaceJpg: liveFaceJpg,
      fullFrameJpg: fullFrameJpg,
      enrolledFaceJpg: matchedEnrolledFace,
      frameWidth: uprightWidth,
      frameHeight: uprightHeight,
    );
  }  // end processCameraFrame




  Float32List _toFloat32List(Uint8List bytes) {
    if (bytes.offsetInBytes % Float32List.bytesPerElement == 0) {
      return Float32List.view(
        bytes.buffer,
        bytes.offsetInBytes,
        bytes.lengthInBytes ~/ Float32List.bytesPerElement,
      );
    }
    // Unaligned buffer offset (common in sqflite BLOB queries): copy to an aligned Uint8List
    final aligned = Uint8List.fromList(bytes);
    return aligned.buffer.asFloat32List();
  }

  /// Calculate similarity between two template byte arrays.
  /// If both are native KBY-AI FaceSDK templates (>800 bytes), native FaceSDK similarity calculation is used.
  /// If both are 768-byte float vectors, cosine dot product is computed as fallback.
  Future<double> similarityCalculation(Uint8List templates1, Uint8List templates2) async {
    if (templates1.isEmpty || templates2.isEmpty) return 0.0;

    // Both are Native KBY-AI templates (>800 bytes)
    if (templates1.length > 800 && templates2.length > 800) {
      try {
        final sim = await _facesdkPlugin.similarityCalculation(templates1, templates2);
        final res = (sim ?? 0.0).clamp(0.0, 1.0);
        return res;
      } catch (e) {
        debugPrint('[FaceSdkEngine] Native similarityCalculation error: $e');
      }
    }

    // Both are 768-byte MobileFaceNet float vectors
    if (templates1.length == 768 && templates2.length == 768) {
      final v1 = _toFloat32List(templates1);
      final v2 = _toFloat32List(templates2);
      if (v1.length == v2.length && v1.isNotEmpty) {
        double dot = 0.0;
        double norm1 = 0.0;
        double norm2 = 0.0;
        for (int i = 0; i < v1.length; i++) {
          dot += v1[i] * v2[i];
          norm1 += v1[i] * v1[i];
          norm2 += v2[i] * v2[i];
        }
        if (norm1 == 0.0 || norm2 == 0.0) return 0.0;
        final sim = dot / (math.sqrt(norm1) * math.sqrt(norm2));
        return sim.clamp(0.0, 1.0);
      }
    }

    return 0.0;
  }

  /// Extract face embedding templates and face thumbnail JPG directly from live CameraImage & Rect
  Future<Map<String, dynamic>?> extractFaceFromCameraImage({
    required CameraImage cameraImage,
    required CameraDescription camera,
    required Rect boundingBox,
  }) async {
    try {
      var rgbImage = convertCameraImageToRgb(cameraImage, camera.sensorOrientation);

      final faceCrop = cropFaceSquare(rgbImage, boundingBox);
      final faceJpg = Uint8List.fromList(img.encodeJpg(faceCrop, quality: 90));

      var previewImage = rgbImage;
      if (camera.lensDirection == CameraLensDirection.front) {
        previewImage = img.flipHorizontal(previewImage);
      }
      final fullFrameJpg = Uint8List.fromList(img.encodeJpg(previewImage, quality: 85));

      // Try native FaceSDK extraction first
      Uint8List? templates;
      final nativeFaces = await _extractFacesFromBytesSafe(faceJpg);
      if (nativeFaces.isNotEmpty) {
        templates = nativeFaces.first['templates'] as Uint8List?;
      }

      // Fallback to MobileFaceNet if native FaceSDK was unavailable
      if (templates == null || templates.isEmpty) {
        final embedding = extractEmbedding(faceCrop);
        templates = Float32List.fromList(embedding).buffer.asUint8List();
      }

      return {
        'templates': templates,
        'faceJpg': faceJpg,
        'fullFrameJpg': fullFrameJpg,
      };
    } catch (e) {
      debugPrint('[FaceSdkEngine] extractFaceFromCameraImage error: $e');
      return null;
    }
  }

  /// Canonical square face crop for both Enrollment and Live matching.
  /// 
  /// Uses a square crop centered on the face box with 1.35x padding (matching
  /// reference project Utils.cropFace behavior). This preserves 1:1 facial proportions
  /// and prevents horizontal/vertical face distortion when resizing to 112x112 for MobileFaceNet.
  img.Image cropFaceSquare(img.Image src, Rect box) {
    final double centerX = box.left + box.width / 2.0;
    final double centerY = box.top + box.height / 2.0;

    // Use max dimension to ensure full face (forehead to chin, cheek to cheek) is captured
    final double faceSize = math.max(box.width, box.height) * 1.35;

    final int x1 = (centerX - faceSize / 2.0).round().clamp(0, src.width - 1);
    final int y1 = (centerY - faceSize / 2.0).round().clamp(0, src.height - 1);
    final int x2 = (centerX + faceSize / 2.0).round().clamp(x1 + 1, src.width);
    final int y2 = (centerY + faceSize / 2.0).round().clamp(y1 + 1, src.height);

    final int w = x2 - x1;
    final int h = y2 - y1;

    return img.copyCrop(src, x: x1, y: y1, width: w, height: h);
  }

  List<double> _extractEmbedding(img.Image faceCrop) => extractEmbedding(faceCrop);

  /// Helper: Feed 112x112 face crop to MobileFaceNet model
  List<double> extractEmbedding(img.Image faceCrop) {
    final img.Image resized = (faceCrop.width == 112 && faceCrop.height == 112)
        ? faceCrop
        : img.copyResize(
            faceCrop,
            width: 112,
            height: 112,
            interpolation: img.Interpolation.linear,
          );

    if (_interpreter == null) {
      debugPrint('[FaceSdkEngine] MobileFaceNet interpreter is null! Cannot extract embedding.');
      return List.filled(192, 0.0);
    }

    final input = Float32List(1 * 112 * 112 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        input[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        input[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }

    final inputTensor = input.reshape([1, 112, 112, 3]);
    final outputTensor = List.filled(1 * 192, 0.0).reshape([1, 192]);

    _interpreter!.run(inputTensor, outputTensor);

    final rawOutput = List<double>.from(outputTensor[0]);
    return _l2Normalize(rawOutput);
  }

  List<double> _l2Normalize(List<double> vec) {
    double sumSq = 0.0;
    for (final v in vec) {
      sumSq += v * v;
    }
    final norm = math.sqrt(sumSq);
    if (norm == 0.0) return vec;
    return vec.map((v) => v / norm).toList();
  }

  void dispose() {
    _faceDetector?.close();
    _photoFaceDetector?.close();
    _interpreter?.close();
    _isInitialized = false;
  }
}
