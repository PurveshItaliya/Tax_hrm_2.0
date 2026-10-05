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
  final FaceRecognitionService recognitionService = FaceRecognitionService();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  int _cameraSessionId = 0;

  // State
  FaceProcessState currentState = FaceProcessState.idle;
  FaceErrorReason currentError = FaceErrorReason.none;
  double lastSimilarity = 0.0;

  // Multi-step Enrollment
  int enrollmentStep = 0;
  List<List<double>> enrollmentEmbeddings = [];

  // Camera
  CameraController? cameraController;
  bool isProcessingFrame = false;
  Stopwatch stabilityStopwatch = Stopwatch();

  // Persistent Settings
  bool isFacePunchEnabled = false;
  bool isEnrolled = false;
  String? registeredFaceTemplate;

  // Sync state after enrollment
  bool isSyncing = false;
  bool hasSyncError = false;

  // Constants
  static const double THRESHOLD =
      0.60; // Cosine similarity threshold for MobileFaceNet
  final String templateKeyPrefix = 'face_template_v2_'; // Append empId

  // Logs
  List<String> logs = [];

  void log(String message) {
    logs.add("${DateTime.now().toIso8601String().split('T').last}: $message");
    debugPrint("[FaceVerificationProvider] $message");
    // Notify listeners if needed for UI, but usually not necessary unless debugging
  }


  Future<Map<String, String>> getAllEnrolledFaces() async {
    Map<String, String> allValues = {};
    try {
      allValues = await secureStorage.readAll();
    } catch (e) {
      log("Secure storage readAll failed (likely corrupted key). Deleting all data. Error: $e");
      try {
        await secureStorage.deleteAll();
      } catch (_) {}
    }

    final faces = <String, String>{};
    allValues.forEach((key, value) {
      if (key.startsWith(templateKeyPrefix)) {
        String empId = key.substring(templateKeyPrefix.length);
        faces[empId] = value;
      }
    });
    return faces;
  }

  void setState(
    FaceProcessState state, {
    FaceErrorReason error = FaceErrorReason.none,
  }) {
    if (currentState == state && currentError == error) return;
    currentState = state;
    currentError = error;
    log("State changed to: $state, Error: $error");
    notifyListeners();
  }

  // ---- CAMERA MANAGEMENT ----
  Future<void> initCamera({required bool forEnrollment}) async {
    _cameraSessionId++;
    final int currentSession = _cameraSessionId;

    isProcessingFrame = false;
    setState(FaceProcessState.initializing);
    log("Initializing camera. For enrollment: $forEnrollment");
    
    await recognitionService.initialize();
    
    if (currentSession != _cameraSessionId) {
      log("initCamera aborted: session invalidated during model initialization.");
      return;
    }
    
    enrollmentStep = 0;
    enrollmentEmbeddings.clear();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(
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
      
      if (currentSession != _cameraSessionId) {
        log("initCamera aborted: session invalidated during camera initialization.");
        await cameraController!.dispose();
        cameraController = null;
        return;
      }
      
      setState(FaceProcessState.idle);

      log("Camera initialized. Starting image stream.");
      stabilityStopwatch.reset();

      // Maximize screen brightness for face detection
      try {
        await ScreenBrightness().setScreenBrightness(1.0);
      } catch (e) {
        log("Could not set screen brightness: $e");
      }

      bool firstFrame = true;
      cameraController!.startImageStream((image) {
        if (firstFrame) {
          log(
            "Received first frame from camera! Size: ${image.width}x${image.height}",
          );
          firstFrame = false;
        }
        
        if (!isProcessingFrame) {
          isProcessingFrame = true;
          if (forEnrollment) {
            processEnrollmentFrame(image, frontCamera);
          } else {
            processVerificationFrame(image, frontCamera);
          }
        }
      });
    } catch (e) {
      log("Camera init error: $e");
      setState(
        FaceProcessState.failed,
        error: FaceErrorReason.cameraUnavailable,
      );
    }
  }

  Future<void> stopCamera() async {
    _cameraSessionId++; // Invalidate any ongoing initCamera sessions
    log("Stopping camera");
    final controller = cameraController;
    cameraController = null;
    isProcessingFrame = false;
    stabilityStopwatch.stop();
    setState(FaceProcessState.idle);

    // Restore original screen brightness
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      log("Could not reset screen brightness: $e");
    }

    if (controller != null) {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      await controller.dispose();
    }
  }

  void retry() {
    log("Retry called");
    enrollmentStep = 0;
    enrollmentEmbeddings.clear();
    setState(FaceProcessState.idle);
  }

  // ---- ENROLLMENT FLOW ----

  Future<void> processEnrollmentFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (currentState == FaceProcessState.success ||
        currentState == FaceProcessState.failed) {
      isProcessingFrame = false;
      return;
    }

    try {
      final inputImage = recognitionService.convertCameraImageToInputImage(
        image,
        camera,
      );
      if (inputImage == null) {
        isProcessingFrame = false;
        return;
      }
      final faces = await recognitionService.detectFaces(inputImage);

      final error = recognitionService.validateFaceQuality(
        faces,
        image,
        camera,
      );
      if (error != null) {
        stabilityStopwatch.stop();
        setState(
          FaceProcessState.detectingFace,
          error: parseErrorReason(error),
        );
        isProcessingFrame = false;
        return;
      }

      final face = faces.first;
      
      setState(FaceProcessState.checkingLiveness);
      bool isLive = await recognitionService.checkLiveness(
        image,
        face,
        camera,
      );
      if (!isLive) {
        stabilityStopwatch.stop();
        setState(
          FaceProcessState.detectingFace,
          error: FaceErrorReason.spoofDetected,
        );
        isProcessingFrame = false;
        return;
      }

      setState(FaceProcessState.faceDetected);

      if (!stabilityStopwatch.isRunning) stabilityStopwatch.start();

      int requiredDelay = enrollmentStep == 0 ? 500 : 1000;
      if (stabilityStopwatch.elapsedMilliseconds < requiredDelay) {
        // Wait for stability / movement validation
        isProcessingFrame = false;
        return;
      }

      setState(FaceProcessState.recognizing);
      final embedding = await recognitionService.generateFaceEmbedding(
        image,
        face,
        camera,
      );
      if (embedding == null) {
        setState(
          FaceProcessState.failed,
          error: FaceErrorReason.modelInitFailed,
        );
        return;
      }

      enrollmentEmbeddings.add(embedding);
      enrollmentStep++;

      log("Enrollment step $enrollmentStep completed successfully.");

      if (enrollmentStep < 3) {
        log("Waiting for next enrollment step...");
        // We need more steps. Reset the stopwatch to wait 500ms for the next frame.
        stabilityStopwatch.reset();
        stabilityStopwatch.start();
        // Force state update to notify UI of step progress
        notifyListeners();
        return; // Exit and process next frames
      }

      log("All 3 enrollment steps completed. Averaging embeddings...");
      
      final averagedEmbedding = recognitionService.averageEmbeddings(enrollmentEmbeddings);
      String finalString = recognitionService.embeddingToBase64(averagedEmbedding);

      // Store the registered template to be accessed by UI/APIs
      registeredFaceTemplate = finalString;
      isEnrolled = true;

      // Save the JSON string to secure storage for the current logged-in user if available in global context,
      // but remove SharedPreferences dependency
      try {
        String empId = curentUser?['Id']?.toString() ?? 'UNKNOWN';
        if (empId != 'UNKNOWN') {
          log("Saving embeddings JSON to secure storage for user: $empId");
          await secureStorage.write(
            key: templateKeyPrefix + empId,
            value: finalString,
          );
        }
      } catch (e) {
        log("Failed to save to secure storage: $e");
      }

      log("Face successfully registered.");
      isSyncing =
          true; // Show loader immediately on success screen while API sync runs
      setState(FaceProcessState.success);
      stopCamera();
    } catch (e) {
      log("Enrollment frame error: $e");
    } finally {
      isProcessingFrame = false;
    }
  }

  // ---- VERIFICATION FLOW ----
  int consecutiveLiveFrames = 0;

  Future<void> processVerificationFrame(
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
      final inputImage = recognitionService.convertCameraImageToInputImage(
        image,
        camera,
      );
      if (inputImage == null) {
        isProcessingFrame = false;
        return;
      }
      final faces = await recognitionService.detectFaces(inputImage);

      final error = recognitionService.validateFaceQuality(
        faces,
        image,
        camera,
      );
      if (error != null) {
        consecutiveLiveFrames = 0;
        stabilityStopwatch.stop();
        setState(
          FaceProcessState.detectingFace,
          error: parseErrorReason(error),
        );
        isProcessingFrame = false;
        return;
      }

      final face = faces.first;
      setState(FaceProcessState.checkingLiveness);

      if (!stabilityStopwatch.isRunning) stabilityStopwatch.start();
      if (stabilityStopwatch.elapsedMilliseconds < 500) {
        isProcessingFrame = false;
        return; // Need stability
      }

      bool isLive = await recognitionService.checkLiveness(
        image,
        face,
        camera,
      );
      if (!isLive) {
        consecutiveLiveFrames = 0;
        setState(
          FaceProcessState.failed,
          error: FaceErrorReason.spoofDetected,
        );
        stopCamera();
        return;
      }

      consecutiveLiveFrames++;
      if (consecutiveLiveFrames < 3) {
        isProcessingFrame = false;
        return; // Require 3 consecutive live frames
      }

      // Liveness passed, do recognition
      setState(FaceProcessState.recognizing);

      String empId = curentUser?['Id']?.toString() ?? 'UNKNOWN';
      String? storedStr;
      
      try {
        storedStr = await secureStorage.read(
          key: templateKeyPrefix + empId,
        );
      } catch (e) {
        log("Secure storage read failed (likely corrupted key). Error: $e");
        try {
          await secureStorage.deleteAll();
        } catch (_) {}
      }

      if (storedStr == null) {
        setState(
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
                recognitionService.embeddingFromBase64(item),
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
                recognitionService.embeddingFromBase64(item),
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
                recognitionService.embeddingFromBase64(part),
              );
            }
          } else {
            storedEmbeddings.add(
              recognitionService.embeddingFromBase64(storedStr),
            );
          }
        } catch (e2) {
          setState(
            FaceProcessState.failed,
            error: FaceErrorReason.templateMissing,
          );
          stopCamera();
          return;
        }
      }

      if (storedEmbeddings.isEmpty) {
        setState(
          FaceProcessState.failed,
          error: FaceErrorReason.templateMissing,
        );
        stopCamera();
        return;
      }

      final liveEmbedding = await recognitionService.generateFaceEmbedding(
        image,
        face,
        camera,
      );

      if (liveEmbedding == null) {
        setState(
          FaceProcessState.failed,
          error: FaceErrorReason.modelInitFailed,
        );
        stopCamera();
        return;
      }

      double maxSimilarity = -1.0;
      for (var stored in storedEmbeddings) {
        double similarity = recognitionService.calculateCosineSimilarity(
          liveEmbedding,
          stored,
        );
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
        }
      }

      lastSimilarity = maxSimilarity;
      log(
        "Max Similarity across ${storedEmbeddings.length} templates: $maxSimilarity",
      );

      if (maxSimilarity >= THRESHOLD) {
        setState(FaceProcessState.waitingForConfirmation);
        // We do not stop camera here immediately so preview can freeze, but we stop processing frames.
      } else {
        setState(FaceProcessState.failed, error: FaceErrorReason.mismatch);
        stopCamera();
      }
    } catch (e) {
      log("Verification frame error: $e");
    } finally {
      isProcessingFrame = false;
    }
  }

  /// Verify face using a static image file (e.g. taken by another camera controller)
  Future<bool> verifyStaticFile(File imageFile, String storedStr) async {
    try {
      await recognitionService.initialize();
      log("Starting static file face verification...");
      List<List<double>> storedEmbeddings = [];

      try {
        await recognitionService.initialize();
        final decoded = jsonDecode(storedStr);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is List) {
              storedEmbeddings.add(
                item.map((e) => (e as num).toDouble()).toList(),
              );
            } else if (item is String) {
              storedEmbeddings.add(
                recognitionService.embeddingFromBase64(item),
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
                recognitionService.embeddingFromBase64(item),
              );
            }
          }
        } else {
          storedEmbeddings.add(
            recognitionService.embeddingFromBase64(storedStr),
          );
        }
      } catch (e) {
        if (storedStr.contains(',')) {
          final parts = storedStr.split(',');
          for (var part in parts) {
            storedEmbeddings.add(recognitionService.embeddingFromBase64(part));
          }
        } else {
          storedEmbeddings.add(
            recognitionService.embeddingFromBase64(storedStr),
          );
        }
      }

      if (storedEmbeddings.isEmpty) {
        log("Failed: storedEmbeddings is empty");
        return false;
      }

      final liveEmbedding = await recognitionService
          .generateFaceEmbeddingFromFile(imageFile);
      if (liveEmbedding == null) {
        log(
          "Failed: Could not generate embedding from file (no face or error)",
        );
        return false;
      }

      double maxSimilarity = -1.0;
      for (var stored in storedEmbeddings) {
        double similarity = recognitionService.calculateCosineSimilarity(
          liveEmbedding,
          stored,
        );
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
        }
      }

      lastSimilarity = maxSimilarity;
      log("Static File Max Similarity: $maxSimilarity");

      return maxSimilarity >= THRESHOLD;
    } catch (e) {
      log("Static file verification error: $e");
      return false;
    }
  }

  /// Verify face live using a CameraController stream (for Punch Verification)
  Future<bool> verifyLiveStream(CameraController controller, String storedStr) async {
    log("Starting live stream face verification...");
    await recognitionService.initialize();
    
    List<List<double>> storedEmbeddings = [];
    try {
      final decoded = jsonDecode(storedStr);
      if (decoded is List) {
        for (var item in decoded) {
          if (item is List) {
            storedEmbeddings.add(item.map((e) => (e as num).toDouble()).toList());
          } else if (item is String) {
            storedEmbeddings.add(recognitionService.embeddingFromBase64(item));
          }
        }
      } else if (decoded is Map<String, dynamic> && decoded.containsKey("faceEmbeddings")) {
        List<dynamic> list = decoded["faceEmbeddings"];
        for (var item in list) {
          if (item is List) {
            storedEmbeddings.add(item.map((e) => (e as num).toDouble()).toList());
          } else if (item is String) {
            storedEmbeddings.add(recognitionService.embeddingFromBase64(item));
          }
        }
      } else {
        storedEmbeddings.add(recognitionService.embeddingFromBase64(storedStr));
      }
    } catch (e) {
      if (storedStr.contains(',')) {
        for (var part in storedStr.split(',')) {
          storedEmbeddings.add(recognitionService.embeddingFromBase64(part));
        }
      } else {
        storedEmbeddings.add(recognitionService.embeddingFromBase64(storedStr));
      }
    }

    if (storedEmbeddings.isEmpty) return false;

    Completer<bool> completer = Completer<bool>();
    bool isProcessing = false;
    Stopwatch stability = Stopwatch()..start();
    
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      
      await controller.startImageStream((image) async {
        if (isProcessing || completer.isCompleted) return;
        isProcessing = true;
        
        try {
           final inputImage = recognitionService.convertCameraImageToInputImage(image, controller.description);
           if (inputImage == null) { isProcessing = false; return; }
           
           final faces = await recognitionService.detectFaces(inputImage);
           final error = recognitionService.validateFaceQuality(faces, image, controller.description);
           if (error != null) {
              stability.reset();
              stability.start();
              isProcessing = false;
              return;
           }
           
           bool isLive = await recognitionService.checkLiveness(image, faces.first, controller.description);
           if (!isLive) {
              // Continuous scan: Ignore this frame and wait for the next one
              return;
           }
           
           final liveEmbedding = await recognitionService.generateFaceEmbedding(image, faces.first, controller.description);
           if (liveEmbedding == null) {
              // Continuous scan: Ignore this frame and wait for the next one
              return;
           }
           
           double maxSimilarity = -1.0;
           for (var stored in storedEmbeddings) {
             double similarity = recognitionService.calculateCosineSimilarity(liveEmbedding, stored);
             if (similarity > maxSimilarity) maxSimilarity = similarity;
           }
           
           if (maxSimilarity >= THRESHOLD) {
              if (!completer.isCompleted) completer.complete(true);
           } else {
              // Continuous scan: Do NOT instantly fail. Let it scan the next frame.
              // It will automatically timeout and fail if 15 seconds pass without a match.
           }
        } catch (e) {
           log("Live stream verification frame error: $e");
        } finally {
           isProcessing = false;
        }
      });
      
      // Wait for result with a timeout (e.g. 15 seconds)
      bool result = await completer.future.timeout(const Duration(seconds: 15), onTimeout: () => false);
      return result;
    } catch (e) {
      log("verifyLiveStream error: $e");
      return false;
    } finally {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    }
  }

  FaceErrorReason parseErrorReason(String err) {
    switch (err) {
      case 'noFace':
        return FaceErrorReason.noFace;
      case 'multipleFaces':
        return FaceErrorReason.multipleFaces;
      case 'moveCloser':
        return FaceErrorReason.moveCloser;
      case 'straightenFace':
        return FaceErrorReason.straightenFace;
      case 'alignFace':
        return FaceErrorReason.alignFace;
      default:
        return FaceErrorReason.unexpected;
    }
  }

  void cancelPunch() {
    log("Punch cancelled");
    stopCamera();
  }

  /// Runs after a successful face enrollment:
  /// 1. Updates FaceRegisterId via the Employee Edit API.
  /// 2. Re-fetches user data via /api/Token/EmpLogin.
  /// 3. Saves the fresh data to SharedPreferences and updates curentUser in memory.

  @override
  void dispose() {
    recognitionService.dispose();
    stopCamera();
    super.dispose();
  }
}
