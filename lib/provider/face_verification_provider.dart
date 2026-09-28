// ignore_for_file: constant_identifier_names, prefer_final_fields

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/face_registation/face_punch_state.dart';
import 'package:tax_hrm/page/face_registation/face_recognition_service.dart';
import 'package:screen_brightness/screen_brightness.dart';

class FaceVerificationProvider extends ChangeNotifier {
  final FaceRecognitionService _recognitionService = FaceRecognitionService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // State
  FaceProcessState currentState = FaceProcessState.idle;
  FaceErrorReason currentError = FaceErrorReason.none;
  double lastSimilarity = 0.0;

  // Multi-step Enrollment
  int enrollmentStep = 0;
  List<List<double>> _enrollmentEmbeddings = [];

  // Camera
  CameraController? cameraController;
  bool isProcessingFrame = false;
  Stopwatch _stabilityStopwatch = Stopwatch();

  // Persistent Settings
  bool isFacePunchEnabled = false;
  bool isEnrolled = false;
  String? registeredFaceTemplate;

  // Sync state after enrollment
  bool isSyncing = false;
  bool hasSyncError = false;

  // Constants
  static const double THRESHOLD =
      0.65; // Cosine similarity threshold for MobileFaceNet
  final String _templateKeyPrefix = 'face_template_v2_'; // Append empId

  // Logs
  List<String> logs = [];

  void _log(String message) {
    logs.add("${DateTime.now().toIso8601String().split('T').last}: $message");
    debugPrint("[FaceVerificationProvider] $message");
    // Notify listeners if needed for UI, but usually not necessary unless debugging
  }


  Future<Map<String, String>> getAllEnrolledFaces() async {
    Map<String, String> allValues = {};
    try {
      allValues = await _secureStorage.readAll();
    } catch (e) {
      _log("Secure storage readAll failed (likely corrupted key). Deleting all data. Error: $e");
      try {
        await _secureStorage.deleteAll();
      } catch (_) {}
    }

    final faces = <String, String>{};
    allValues.forEach((key, value) {
      if (key.startsWith(_templateKeyPrefix)) {
        String empId = key.substring(_templateKeyPrefix.length);
        faces[empId] = value;
      }
    });
    return faces;
  }

  void _setState(
    FaceProcessState state, {
    FaceErrorReason error = FaceErrorReason.none,
  }) {
    if (currentState == state && currentError == error) return;
    currentState = state;
    currentError = error;
    _log("State changed to: $state, Error: $error");
    notifyListeners();
  }

