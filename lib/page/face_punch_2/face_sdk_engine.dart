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
  Interpreter? _livenessInterpreter; // FAS (Face Anti-Spoofing) model
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
            enableClassification: true,
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

      // MobileFaceNet interpreter for face recognition
      try {
        _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
        debugPrint('[FaceSdkEngine] MobileFaceNet interpreter loaded for face recognition.');
      } catch (e) {
        debugPrint('[FaceSdkEngine] Error loading mobilefacenet.tflite: $e');
      }

      // FAS (Face Anti-Spoofing) interpreter for real-time liveness detection
      try {
        _livenessInterpreter = await Interpreter.fromAsset('assets/models/fas.tflite');
        debugPrint('[FaceSdkEngine] FAS (Face Anti-Spoofing) interpreter loaded.');
      } catch (e) {
        debugPrint('[FaceSdkEngine] Error loading fas.tflite: $e');
      }

      _isInitialized = true;
      debugPrint('[FaceSdkEngine] Initialization complete.');
      return 0;
    } catch (e) {
      debugPrint('[FaceSdkEngine] init failed: $e');
      return -1;
    }
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

      // 2. Extract facial embedding using Google ML Kit + MobileFaceNet (100% offline & license-free)
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

      final livenessVal = await computeLiveness(
        fullImage: activeImage,
        box: box,
        mlFace: primaryFace,
      );

      return [
        {
          'x1': box.left.toInt(),
          'y1': box.top.toInt(),
          'x2': box.right.toInt(),
          'y2': box.bottom.toInt(),
          'liveness': livenessVal,
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

  /// MobileFaceNet cosine similarity [0.0 .. 1.0].
  /// With L2-normalized 192-d vectors, dot product directly gives cosine similarity:
  /// - Genuine match (same person): typically 0.68 - 0.88+
  /// - Impostor (different person): typically 0.20 - 0.45 (cleanly rejected at >=0.70 threshold)
  static double calibrateSimilarity(double rawSim) {
    if (rawSim <= 0.0) return 0.0;
    if (rawSim >= 1.0) return 1.0;
    return rawSim;
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
    double paddingScale = 1.35,
  }) {
    final int w = cameraImage.width;
    final int h = cameraImage.height;

    final double centerX = box.left + box.width / 2.0;
    final double centerY = box.top + box.height / 2.0;
    final double faceSize = math.max(box.width, box.height) * paddingScale;

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

  /// Direct extraction of 80x80 face crop in BGR format with 2.7x context scale.
  ///
  /// Uses REPLICATE (edge-clamp) border when the crop exceeds frame boundaries:
  /// - Real faces whose 2.7x crop extends beyond camera frame get edge-clamped skin/background.
  /// - Zero-padding was causing real faces to appear as "dark-bezel screen attacks" (fake2 class).
  /// - Photos shown on a phone/screen or printed paper still score far below the liveness threshold.
  Float32List cropFaceScaled80Bgr(
    CameraImage cameraImage,
    Rect box,
    int sensorOrientation, {
    double scale = 2.7,
  }) {
    final int w = cameraImage.width;
    final int h = cameraImage.height;

    final double centerX = box.left + box.width / 2.0;
    final double centerY = box.top + box.height / 2.0;
    final double faceSize = math.max(box.width, box.height) * scale;

    final input = Float32List(1 * 80 * 80 * 3);
    int pixelIndex = 0;

    final isBgra = cameraImage.format.group == ImageFormatGroup.bgra8888;
    final isNv21 = cameraImage.planes.length == 1;

    if (isNv21) {
      final bytes = cameraImage.planes[0].bytes;
      final int frameSize = w * h;

      for (int v = 0; v < 80; v++) {
        final double normV = (v / 79.0) - 0.5;
        for (int u = 0; u < 80; u++) {
          final double normU = (u / 79.0) - 0.5;

          final double xU = centerX + normU * faceSize;
          final double yU = centerY + normV * faceSize;

          int xS;
          int yS;

          if (sensorOrientation == 270) {
            xS = (w - 1 - yU.toInt());
            yS = xU.toInt();
          } else if (sensorOrientation == 90) {
            xS = yU.toInt();
            yS = (h - 1 - xU.toInt());
          } else if (sensorOrientation == 180) {
            xS = (w - 1 - xU.toInt());
            yS = (h - 1 - yU.toInt());
          } else {
            xS = xU.toInt();
            yS = yU.toInt();
          }

          // Edge-clamp (replicate border): fill out-of-bounds with nearest real pixel
          xS = xS.clamp(0, w - 1);
          yS = yS.clamp(0, h - 1);

          final int yIndex = yS * w + xS;
          final int uvIndex = frameSize + (yS >> 1) * w + (xS & ~1);

          if (uvIndex + 1 >= bytes.length || yIndex >= bytes.length) {
            input[pixelIndex++] = 0.0;
            input[pixelIndex++] = 0.0;
            input[pixelIndex++] = 0.0;
            continue;
          }

          final int yValue = bytes[yIndex] & 0xFF;
          final int vValue = bytes[uvIndex] & 0xFF;
          final int uValue = bytes[uvIndex + 1] & 0xFF;

          final double r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toDouble();
          final double g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toDouble();
          final double b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toDouble();

          input[pixelIndex++] = b;
          input[pixelIndex++] = g;
          input[pixelIndex++] = r;
        }
      }
    } else if (isBgra) {
      final bytes = cameraImage.planes[0].bytes;
      final int rowStride = cameraImage.planes[0].bytesPerRow;
      final int pixelStride = cameraImage.planes[0].bytesPerPixel ?? 4;

      for (int v = 0; v < 80; v++) {
        final double normV = (v / 79.0) - 0.5;
        for (int u = 0; u < 80; u++) {
          final double normU = (u / 79.0) - 0.5;

          final double xU = centerX + normU * faceSize;
          final double yU = centerY + normV * faceSize;

          int xS;
          int yS;

          if (sensorOrientation == 270) {
            xS = (w - 1 - yU.toInt());
            yS = xU.toInt();
          } else if (sensorOrientation == 90) {
            xS = yU.toInt();
            yS = (h - 1 - xU.toInt());
          } else if (sensorOrientation == 180) {
            xS = (w - 1 - xU.toInt());
            yS = (h - 1 - yU.toInt());
          } else {
            xS = xU.toInt();
            yS = yU.toInt();
          }

          // Edge-clamp
          xS = xS.clamp(0, w - 1);
          yS = yS.clamp(0, h - 1);

          final int offset = yS * rowStride + (xS * pixelStride);
          if (offset + 2 < bytes.length) {
            // BGRA: bytes[offset] = B, offset+1 = G, offset+2 = R
            input[pixelIndex++] = bytes[offset].toDouble();
            input[pixelIndex++] = bytes[offset + 1].toDouble();
            input[pixelIndex++] = bytes[offset + 2].toDouble();
          } else {
            input[pixelIndex++] = 0.0;
            input[pixelIndex++] = 0.0;
            input[pixelIndex++] = 0.0;
          }
        }
      }
    } else {
      // YUV420 three planes
      final uvRowStride = cameraImage.planes[1].bytesPerRow;
      final uvPixelStride = cameraImage.planes[1].bytesPerPixel ?? 1;

      for (int v = 0; v < 80; v++) {
        final double normV = (v / 79.0) - 0.5;
        for (int u = 0; u < 80; u++) {
          final double normU = (u / 79.0) - 0.5;

          final double xU = centerX + normU * faceSize;
          final double yU = centerY + normV * faceSize;

          int xS;
          int yS;

          if (sensorOrientation == 270) {
            xS = (w - 1 - yU.toInt());
            yS = xU.toInt();
          } else if (sensorOrientation == 90) {
            xS = yU.toInt();
            yS = (h - 1 - xU.toInt());
          } else if (sensorOrientation == 180) {
            xS = (w - 1 - xU.toInt());
            yS = (h - 1 - yU.toInt());
          } else {
            xS = xU.toInt();
            yS = yU.toInt();
          }

          // Edge-clamp
          xS = xS.clamp(0, w - 1);
          yS = yS.clamp(0, h - 1);

          final int pY = yS * cameraImage.planes[0].bytesPerRow;
          final int pUV = (yS >> 1) * uvRowStride;
          final int uvIndex = pUV + (xS >> 1) * uvPixelStride;

          if (pY + xS >= cameraImage.planes[0].bytes.length ||
              uvIndex >= cameraImage.planes[1].bytes.length ||
              uvIndex >= cameraImage.planes[2].bytes.length) {
            input[pixelIndex++] = 0.0;
            input[pixelIndex++] = 0.0;
            input[pixelIndex++] = 0.0;
            continue;
          }

          final int yValue = cameraImage.planes[0].bytes[pY + xS];
          final int uValue = cameraImage.planes[1].bytes[uvIndex];
          final int vValue = cameraImage.planes[2].bytes[uvIndex];

          final double r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toDouble();
          final double g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toDouble();
          final double b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toDouble();

          input[pixelIndex++] = b;
          input[pixelIndex++] = g;
          input[pixelIndex++] = r;
        }
      }
    }

    return input;
  }

  /// Helper to crop an img.Image with 2.7x scale in BGR order with edge-clamp border
  Float32List _cropImageScaled80Bgr(img.Image src, Rect box, {double scale = 2.7}) {
    final double centerX = box.left + box.width / 2.0;
    final double centerY = box.top + box.height / 2.0;
    final double faceSize = math.max(box.width, box.height) * scale;

    final input = Float32List(1 * 80 * 80 * 3);
    int pixelIndex = 0;

    for (int v = 0; v < 80; v++) {
      final double normV = (v / 79.0) - 0.5;
      for (int u = 0; u < 80; u++) {
        final double normU = (u / 79.0) - 0.5;
        // Edge-clamp: clamp to nearest valid pixel (replicate border)
        final int srcX = (centerX + normU * faceSize).round().clamp(0, src.width - 1);
        final int srcY = (centerY + normV * faceSize).round().clamp(0, src.height - 1);

        final pixel = src.getPixel(srcX, srcY);
        input[pixelIndex++] = pixel.b.toDouble();
        input[pixelIndex++] = pixel.g.toDouble();
        input[pixelIndex++] = pixel.r.toDouble();
      }
    }
    return input;
  }

  /// Compute anti-spoof liveness score [0.0 .. 1.0] using fas.tflite (MiniFASNet).
  /// Returns a confidence score between 0.0 (spoof/screen/photo) and 1.0 (live human face).
  /// Strictly fails closed (returns 0.0 on error or missing interpreter).
  Future<double> computeLiveness({
    Float32List? tensor80Bgr,
    img.Image? faceCrop,
    Rect? box,
    img.Image? fullImage,
    Face? mlFace,
  }) async {
    if (_livenessInterpreter == null) {
      debugPrint('[FaceSdkEngine] ⚠️ FAS interpreter is null, attempting lazy load...');
      try {
        _livenessInterpreter = await Interpreter.fromAsset('assets/models/fas.tflite');
        debugPrint('[FaceSdkEngine] FAS interpreter successfully loaded on-demand.');
      } catch (e) {
        debugPrint('[FaceSdkEngine] ❌ Error loading fas.tflite on-demand: $e');
      }
    }

    if (_livenessInterpreter == null) {
      debugPrint('[FaceSdkEngine] ❌ _livenessInterpreter is null! Rejecting as NOT LIVE (fail-closed).');
      return 0.0;
    }

    try {
      Float32List input;
      if (tensor80Bgr != null && tensor80Bgr.length == 1 * 80 * 80 * 3) {
        input = tensor80Bgr;
      } else if (fullImage != null && box != null) {
        input = _cropImageScaled80Bgr(fullImage, box, scale: 2.7);
      } else if (faceCrop != null) {
        final img.Image resized80 = (faceCrop.width == 80 && faceCrop.height == 80)
            ? faceCrop
            : img.copyResize(faceCrop, width: 80, height: 80, interpolation: img.Interpolation.linear);
        input = Float32List(1 * 80 * 80 * 3);
        int idx = 0;
        for (int y = 0; y < 80; y++) {
          for (int x = 0; x < 80; x++) {
            final p = resized80.getPixel(x, y);
            input[idx++] = p.b.toDouble();
            input[idx++] = p.g.toDouble();
            input[idx++] = p.r.toDouble();
          }
        }
      } else {
        return 0.0;
      }

      final inputTensor = input.reshape([1, 80, 80, 3]);
      final outputTensor = List.filled(1 * 3, 0.0).reshape([1, 3]);

      _livenessInterpreter!.run(inputTensor, outputTensor);

      final double fakeScore1 = (outputTensor[0][0] as num).toDouble();
      final double realScore = (outputTensor[0][1] as num).toDouble();
      final double fakeScore2 = (outputTensor[0][2] as num).toDouble();

      // MiniFASNet has 3 classes: [fake1, real, fake2].
      // If either fake class has a higher or equal raw score to realScore, the model
      // has explicitly classified this frame as a SPOOF/PHOTO. Fail immediately (return 0.0)!
      if (realScore <= fakeScore1 || realScore <= fakeScore2) {
        debugPrint(
          '[FaceSdkEngine] FAS Anti-Spoof: SPOOF PHOTO REJECTED (fake1=${fakeScore1.toStringAsFixed(2)}, real=${realScore.toStringAsFixed(2)}, fake2=${fakeScore2.toStringAsFixed(2)}) -> 0.0%',
        );
        return 0.0;
      }

      final double maxScore = math.max(fakeScore1, math.max(realScore, fakeScore2));
      final double expFake1 = math.exp(fakeScore1 - maxScore);
      final double expReal = math.exp(realScore - maxScore);
      final double expFake2 = math.exp(fakeScore2 - maxScore);
      final double sumExp = expFake1 + expReal + expFake2;

      double livenessScore = (sumExp > 0) ? (expReal / sumExp) : 0.0;

      // Multi-modal check: Head tilt penalty
      if (mlFace != null) {
        final double yaw = (mlFace.headEulerAngleY ?? 0.0).abs();
        final double pitch = (mlFace.headEulerAngleX ?? 0.0).abs();
        if (yaw > 22.0 || pitch > 22.0) {
          livenessScore *= 0.80;
        }

        // Multi-modal check: Eye open classification
        final double? leftEye = mlFace.leftEyeOpenProbability;
        final double? rightEye = mlFace.rightEyeOpenProbability;
        if (leftEye != null && rightEye != null) {
          if (leftEye < 0.10 && rightEye < 0.10) {
            livenessScore *= 0.50; // Both eyes closed / unnatural
          }
        }
      }

      debugPrint(
        '[FaceSdkEngine] FAS Liveness: real=${(livenessScore * 100).toStringAsFixed(2)}% '
        '(raw: real=${realScore.toStringAsFixed(2)}, fake1=${fakeScore1.toStringAsFixed(2)}, fake2=${fakeScore2.toStringAsFixed(2)})',
      );

      return livenessScore.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('[FaceSdkEngine] computeLiveness error: $e');
      return 0.0; // Fail-closed!
    }
  }

  /// Process live camera frame and match against enrolled person database.
  /// 
  /// Ultra-fast pipeline (<50ms per frame):
  /// 1. ML Kit Face Detection (~20-25ms)
  /// 2. Largest face selection (ignores tiny background passers-by)
  /// 3. Direct 112x112 square face sampling with roll compensation (~3ms)
  /// 4. Anti-spoof liveness detection using FAS MiniFASNet (~3-5ms)
  /// 5. MobileFaceNet normal + horizontally flipped embedding (mirror-invariant, ~20ms)
  /// 6. In-memory cosine similarity against enrolled templates (<1ms)
  /// 7. Only on match (both face & liveness passed): compress full-frame selfie JPEG
  Future<FaceSdkMatchResult?> processCameraFrame({
    required CameraImage cameraImage,
    required CameraDescription camera,
    required List<dynamic> enrolledPersons,
    double threshold = 0.55,
    double livenessThreshold = 0.70,
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
          liveness: 0.0,
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
        liveness: 0.0,
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

    // 2. Direct 112x112 square face crop with roll angle compensation for recognition (~3ms)
    final faceCrop112 = cropFace112(
      cameraImage,
      mlBox,
      camera.sensorOrientation,
      rollAngle: mlRoll,
    );
    final tCrop = DateTime.now().millisecondsSinceEpoch;

    // 2b. Direct 2.7x 80x80 BGR tensor for FAS Anti-Spoofing (<1ms)
    final tensor80Bgr = cropFaceScaled80Bgr(
      cameraImage,
      mlBox,
      camera.sensorOrientation,
      scale: 2.7,
    );

    // Anti-spoof liveness detection using FAS model (~3-5ms)
    final double livenessScore = await computeLiveness(
      tensor80Bgr: tensor80Bgr,
      mlFace: mlFace,
    );
    final tLive = DateTime.now().millisecondsSinceEpoch;

    // 3. Extract MobileFaceNet embeddings (Lazy flipped embedding for 2x faster performance)
    final embNormal = _extractEmbedding(faceCrop112);
    List<double>? embFlipped;
    final tEmbed = DateTime.now().millisecondsSinceEpoch;

    // 4. Compare against enrolled templates
    double maxSimilarity = -1.0;
    double maxRawSimilarity = 0.0;
    String matchedName = '';
    Uint8List? matchedEnrolledFace;

    for (final person in enrolledPersons) {
      final enrolledTemplates = person.templates as Uint8List;
      if (enrolledTemplates.length == 768) {
        // Safe buffer view handling SQLite non-zero buffer offsets and byte alignment
        final enrolledFloats = _toFloat32List(enrolledTemplates);
        final simNorm = cosineSimilarityFloats(embNormal, enrolledFloats);
        double rawSim = simNorm;

        // 1. If normal similarity is below threshold, try flipped embedding for mirror invariance
        if (rawSim < threshold) {
          embFlipped ??= _extractEmbedding(img.flipHorizontal(faceCrop112));
          final simFlip = cosineSimilarityFloats(embFlipped, enrolledFloats);
          rawSim = math.max(rawSim, simFlip);
        }

        final sim = calibrateSimilarity(rawSim);

        if (sim > maxSimilarity) {
          maxSimilarity = sim;
          maxRawSimilarity = rawSim;
          matchedName = person.name as String;
          matchedEnrolledFace = person.faceJpg as Uint8List?;
        }
      } else {
        // Enrolled template is not 768 bytes (legacy/corrupted)
        debugPrint(
          '[FaceSdkEngine] Warning: Template for "${person.name}" is ${enrolledTemplates.length} bytes (expected 768 for MobileFaceNet). Skipping.',
        );
      }
    }

    final bool isFaceMatch = maxSimilarity >= threshold;
    final bool isLive = livenessScore >= livenessThreshold;
    final bool isMatch = isFaceMatch && isLive;

    String? errorMessage;
    if (!isFaceMatch && maxSimilarity >= 0) {
      errorMessage = 'SIMILARITY_LOW';
    } else if (isFaceMatch && !isLive) {
      errorMessage = 'SPOOF_DETECTED';
    }

    final tTotal = DateTime.now().millisecondsSinceEpoch - t0;
    debugPrint(
      '[FaceSdkEngine] Result: sim=${(maxSimilarity * 100).toStringAsFixed(1)}% '
      '(raw: ${(maxRawSimilarity * 100).toStringAsFixed(1)}%, req ${(threshold * 100).toStringAsFixed(0)}%), '
      'live=${(livenessScore * 100).toStringAsFixed(1)}% '
      '(req ${(livenessThreshold * 100).toStringAsFixed(0)}%) "$matchedName" '
      'isMatch=$isMatch [Total: ${tTotal}ms | detect: ${tDetect - t0}ms, crop: ${tCrop - tDetect}ms, live: ${tLive - tCrop}ms, embed: ${tEmbed - tLive}ms]',
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
      liveness: livenessScore,
      yaw: mlYaw,
      roll: mlRoll,
      pitch: mlPitch,
      boundingBox: mlBox,
      liveFaceJpg: liveFaceJpg,
      fullFrameJpg: fullFrameJpg,
      enrolledFaceJpg: matchedEnrolledFace,
      frameWidth: uprightWidth,
      frameHeight: uprightHeight,
      errorMessage: errorMessage,
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

      // Consistent MobileFaceNet extraction for camera enrollment (768 bytes)
      final embedding = extractEmbedding(faceCrop);
      final templates = Float32List.fromList(embedding).buffer.asUint8List();

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
    _livenessInterpreter?.close();
    _isInitialized = false;
  }
}