  // ---- CAMERA MANAGEMENT ----
  Future<void> initCamera({required bool forEnrollment}) async {
    _setState(FaceProcessState.initializing);
    _log("Initializing camera. For enrollment: $forEnrollment");
    enrollmentStep = 0;
    _enrollmentEmbeddings.clear();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setState(
          FaceProcessState.failed,
          error: FaceErrorReason.cameraUnavailable,
        );
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await cameraController!.initialize();
      _setState(FaceProcessState.idle);

      _log("Camera initialized. Starting image stream.");
      _stabilityStopwatch.reset();

      // Maximize screen brightness for face detection
      try {
        await ScreenBrightness().setScreenBrightness(1.0);
      } catch (e) {
        _log("Could not set screen brightness: $e");
      }

      bool firstFrame = true;
      cameraController!.startImageStream((image) {
        if (firstFrame) {
          _log(
            "Received first frame from camera! Size: ${image.width}x${image.height}",
          );
          firstFrame = false;
        }
        
        if (!isProcessingFrame) {
          isProcessingFrame = true;
          if (forEnrollment) {
            _processEnrollmentFrame(image, frontCamera);
          } else {
            _processVerificationFrame(image, frontCamera);
          }
        }
      });
    } catch (e) {
      _log("Camera init error: $e");
      _setState(
        FaceProcessState.failed,
        error: FaceErrorReason.cameraUnavailable,
      );
    }
  }

  Future<void> stopCamera() async {
    _log("Stopping camera");
    final controller = cameraController;
    cameraController = null;
    isProcessingFrame = false;
    _stabilityStopwatch.stop();
    _setState(FaceProcessState.idle);

    // Restore original screen brightness
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      _log("Could not reset screen brightness: $e");
    }

    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }
  }

  void retry() {
    _log("Retry called");
    enrollmentStep = 0;
    _enrollmentEmbeddings.clear();
    _setState(FaceProcessState.idle);
  }

  // ---- ENROLLMENT FLOW ----

  Future<void> _processEnrollmentFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (currentState == FaceProcessState.success ||
        currentState == FaceProcessState.failed) {
      isProcessingFrame = false;
      return;
    }

    try {
      _setState(FaceProcessState.detectingFace);
      final inputImage = _recognitionService.convertCameraImageToInputImage(
        image,
        camera,
      );
      if (inputImage == null) {
        isProcessingFrame = false;
        return;
      }
      final faces = await _recognitionService.detectFaces(inputImage);

      final error = _recognitionService.validateFaceQuality(
        faces,
        Size(image.width.toDouble(), image.height.toDouble()),
      );
      if (error != null) {
        _stabilityStopwatch.stop();
        _setState(
          FaceProcessState.detectingFace,
          error: _parseErrorReason(error),
        );
        isProcessingFrame = false;
        return;
      }

      final face = faces.first;
      
      _setState(FaceProcessState.checkingLiveness);
      bool isLive = await _recognitionService.checkLiveness(
        image,
        face,
        camera,
      );
      if (!isLive) {
        _stabilityStopwatch.stop();
        _setState(
          FaceProcessState.detectingFace,
          error: FaceErrorReason.spoofDetected,
        );
        isProcessingFrame = false;
        return;
      }

      _setState(FaceProcessState.faceDetected);

      if (!_stabilityStopwatch.isRunning) _stabilityStopwatch.start();

      int requiredDelay = enrollmentStep == 0 ? 500 : 1000;
      if (_stabilityStopwatch.elapsedMilliseconds < requiredDelay) {
        // Wait for stability / movement validation
        isProcessingFrame = false;
        return;
      }

      _setState(FaceProcessState.recognizing);
      final embedding = await _recognitionService.generateFaceEmbedding(
        image,
        face,
        camera,
      );
      if (embedding == null) {
        _setState(
          FaceProcessState.failed,
          error: FaceErrorReason.modelInitFailed,
        );
        return;
      }

      _enrollmentEmbeddings.add(embedding);
      enrollmentStep++;

      _log("Enrollment step $enrollmentStep completed successfully.");

      if (enrollmentStep < 3) {
        _log("Waiting for next enrollment step...");
        // We need more steps. Reset the stopwatch to wait 500ms for the next frame.
        _stabilityStopwatch.reset();
        _stabilityStopwatch.start();
        // Force state update to notify UI of step progress
        notifyListeners();
        return; // Exit and process next frames
      }

      _log("All 3 enrollment steps completed. Formatting to JSON...");

      String jsonStr = _recognitionService.embeddingToBase64(
        _enrollmentEmbeddings.first,
      );

      // Store the registered template to be accessed by UI/APIs
      registeredFaceTemplate = jsonStr;
      isEnrolled = true;

      // Save the JSON string to secure storage for the current logged-in user if available in global context,
      // but remove SharedPreferences dependency
      try {
        String empId = curentUser?['Id']?.toString() ?? 'UNKNOWN';
        if (empId != 'UNKNOWN') {
          _log("Saving embeddings JSON to secure storage for user: $empId");
          await _secureStorage.write(
            key: _templateKeyPrefix + empId,
            value: jsonStr,
          );
        }
      } catch (e) {
        _log("Failed to save to secure storage: $e");
      }

      _log("Face successfully registered.");
      isSyncing =
          true; // Show loader immediately on success screen while API sync runs
      _setState(FaceProcessState.success);
      stopCamera();
    } catch (e) {
      _log("Enrollment frame error: $e");
    } finally {
      isProcessingFrame = false;
    }
  }

  // ---- VERIFICATION FLOW ----
  int _consecutiveLiveFrames = 0;

  Future<void> _processVerificationFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (currentState == FaceProcessState.success ||
        currentState == FaceProcessState.failed ||
        currentState == FaceProcessState.waitingForConfirmation ||
        currentState == FaceProcessState.punching) {
      isProcessingFrame = false;
      return;
    }

    try {
      _setState(FaceProcessState.detectingFace);
      final inputImage = _recognitionService.convertCameraImageToInputImage(
        image,
        camera,
      );
      if (inputImage == null) {
        isProcessingFrame = false;
        return;
      }
      final faces = await _recognitionService.detectFaces(inputImage);

      final error = _recognitionService.validateFaceQuality(
        faces,
        Size(image.width.toDouble(), image.height.toDouble()),
      );
      if (error != null) {
        _consecutiveLiveFrames = 0;
        _stabilityStopwatch.stop();
        _setState(
          FaceProcessState.detectingFace,
          error: _parseErrorReason(error),
        );
        isProcessingFrame = false;
        return;
      }

      final face = faces.first;
      _setState(FaceProcessState.checkingLiveness);

      if (!_stabilityStopwatch.isRunning) _stabilityStopwatch.start();
      if (_stabilityStopwatch.elapsedMilliseconds < 500) {
        isProcessingFrame = false;
        return; // Need stability
      }

      bool isLive = await _recognitionService.checkLiveness(
        image,
        face,
        camera,
      );
      if (!isLive) {
        _consecutiveLiveFrames = 0;
        _setState(
          FaceProcessState.failed,
          error: FaceErrorReason.spoofDetected,
        );
        stopCamera();
        return;
      }

      _consecutiveLiveFrames++;
      if (_consecutiveLiveFrames < 3) {
        isProcessingFrame = false;
        return; // Require 3 consecutive live frames
      }

      // Liveness passed, do recognition
      _setState(FaceProcessState.recognizing);

      String empId = curentUser?['Id']?.toString() ?? 'UNKNOWN';
      String? storedStr;
      
      try {
        storedStr = await _secureStorage.read(
          key: _templateKeyPrefix + empId,
        );
      } catch (e) {
        _log("Secure storage read failed (likely corrupted key). Error: $e");
        try {
          await _secureStorage.deleteAll();
        } catch (_) {}
      }

      if (storedStr == null) {
        _setState(
          FaceProcessState.failed,
          error: FaceErrorReason.templateMissing,
        );
        stopCamera();
        return;
      }

      List<List<double>> storedEmbeddings = [];
      try {
        final decoded = jsonDecode(storedStr);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is List) {
              storedEmbeddings.add(
                item.map((e) => (e as num).toDouble()).toList(),
              );
            } else if (item is String) {
              storedEmbeddings.add(
                _recognitionService.embeddingFromBase64(item),
              );
            }
          }
        } else if (decoded is Map<String, dynamic> &&
            decoded.containsKey("faceEmbeddings")) {
          List<dynamic> list = decoded["faceEmbeddings"];
          for (var item in list) {
            if (item is List) {
              storedEmbeddings.add(
                item.map((e) => (e as num).toDouble()).toList(),
              );
            } else if (item is String) {
              storedEmbeddings.add(
                _recognitionService.embeddingFromBase64(item),
              );
            }
          }
        }
      } catch (e) {
        // Fallback to legacy base64 format or comma-separated base64 format
        try {
          if (storedStr.contains(',')) {
            final parts = storedStr.split(',');
            for (var part in parts) {
              storedEmbeddings.add(
                _recognitionService.embeddingFromBase64(part),
              );
            }
          } else {
            storedEmbeddings.add(
              _recognitionService.embeddingFromBase64(storedStr),
            );
          }
        } catch (e2) {
          _setState(
            FaceProcessState.failed,
            error: FaceErrorReason.templateMissing,
          );
          stopCamera();
          return;
        }
      }

      if (storedEmbeddings.isEmpty) {
        _setState(
          FaceProcessState.failed,
          error: FaceErrorReason.templateMissing,
        );
        stopCamera();
        return;
      }

      final liveEmbedding = await _recognitionService.generateFaceEmbedding(
        image,
        face,
        camera,
      );

      if (liveEmbedding == null) {
        _setState(
          FaceProcessState.failed,
          error: FaceErrorReason.modelInitFailed,
        );
        stopCamera();
        return;
      }

      double maxSimilarity = -1.0;
      for (var stored in storedEmbeddings) {
        double similarity = _recognitionService.calculateCosineSimilarity(
          liveEmbedding,
          stored,
        );
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
        }
      }

      lastSimilarity = maxSimilarity;
      _log(
        "Max Similarity across ${storedEmbeddings.length} templates: $maxSimilarity",
      );

      if (maxSimilarity >= THRESHOLD) {
        _setState(FaceProcessState.waitingForConfirmation);
        // We do not stop camera here immediately so preview can freeze, but we stop processing frames.
      } else {
        _setState(FaceProcessState.failed, error: FaceErrorReason.mismatch);
        stopCamera();
      }
    } catch (e) {
      _log("Verification frame error: $e");
    } finally {
      isProcessingFrame = false;
    }
  }

  /// Verify face using a static image file (e.g. taken by another camera controller)
  Future<bool> verifyStaticFile(File imageFile, String storedStr) async {
    try {
      await _recognitionService.initialize();
      _log("Starting static file face verification...");
      List<List<double>> storedEmbeddings = [];

      try {
        final decoded = jsonDecode(storedStr);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is List) {
              storedEmbeddings.add(
                item.map((e) => (e as num).toDouble()).toList(),
              );
            } else if (item is String) {
              storedEmbeddings.add(
                _recognitionService.embeddingFromBase64(item),
              );
            }
          }
        } else if (decoded is Map<String, dynamic> &&
            decoded.containsKey("faceEmbeddings")) {
          List<dynamic> list = decoded["faceEmbeddings"];
          for (var item in list) {
            if (item is List) {
              storedEmbeddings.add(
                item.map((e) => (e as num).toDouble()).toList(),
              );
            } else if (item is String) {
              storedEmbeddings.add(
                _recognitionService.embeddingFromBase64(item),
              );
            }
          }
        } else {
          storedEmbeddings.add(
            _recognitionService.embeddingFromBase64(storedStr),
          );
        }
      } catch (e) {
        if (storedStr.contains(',')) {
          final parts = storedStr.split(',');
          for (var part in parts) {
            storedEmbeddings.add(_recognitionService.embeddingFromBase64(part));
          }
        } else {
          storedEmbeddings.add(
            _recognitionService.embeddingFromBase64(storedStr),
          );
        }
      }

      if (storedEmbeddings.isEmpty) {
        _log("Failed: storedEmbeddings is empty");
        return false;
      }

      final liveEmbedding = await _recognitionService
          .generateFaceEmbeddingFromFile(imageFile);
      if (liveEmbedding == null) {
        _log(
          "Failed: Could not generate embedding from file (no face or error)",
        );
        return false;
      }

      double maxSimilarity = -1.0;
      for (var stored in storedEmbeddings) {
        double similarity = _recognitionService.calculateCosineSimilarity(
          liveEmbedding,
          stored,
        );
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
        }
      }

      lastSimilarity = maxSimilarity;
      _log("Static File Max Similarity: $maxSimilarity");

      return maxSimilarity >= THRESHOLD;
    } catch (e) {
      _log("Static file verification error: $e");
      return false;
    }
  }

  FaceErrorReason _parseErrorReason(String err) {
    switch (err) {
      case 'noFace':
        return FaceErrorReason.noFace;
      case 'multipleFaces':
        return FaceErrorReason.multipleFaces;
      case 'moveCloser':
        return FaceErrorReason.moveCloser;
      case 'straightenFace':
        return FaceErrorReason.straightenFace;
      default:
        return FaceErrorReason.unexpected;
    }
  }

  void cancelPunch() {
    _log("Punch cancelled");
    stopCamera();
  }

  /// Runs after a successful face enrollment:
  /// 1. Updates FaceRegisterId via the Employee Edit API.
  /// 2. Re-fetches user data via /api/Token/EmpLogin.
  /// 3. Saves the fresh data to SharedPreferences and updates curentUser in memory.

  @override
  void dispose() {
    _recognitionService.dispose();
    stopCamera();
    super.dispose();
  }
}
