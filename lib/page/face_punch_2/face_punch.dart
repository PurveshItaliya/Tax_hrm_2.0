// ignore_for_file: invalid_return_type_for_catch_error, deprecated_member_use, strict_top_level_inference, use_build_context_synchronously, unused_element

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/page/face_punch_2/face_sdk_engine.dart';
import 'package:tax_hrm/page/face_punch_2/face_sdk_verify_screen.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/selfie_punch_provider.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/services/permission_flow_service.dart';
import 'package:tax_hrm/services/developer_mode_service.dart';
import 'package:tax_hrm/services/remote_config_services.dart';
import 'package:tax_hrm/services/punch_performance_tracker.dart';
import 'package:tax_hrm/services/face_registration_sync_service.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/loadersshow.dart';
import 'package:tax_hrm/widigets/punch_sync_summary_dialog.dart';
import 'package:tax_hrm/widigets/single_run_gif.dart';

enum FaceScanStatus {
  idle,
  scanning,
  success,
  failed,
  multipleFaces,
}

class FaceVerificationAttemptResult {
  final FaceSdkMatchResult? matchResult;
  final double bestSimilarity;
  final int framesAnalyzed;
  final String? failureReason;
  final bool isMultipleFaces;

  const FaceVerificationAttemptResult({
    this.matchResult,
    this.bestSimilarity = 0.0,
    this.framesAnalyzed = 0,
    this.failureReason,
    this.isMultipleFaces = false,
  });

  bool get isSuccess => matchResult != null && matchResult!.isMatch && !isMultipleFaces;
}

class FacePunchScreen extends StatefulWidget {
  final bool isFromWidget;
  const FacePunchScreen({super.key, this.isFromWidget = false});

  @override
  State<FacePunchScreen> createState() => _FacePunchScreenState();
}

class _FacePunchScreenState extends State<FacePunchScreen>
    with WidgetsBindingObserver {
  // ── Guards ────────────────────────────────────────────────────────────────
  bool _isFlowRunning = false; // true while PermissionFlowService is active
  bool _permissionsChecked = false;
  bool _wentToSettings = false;
  bool _hasAutoPunchedFromWidget = false;

  // ── Face Enrollment & Master Sync State ───────────────────────────────────
  bool? _isFaceEnrolled;
  bool _isCheckingFaceStatus = false;
  bool _hasShownFaceRegisterPrompt = false;

  // ── Fast Camera Auto-Restart State ──────────────────────────────────────────
  int _cameraAutoRestartAttempts = 0;
  DateTime? _lastCameraAutoRestartTime;

  void _triggerFastCameraAutoRestart() {
    final now = DateTime.now();
    if (_lastCameraAutoRestartTime != null &&
        now.difference(_lastCameraAutoRestartTime!).inMilliseconds < 1000) {
      return;
    }
    _lastCameraAutoRestartTime = now;
    if (_cameraAutoRestartAttempts < 5) {
      _cameraAutoRestartAttempts++;
      debugPrint('[FacePunch] FAST CAMERA AUTO-RESTART triggered (attempt $_cameraAutoRestartAttempts/5)...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !selfiePunchProvider.cameraisLoading &&
            !selfiePunchProvider.isCameraReady) {
          selfiePunchProvider.startCamera(0);
        }
      });
    }
  }

  // ── On-Demand Face Verification State ─────────────────────────────────────
  FaceScanStatus _scanStatus = FaceScanStatus.idle;
  File? _capturedFaceFile;
  String? _cameraBoxMessage;
  Timer? _cameraBoxMessageTimer;
  double _identifyThreshold = 0.70;
  double _livenessThreshold = 0.70;

  void _setCameraBoxMessage(String message, {Duration duration = const Duration(seconds: 3)}) {
    _cameraBoxMessageTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _cameraBoxMessage = message;
    });
    _cameraBoxMessageTimer = Timer(duration, () {
      if (mounted && _cameraBoxMessage == message) {
        setState(() {
          _cameraBoxMessage = null;
        });
      }
    });
  }

  Widget _buildStatusGif() {
    switch (_scanStatus) {
      case FaceScanStatus.scanning:
        return const SingleRunGif(
          key: ValueKey('face_scanning'),
          assetPath: 'assets/lottie/face_scanning.gif',
          width: 130,
          height: 130,
          fit: BoxFit.contain,
        );
      case FaceScanStatus.success:
        return const SingleRunGif(
          key: ValueKey('face_sucess'),
          assetPath: 'assets/lottie/face_sucess.gif',
          width: 130,
          height: 130,
          fit: BoxFit.contain,
        );
      case FaceScanStatus.failed:
        return const SingleRunGif(
          key: ValueKey('face_not_verified'),
          assetPath: 'assets/lottie/face_not_verified.gif',
          width: 130,
          height: 130,
          fit: BoxFit.contain,
        );
      case FaceScanStatus.multipleFaces:
        return Image.asset(
          'assets/lottie/multiplse_detect.gif',
          width: 130,
          height: 130,
          fit: BoxFit.contain,
        );
      case FaceScanStatus.idle:
        return const SizedBox.shrink();
    }
  }

  void _onRemoteConfigUpdated() {
    if (!mounted) return;
    _applySettings();
  }

  Future<void> _applySettings({bool isInitial = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final hasUserCustom = prefs.getBool('user_custom_thresholds_applied') ?? false;
    final savedId = prefs.getString('identify_threshold');
    final savedLive = prefs.getString('liveness_threshold');

    final prevId = _identifyThreshold;
    final prevLive = _livenessThreshold;

    final idThreshold = hasUserCustom && savedId != null && savedId.isNotEmpty
        ? (double.tryParse(savedId) ?? RemoteConfigServices.identityThreshold)
        : RemoteConfigServices.identityThreshold;
    final liveThreshold = hasUserCustom && savedLive != null && savedLive.isNotEmpty
        ? (double.tryParse(savedLive) ?? RemoteConfigServices.livenessThreshold)
        : RemoteConfigServices.livenessThreshold;

    if (mounted) {
      setState(() {
        _identifyThreshold = idThreshold;
        _livenessThreshold = liveThreshold;
      });
    } else {
      _identifyThreshold = idThreshold;
      _livenessThreshold = liveThreshold;
    }

    debugPrint('=================================================================');
    debugPrint('[FacePunch] AFTER APPLY SETTINGS (${isInitial ? "Initial/Cached" : "Remote Config Updated"}):');
    debugPrint('[FacePunch]   - identifyThreshold: $_identifyThreshold (${(_identifyThreshold * 100).toStringAsFixed(1)}%) [Previous: $prevId]');
    debugPrint('[FacePunch]   - livenessThreshold: $_livenessThreshold (${(_livenessThreshold * 100).toStringAsFixed(1)}%) [Previous: $prevLive]');
    debugPrint('[FacePunch]   - userCustomActive : $hasUserCustom');
    debugPrint('=================================================================');
  }

  Future<void> _loadSettings() async {
    try {
      debugPrint('=================================================================');
      debugPrint('[FacePunch] BEFORE APPLY SETTINGS:');
      debugPrint('[FacePunch]   - identifyThreshold : $_identifyThreshold (${(_identifyThreshold * 100).toStringAsFixed(1)}%)');
      debugPrint('[FacePunch]   - livenessThreshold : $_livenessThreshold (${(_livenessThreshold * 100).toStringAsFixed(1)}%)');
      debugPrint('=================================================================');

      // 1. Apply cached/initial settings for instant responsiveness
      await _applySettings(isInitial: true);

      // 2. Fetch fresh remote config from Firebase on punch open
      debugPrint('[FacePunch] Fetching latest Remote Config from Firebase...');
      await RemoteConfigServices.instance.fetchLatestConfig();
      debugPrint('[FacePunch] Remote Config fetch complete.');

      // 3. Re-apply fresh remote settings
      await _applySettings(isInitial: false);
    } catch (e) {
      debugPrint('[FacePunch] _loadSettings error: $e');
    }
  }

  /// Filters enrolled persons from local database to match the currently logged in employee.
  /// Prevents unauthorized persons or users from punching without enrolling their own face.
  List<FaceSdkPerson> _getEnrolledPersonsForCurrentUser(
    List<FaceSdkPerson> allPersons,
  ) {
    if (allPersons.isEmpty) return [];
    if (curentUser == null) return [];

    final String userId = (curentUser?['Id'] ?? '').toString().trim();
    final String userName = (curentUser?['UserName'] ?? curentUser?['Name'] ?? '').toString().trim().toLowerCase();

    debugPrint('[FacePunch] Filter enrolled persons: currentUserId="$userId", userName="$userName", total in DB=${allPersons.length}');
    for (final p in allPersons) {
      debugPrint('[FacePunch]   DB person: name="${p.name}", templateBytes=${p.templates.length}');
    }

    final userPersons = allPersons.where((p) {
      final pName = p.name.trim().toLowerCase();
      // Explicitly ignore legacy placeholder name unless matches current user
      if (pName == 'employee') return false;

      // Match by exact User ID or prefix (e.g. "391941" or "391941_Aaa")
      if (userId.isNotEmpty && (pName == userId || pName.startsWith('${userId}_') || pName.split('_').first == userId)) {
        return true;
      }
      if (userName.isNotEmpty && (pName == userName || pName.startsWith('${userName}_'))) return true;
      return false;
    }).toList();

    // Deduplicate by name to prevent multiple evaluations of duplicate rows
    final uniqueMap = <String, FaceSdkPerson>{};
    for (final p in userPersons) {
      uniqueMap[p.name] = p;
    }
    final deduplicatedPersons = uniqueMap.values.toList();

    return deduplicatedPersons;
  }

  /// On-demand face verification triggered ONLY upon clicking the punch button (max 2 seconds limit).
  /// Runs camera stream only during the 2-second verification window, keeping idle preview at buttery 60 FPS.

  Future<FaceVerificationAttemptResult> _verifyFaceOnDemand({
    Duration timeout = const Duration(seconds: 4),
    List<FaceSdkPerson>? enrolledPersons,
  }) async {
    // Read active thresholds prioritizing RemoteConfigServices with user customization fallback
    final prefs = await SharedPreferences.getInstance();
    final hasUserCustom = prefs.getBool('user_custom_thresholds_applied') ?? false;
    final savedId = prefs.getString('identify_threshold');
    final savedLive = prefs.getString('liveness_threshold');
    _identifyThreshold = hasUserCustom && savedId != null && savedId.isNotEmpty
        ? (double.tryParse(savedId) ?? RemoteConfigServices.identityThreshold)
        : RemoteConfigServices.identityThreshold;
    _livenessThreshold = hasUserCustom && savedLive != null && savedLive.isNotEmpty
        ? (double.tryParse(savedLive) ?? RemoteConfigServices.livenessThreshold)
        : RemoteConfigServices.livenessThreshold;

    debugPrint('[FacePunch] [Verify] Active thresholds for punch: identifyThreshold=$_identifyThreshold, livenessThreshold=$_livenessThreshold');

    final controller = selfiePunchProvider.cameraController;
    if (controller == null || !controller.value.isInitialized || !selfiePunchProvider.isCameraReady) {
      debugPrint('[FacePunch] [Verify] Camera controller not ready. Self-healing restart...');
      try {
        await selfiePunchProvider.startCamera(0);
      } catch (_) {}
      return const FaceVerificationAttemptResult(
        matchResult: null,
        failureReason: 'Camera initializing, please try again',
      );
    }

    final allPersons = enrolledPersons ?? await FaceSdkDatabase.loadAll();
    final targetPersons = _getEnrolledPersonsForCurrentUser(allPersons);

    final String currentUserId = (curentUser?['Id'] ?? '').toString().trim();
    final String currentFileName = (curentUser?['FileName'] ?? curentUser?['FaceRegisterImg'] ?? '').toString().trim();
    final String cleanFileName = currentFileName.split('/').last.split(r'\').last;
    final String base = apibaseurl.endsWith('/') ? apibaseurl : '$apibaseurl/';
    final String fullCompareUrl = currentFileName.startsWith('http')
        ? currentFileName
        : '${base}HRM/Uploads/$currentUserId/$cleanFileName';

    debugPrint('=================================================================');
    debugPrint('[FacePunch] [Verify] STARTING FACE VERIFICATION');
    debugPrint('[FacePunch] [Verify] User ID: $currentUserId');
    debugPrint('[FacePunch] [Verify] FULL COMPARE IMAGE URL: $fullCompareUrl');
    debugPrint('[FacePunch] [Verify] Target enrolled persons for current user: ${targetPersons.length}');
    for (var p in targetPersons) {
      debugPrint('[FacePunch] [Verify]   -> Enrolled Person: name="${p.name}", templates length=${p.templates.length}');
    }
    debugPrint('=================================================================');

    if (targetPersons.isEmpty) {
      debugPrint('[FacePunch] [Verify] BLOCKED: No enrolled faces found for current user!');
      return const FaceVerificationAttemptResult(
        matchResult: null,
        failureReason: 'No enrolled face in local database',
      );
    }

    final cameras = selfiePunchProvider.cameras ?? await availableCameras();
    CameraDescription frontCamera;
    if (cameras.isNotEmpty) {
      frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
    } else {
      frontCamera = controller.description;
    }

    final Completer<FaceVerificationAttemptResult> completer =
        Completer<FaceVerificationAttemptResult>();
    bool isStopped = false;
    bool isProcessing = false;
    int frameCount = 0;
    int consecutiveMatchCount = 0;
    const int requiredConsecutiveMatches = 2; // Require 2 consecutive verified live frames (MiniFASNet + MobileFaceNet) to eliminate photo spoof bypass
    double bestSimilarity = 0.0;
    String? lastFailureReason;

    Future<void> stopStreamSafely() async {
      if (isStopped) return;
      isStopped = true;
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (e) {
        debugPrint('[FacePunch] [Verify] stopImageStream error: $e');
      }
      try {
        await controller.resumePreview();
      } catch (_) {}
    }

    debugPrint(
      '[FacePunch] [Verify] >>> Starting camera frame stream (timeout: ${timeout.inSeconds}s, identifyThreshold: $_identifyThreshold, livenessThreshold: $_livenessThreshold) <<<',
    );

    // Maximum timeout timer
    final Timer timeoutTimer = Timer(timeout, () async {
      if (!completer.isCompleted) {
        debugPrint(
          '[FacePunch] [Verify] >>> TIMED OUT after ${timeout.inSeconds}s! Frames analyzed: $frameCount, Best sim: ${(bestSimilarity * 100).toStringAsFixed(1)}%, Last reason: $lastFailureReason <<<',
        );
        await stopStreamSafely();
        final String reason;
        if (lastFailureReason != null) {
          reason = lastFailureReason!;
        } else if (bestSimilarity > 0) {
          reason = 'Face similarity low (best: ${(bestSimilarity * 100).toStringAsFixed(1)}%)';
        } else {
          reason = 'Face not detected. Please face the camera directly.';
        }
        completer.complete(FaceVerificationAttemptResult(
          matchResult: null,
          bestSimilarity: bestSimilarity,
          framesAnalyzed: frameCount,
          failureReason: reason,
        ));
      }
    });

    try {
      if (controller.value.isStreamingImages) {
        try {
          await controller.stopImageStream();
          await Future.delayed(const Duration(milliseconds: 60));
        } catch (_) {}
      }

      await controller.startImageStream((CameraImage image) async {
        if (isStopped || completer.isCompleted || isProcessing) return;

        frameCount++;
        if (frameCount <= 1) {
          debugPrint('[FacePunch] [Verify] Discarding buffer frame #$frameCount');
          return;
        }

        isProcessing = true;

        final Size screenSize = MediaQuery.of(context).size;
        final double widgetAspectRatio = (screenSize.width - 40) / (screenSize.height * 0.5);

        try {
          final result = await FaceSdkEngine.instance.processCameraFrame(
            cameraImage: image,
            camera: frontCamera,
            enrolledPersons: targetPersons,
            threshold: _identifyThreshold,
            livenessThreshold: _livenessThreshold,
            visibleAspectRatio: widgetAspectRatio,
          );

          if (result == null) {
            debugPrint('[FacePunch] [Verify] Frame #$frameCount: No face detected');
            lastFailureReason = 'No face detected in camera';
          } else if (result.isMultipleFaces || result.errorMessage == 'MULTIPLE_FACES_DETECTED') {
            debugPrint('[FacePunch] [Verify] Frame #$frameCount: ⚠️ MULTIPLE FACES DETECTED! Aborting punch.');
            timeoutTimer.cancel();
            await stopStreamSafely();
            if (!completer.isCompleted) {
              completer.complete(FaceVerificationAttemptResult(
                matchResult: result,
                bestSimilarity: 0.0,
                framesAnalyzed: frameCount,
                failureReason: 'MULTIPLE_FACES_DETECTED',
                isMultipleFaces: true,
              ));
            }
            return;
          } else if (result.errorMessage == 'PARTIAL_FACE_OUTSIDE_FRAME' || result.errorMessage == 'PARTIAL_FACE_DETECTED') {
            debugPrint('[FacePunch] [Verify] Frame #$frameCount: ⚠️ Partial face outside widget frame');
            lastFailureReason = 'PARTIAL_FACE_OUTSIDE_FRAME';
            if (mounted && _cameraBoxMessage != 'Keep Full Face Inside Frame') {
              setState(() {
                _cameraBoxMessage = 'Keep Full Face Inside Frame';
              });
            }
          } else if (result.errorMessage == 'FACE_NOT_LOOKING_STRAIGHT') {
            debugPrint('[FacePunch] [Verify] Frame #$frameCount: ⚠️ Face not looking straight');
            lastFailureReason = 'FACE_NOT_LOOKING_STRAIGHT';
            if (mounted && _cameraBoxMessage != 'Look Straight at Camera') {
              setState(() {
                _cameraBoxMessage = 'Look Straight at Camera';
              });
            }
          } else {
            if (result.similarity > bestSimilarity) {
              bestSimilarity = result.similarity;
            }
            final bool isLiveValid = result.liveness >= _livenessThreshold;
            final bool isIdValid = result.similarity >= _identifyThreshold;

            if (result.errorMessage != null &&
                result.errorMessage != 'SIMILARITY_LOW' &&
                result.errorMessage != 'LIVENESS_FAILED' &&
                result.errorMessage != 'SPOOF_DETECTED') {
              lastFailureReason = result.errorMessage;
            } else if (!isLiveValid) {
              lastFailureReason =
                  'Spoof detected: Liveness ${(result.liveness * 100).toStringAsFixed(1)}% < ${(_livenessThreshold * 100).toInt()}%';
              if (mounted && _cameraBoxMessage != 'Real Face Not Detected (Anti-Spoof)') {
                setState(() {
                  _cameraBoxMessage = 'Real Face Not Detected (Anti-Spoof)';
                });
              }
            } else if (!isIdValid) {
              lastFailureReason =
                  'Similarity ${(result.similarity * 100).toStringAsFixed(1)}% < ${(_identifyThreshold * 100).toInt()}%';
            }

            debugPrint(
              '[FacePunch] [Verify] Frame #$frameCount: Matched="${result.matchedName}", '
              'sim=${(result.similarity * 100).toStringAsFixed(1)}% (req ${(_identifyThreshold * 100).toInt()}%), '
              'live=${(result.liveness * 100).toStringAsFixed(1)}% (req ${(_livenessThreshold * 100).toInt()}%), '
              'isMatch=${result.isMatch} -> ${isLiveValid ? (isIdValid ? "✅ LIVE MATCH" : "⚠️ LOW SIMILARITY") : "❌ SPOOF PHOTO REJECTED"}',
            );

            if (result.isMatch && isLiveValid && isIdValid) {
              consecutiveMatchCount++;
              debugPrint('[FacePunch] [Verify] Frame #$frameCount: Consecutive live matches = $consecutiveMatchCount / $requiredConsecutiveMatches');

              if (consecutiveMatchCount >= requiredConsecutiveMatches && !completer.isCompleted) {
                debugPrint(
                  '[FacePunch] [Verify] >>> LIVE PERSON VERIFIED on frame #$frameCount! Matched "${result.matchedName}" '
                  '(sim: ${(result.similarity * 100).toStringAsFixed(1)}%, live: ${(result.liveness * 100).toStringAsFixed(1)}%) <<<',
                );
                timeoutTimer.cancel();
                await stopStreamSafely();
                completer.complete(FaceVerificationAttemptResult(
                  matchResult: result,
                  bestSimilarity: result.similarity,
                  framesAnalyzed: frameCount,
                ));
                return;
              }
            } else {
              consecutiveMatchCount = 0;
            }
          }
        } catch (e) {
          debugPrint('[FacePunch] [Verify] Frame #$frameCount error: $e');
        } finally {
          isProcessing = false;
        }
      });
    } catch (e) {
      debugPrint('[FacePunch] [Verify] startImageStream error: $e');
      timeoutTimer.cancel();
      await stopStreamSafely();
      try {
        await selfiePunchProvider.startCamera(0);
      } catch (_) {}
      return FaceVerificationAttemptResult(
        matchResult: null,
        bestSimilarity: bestSimilarity,
        framesAnalyzed: frameCount,
        failureReason: 'Camera stream error: $e',
      );
    }

    final attemptResult = await completer.future;
    timeoutTimer.cancel();
    await stopStreamSafely();
    return attemptResult;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  bool _isInitFlowRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RemoteConfigServices.configVersion.addListener(_onRemoteConfigUpdated);
    _loadSettings();

    // Fast path: Check local SQLite enrollment immediately for current user
    FaceRegistrationSyncService.instance.isFaceEnrolledLocally().then((isLocal) {
      if (mounted && isLocal) {
        setState(() {
          _isFaceEnrolled = true;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _runSequentialInitFlow();
      }
    });
  }

  Future<void> _runSequentialInitFlow() async {
    if (!mounted || _isInitFlowRunning) return;
    _isInitFlowRunning = true;

    try {
      // 1. Fetch shift data & start live timer (non-UI background tasks)
      _fetchShiftDataAndStartTimer();

      // 2. Initialize permissions & camera preview
      if (!_permissionsChecked) {
        await _initializePage();
      }

      if (!mounted) return;

      // 3. Initialize Face SDK engine
      await _initFaceSdk();

      if (!mounted) return;

      // 4. Face registration check (ONLY AFTER permissions are done & camera is granted)
      final bool camGranted = await Permission.camera.status.isGranted;
      if (camGranted && !_hasShownFaceRegisterPrompt) {
        await _checkEnrolledFaceStatus();
      }

      if (!mounted) return;

      // 5. Punch Sync Summary dialog (ONLY AFTER face registration dialog is closed)
      await PunchSyncSummaryDialog.showIfNeeded(context);
    } catch (e) {
      debugPrint('[FacePunch] Sequential init flow error: $e');
    } finally {
      _isInitFlowRunning = false;
    }
  }

  void _fetchShiftDataAndStartTimer() {
    final settingProv = Provider.of<SettingProvider>(context, listen: false);
    if (settingProv.setEmpProfile?.positionName != null) {
      Provider.of<AttendanceEmp>(
        context,
        listen: false,
      ).fetchAndStoreBeginTime(
        context,
        settingProv.setEmpProfile!.positionName,
      );
    } else {
      settingProv.getUserEmployeeData(context).then((_) {
        if (mounted) {
          Provider.of<AttendanceEmp>(
            context,
            listen: false,
          ).fetchAndStoreBeginTime(
            context,
            settingProv.setEmpProfile?.positionName,
          );
        }
      });
    }

    // Start live timer to keep check-in/out times updated
    if (mounted) {
      Provider.of<HomeProvider>(
        context,
        listen: false,
      ).startWorkingHoursTimer(context);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selfiePunchProvider = context.read<SelfiePunchProvider>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final controller = selfiePunchProvider.cameraController;
      if (controller != null && controller.value.isStreamingImages) {
        try {
          controller.stopImageStream();
        } catch (_) {}
      }
    }

    if (state == AppLifecycleState.resumed && mounted && _wentToSettings) {
      _wentToSettings = false;
      _checkPermissionsAfterSettings(selfiePunchProvider);
    }
    // Check for punch sync results every time the screen comes to foreground.
    if (state == AppLifecycleState.resumed && mounted) {
      PunchSyncSummaryDialog.showIfNeeded(context);

      // Auto-update location when app returns from background
      if (!_isFlowRunning && _permissionsChecked) {
        selfiePunchProvider.getCurrentLocation(context: context);
      }

      // Self-heal camera preview if it was paused or killed by OS in background
      final controller = selfiePunchProvider.cameraController;
      if (controller == null || !controller.value.isInitialized || !selfiePunchProvider.isCameraReady) {
        debugPrint('[FacePunch] App Resumed: Camera not ready, fast auto-restarting...');
        _cameraAutoRestartAttempts = 0;
        selfiePunchProvider.startCamera(0);
      }

      // Guarantee any stuck scanning or loading state is cleared when returning to screen
      if (_scanStatus == FaceScanStatus.scanning) {
        setState(() {
          _scanStatus = FaceScanStatus.idle;
          _cameraBoxMessage = null;
        });
      }
      selfiePunchProvider.setPunchLoader(false);
      selfiePunchProvider.setPunchBoxOnTapStart(false);
    }
  }

  @override
  void dispose() {
    _cameraBoxMessageTimer?.cancel();
    RemoteConfigServices.configVersion.removeListener(_onRemoteConfigUpdated);
    final controller = selfiePunchProvider.cameraController;
    if (controller != null && controller.value.isStreamingImages) {
      try {
        controller.stopImageStream();
      } catch (_) {}
    }
    selfiePunchProvider.disposeCamera();
    WidgetsBinding.instance.removeObserver(this);

    // Stop the live timer when leaving this screen
    try {
      Provider.of<HomeProvider>(context, listen: false).stopWorkingHoursTimer();
    } catch (_) {}

    _isFlowRunning = false;
    _permissionsChecked = false;
    super.dispose();
  }

  late SelfiePunchProvider selfiePunchProvider;

  // ── Permission flow entry points ───────────────────────────────────────────

  Future<void> _initializePage() async {
    if (_isFlowRunning) return;
    _isFlowRunning = true;
    _permissionsChecked = true;

    final provider = Provider.of<SelfiePunchProvider>(context, listen: false);

    try {
      debugPrint("INITPAGE: 2. FAST PATH started");
      // FAST PATH: Check both camera and location upfront
      bool camGranted = false;
      bool locGranted = false;

      try {
        final results = await Future.wait([
          Permission.camera.status.isGranted.timeout(const Duration(seconds: 2)),
          Permission.location.status.isGranted.timeout(const Duration(seconds: 2)),
        ]);
        camGranted = results[0];
        locGranted = results[1];
        debugPrint(
          "INITPAGE: 3. Fast path results: camGranted=$camGranted, locGranted=$locGranted",
        );
      } catch (e) {
        debugPrint(
          "INITPAGE: 4. Fast path permission check failed or timed out: $e",
        );
      }

      bool cameraStarted = false;
      if (mounted && camGranted) {
        debugPrint("INITPAGE: 5. Fast path calling startCamera(0)");
        provider.startCamera(0);
        cameraStarted = true;
      }

      if (mounted && locGranted) {
        debugPrint(
          "INITPAGE: 6. Fast path locGranted is true, proceeding with API calls",
        );
        Future.wait([
          provider.getCurrentLocation(context: context),
          provider.callApi(context),
        ]);

        _isFlowRunning = false;
        return; // Fast path successful!
      }

      debugPrint("INITPAGE: 14. SLOW PATH started (locGranted=false)");
      // SLOW PATH: We don't have location yet, so we MUST wait for the flow.
      final result = await PermissionFlowService.run(
        context,
        isFetchLocation: provider.isFetchLocation,
      );
      debugPrint(
        "INITPAGE: 15. SLOW PATH PermissionFlowService.run completed with cameraGranted=${result.cameraGranted}",
      );
      if (mounted) {
        await _onPermissionsResolved(provider, result, cameraStarted);
      }
    } catch (e) {
      // If ANY permission check or flow crashes, DON'T leave the UI stuck!
      debugPrint("INITPAGE: 16. _initializePage completely failed: $e");
      if (mounted) {
        provider.cameraisLoading = false;
        provider.readyCameraPreviewshow = false;
        provider.setLoading(provider.isLoading);

        await provider.getCurrentLocation(context: context);
        await provider.callApi(context);
      }
    } finally {
      debugPrint("INITPAGE: 17. _initializePage finally block");
      _isFlowRunning = false;
    }
  }

  // ── KBY-AI FaceSDK initialisation ─────────────────────────────────────────

  static bool _sdkInitialized = false;

  Future<void> _initFaceSdk() async {
    if (!_sdkInitialized) {
      try {
        final initRet = await FaceSdkEngine.instance.init();
        _sdkInitialized = true;
        debugPrint('=================================================================');
        debugPrint('[FacePunch] FACE RECOGNITION ENGINE INITIALIZATION:');
        debugPrint('[FacePunch]   - initRet: $initRet');
        debugPrint('[FacePunch]   - identifyThreshold: $_identifyThreshold (${(_identifyThreshold * 100).toInt()}%)');
        debugPrint('[FacePunch]   - livenessThreshold: $_livenessThreshold (${(_livenessThreshold * 100).toInt()}%)');
        debugPrint('=================================================================');
      } catch (e) {
        debugPrint('[FacePunch] FaceSDK init error: $e');
      }
    }

    try {
      if (curentUser != null && curentUser?['Id'] != null) {
        final userId = curentUser!['Id'].toString().trim();
        final firstName = (curentUser!['FirstName'] ?? curentUser!['UserName'] ?? 'User').toString().trim();
        final userTag = '${userId}_$firstName';
        await FaceSdkDatabase.migrateLegacyEmployeeNameIfNeeded(userTag);
      }
    } catch (_) {}
  }

  // ── Face registration check & employee master sync ────────────────────────
  Future<void> _checkEnrolledFaceStatus({bool allowPrompt = true}) async {
    if (_isCheckingFaceStatus) return;
    _isCheckingFaceStatus = true;

    try {
      final bool isAvailable = await FaceRegistrationSyncService.instance
          .checkFaceAvailabilityAndSync(forceServerCheck: false);

      if (mounted) {
        setState(() {
          _isFaceEnrolled = isAvailable;
          _isCheckingFaceStatus = false;
        });
        // CRITICAL: Only prompt AFTER API response has completed and confirmed user is NOT registered!
        if (!isAvailable && allowPrompt && !_hasShownFaceRegisterPrompt) {
          _hasShownFaceRegisterPrompt = true;
          await _showRegisterFacePromptDialog();
        }
      }
    } catch (e) {
      debugPrint('[FacePunch] _checkEnrolledFaceStatus error: $e');
      if (mounted) {
        final bool isLocal = await FaceRegistrationSyncService.instance.isFaceEnrolledLocally();
        if (mounted) {
          setState(() {
            _isCheckingFaceStatus = false;
            _isFaceEnrolled = isLocal ? true : false;
          });
        }
      }
    }
  }

  Future<void> _showRegisterFacePromptDialog() async {
    if (!mounted) return;
    try {
      await selfiePunchProvider.disposeCamera();
      final registered = await FaceRegistrationSyncService.instance
          .showFaceRegistrationRequiredDialog(context);
      if (registered && mounted) {
        await _onFaceRegistrationCompleted();
      }
    } catch (e) {
      debugPrint('[FacePunch] _showRegisterFacePromptDialog error: $e');
    } finally {
      if (mounted) {
        await _restartPunchCameraAfterRegistration();
      }
    }
  }

  Future<void> _openFaceRegistration() async {
    try {
      await selfiePunchProvider.disposeCamera();
      final registered = await FaceRegistrationSyncService.instance
          .openFaceRegistrationScreen(context);
      if (registered && mounted) {
        await _onFaceRegistrationCompleted();
      }
    } catch (e) {
      debugPrint('[FacePunch] _openFaceRegistration error: $e');
    } finally {
      if (mounted) {
        await _restartPunchCameraAfterRegistration();
      }
    }
  }

  Future<void> _onFaceRegistrationCompleted() async {
    if (!mounted) return;
    setState(() {
      _isFaceEnrolled = true;
      _isCheckingFaceStatus = true;
      _setCameraBoxMessage('Face Registered Successfully');
    });

    try {
      // Reload punch data and status
      await selfiePunchProvider.callApi(context);
      if (mounted) {
        await selfiePunchProvider.getCurrentLocation(context: context);
      }
    } catch (e) {
      debugPrint('[FacePunch] _onFaceRegistrationCompleted callApi error: $e');
    }

    try {
      final isAvailable = await FaceRegistrationSyncService.instance
          .checkFaceAvailabilityAndSync(forceServerCheck: false);
      if (mounted) {
        setState(() {
          _isFaceEnrolled = isAvailable;
          _isCheckingFaceStatus = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFaceEnrolled = true;
          _isCheckingFaceStatus = false;
        });
      }
    }
  }

  Future<void> _restartPunchCameraAfterRegistration() async {
    if (!mounted) return;
    // Release cooldown for Android Camera2 hardware
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    try {
      await selfiePunchProvider.startCamera(0);
    } catch (e) {
      debugPrint('[FacePunch] Camera restart attempt 1 failed: $e, retrying...');
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        try {
          await selfiePunchProvider.startCamera(0);
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _scanStatus = FaceScanStatus.idle;
        _capturedFaceFile = null;
      });
      selfiePunchProvider.setPunchLoader(false);
      selfiePunchProvider.setPunchBoxOnTapStart(false);
      _isFlowRunning = false;
    }
  }


  Future<void> _checkPermissionsAfterSettings(
      SelfiePunchProvider provider,
      ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _isFlowRunning = false; // Reset so it can run again
    await _initializePage();
  }

  // ── Post-flow initialisation ───────────────────────────────────────────────

  Future<void> _onPermissionsResolved(
      SelfiePunchProvider provider,
      PermissionFlowResult result, [
        bool cameraStarted = false,
      ]) async {
    if (!mounted) return;

    if (result.cameraGranted && !cameraStarted) {
      // Start camera in background so it doesn't block location and API calls
      provider.startCamera(0);
    } else if (!result.cameraGranted && !cameraStarted) {
      provider.cameraisLoading = false;
      provider.readyCameraPreviewshow = false;
      provider.setLoading(provider.isLoading);
    }

    final List<Future<void>> futures = [
      if (result.locationGranted) provider.getCurrentLocation(context: context),
      provider.callApi(context),
    ];

    await Future.wait(futures);
  }

  // ── Manual retry (punch buttons) ──────────────────────────────────────────

  Future<void> _retryPermissionFlow(SelfiePunchProvider provider) async {
    if (_isFlowRunning) return;
    _isFlowRunning = true;
    try {
      final result = await PermissionFlowService.run(
        context,
        isFetchLocation: provider.isFetchLocation,
      );
      if (mounted) {
        await _onPermissionsResolved(provider, result);
      }
    } finally {
      _isFlowRunning = false;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    String currentDay = DateFormat('EEEE').format(DateTime.now());
    safeAreaBgAndTextColor(context);

    Provider.of<SelfiePunchProvider>(context);
    Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Camera Preview
          Selector<SelfiePunchProvider, CameraController?>(
            selector: (context, provider) =>
            provider.isCameraReady ? provider.cameraController : null,
            builder: (context, cameraController, child) {
              if (cameraController != null &&
                  cameraController.value.isInitialized &&
                  cameraController.value.previewSize != null) {
                _cameraAutoRestartAttempts = 0;
                return Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Clean, modern ambient dark background (no heavy live blur GPU bottleneck)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF14141E),
                              Color(0xFF0D0D14),
                            ],
                          ),
                        ),
                      ),
                      // Camera Box inside the frame (clean 60 FPS preview, Face_gif biometric scan overlay)
                      Positioned(
                        top:
                            MediaQuery.of(context).size.height *
                            (widget.isFromWidget ? 0.20 : 0.15),
                        left: 20,
                        right: 20,
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF14141E),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Camera preview or verified image with dimmed opacity on success/failed/multipleFaces
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: (_scanStatus == FaceScanStatus.success ||
                                          _scanStatus == FaceScanStatus.failed ||
                                          _scanStatus == FaceScanStatus.multipleFaces)
                                      ? 0.25
                                      : 1.0,
                                  child: (_capturedFaceFile != null && _scanStatus == FaceScanStatus.success)
                                      ? Image.file(
                                          _capturedFaceFile!,
                                          fit: BoxFit.cover,
                                        )
                                      : FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: cameraController.value.previewSize!.height,
                                            height: cameraController.value.previewSize!.width,
                                            child: CameraPreview(cameraController),
                                          ),
                                        ),
                                ),
                                // Dimmed theme overlay on success or failure matching UI/UX
                                if (_scanStatus == FaceScanStatus.success ||
                                    _scanStatus == FaceScanStatus.failed ||
                                    _scanStatus == FaceScanStatus.multipleFaces)
                                  Container(
                                    color: const Color(0xFF0E1320).withOpacity(0.55),
                                  ),
                                // Centered status animations (scanning, success, failed, multiple faces)
                                if (_scanStatus == FaceScanStatus.multipleFaces)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                      child: Image.asset(
                                        'assets/lottie/multiplse_detect.gif',
                                        width: 130,
                                        height: 130,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  )
                                else if (_scanStatus != FaceScanStatus.idle)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.35),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: _buildStatusGif(),
                                    ),
                                  ),

                                // In-camera short message pill: styled using app themeColor, no red, no icons
                                if (_cameraBoxMessage != null && _cameraBoxMessage!.isNotEmpty)
                                  Positioned(
                                    bottom: 12,
                                    left: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: ColorConst.themeColor.withOpacity(0.92),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _cameraBoxMessage!,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Fast auto-restart: automatically trigger camera restart without requiring manual tap
              if (!selfiePunchProvider.cameraisLoading && _cameraAutoRestartAttempts < 5) {
                _triggerFastCameraAutoRestart();
              }

              final bool isAutoRestarting = selfiePunchProvider.cameraisLoading || _cameraAutoRestartAttempts < 5;

              return Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    debugPrint('[FacePunch] Camera fallback tapped: restarting camera...');
                    _cameraAutoRestartAttempts = 0;
                    _lastCameraAutoRestartTime = null;
                    selfiePunchProvider.startCamera(0);
                  },
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isAutoRestarting
                                ? LanguageProvider.translate("startingCamera", "Starting camera...")
                                : LanguageProvider.translate("tapToRestartCamera", "Tap to restart camera"),
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. White Flash Overlay (triggered before capturing selfie in dark environments)
          Selector<SelfiePunchProvider, bool>(
            selector: (context, provider) => provider.showFlashOverlay,
            builder: (context, showFlash, child) {
              if (showFlash) {
                return Positioned.fill(
                  child: Container(color: Colors.white.withOpacity(0.9)),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 3. UI overlays
          Consumer<SelfiePunchProvider>(
            builder: (context, provider, child) {
              // Only show full-screen loader during API/punch operations.
              // Camera warmup (readyCameraPreviewshow) already shows the black
              // placeholder from layer 1 — no extra overlay needed.
              bool showLoading = provider.isLoading && _permissionsChecked;

              if (showLoading) return scanloading();

              // ── Offline state (read outside the inner Consumer to avoid extra rebuild) ──
              final bool isOffline = context
                  .watch<InternetConnectionProvider>()
                  .isOffline;

              return Stack(
                children: [
                  // --- NEW MODERN TOP HEADER ---
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 20,
                        right: 20,
                        bottom:
                        30, // generous bottom padding for the gradient fade
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "${curentUser["FirstName"] ?? ''} ${curentUser["LastName"] ?? ''}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildRangeStatusPill(provider, isOffline),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: ColorConst.themeColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  provider.currentLocation != null
                                      ? provider.currentLocation.toString()
                                      : noLocationDetailsString,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Unified Control Center (Range Status + Attendance Stats + Punch Button)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: widget.isFromWidget ? 20 : 115,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isOffline
                                  ? Colors.red.withOpacity(0.6)
                                  : Colors.white.withOpacity(0.15),
                              width: isOffline ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Offline mode badge
                              if (isOffline)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.wifi_off_rounded,
                                        color: Colors.red,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        offlineModeString,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Row 4: Attendance Stats
                              Consumer2<HomeProvider, AttendanceEmp>(
                                builder:
                                    (
                                    context,
                                    homeProvider,
                                    attendanceEmp,
                                    child,
                                    ) {
                                  bool isLateCheckIn = false;
                                  String checkInStr =
                                      homeProvider.checkInTime;
                                  if (checkInStr != "00:00") {
                                    String? beginTimeStr =
                                        attendanceEmp.shiftBeginTime ??
                                            (attendanceEmp
                                                .getUserShift
                                                ?.beginTime
                                                ?.toString());
                                    if (beginTimeStr != null &&
                                        beginTimeStr != 'null') {
                                      try {
                                        DateTime useTime = DateTime.parse(
                                          beginTimeStr,
                                        );
                                        DateFormat format = DateFormat(
                                          "hh:mm a",
                                        );
                                        DateTime checkInParsed = format
                                            .parse(checkInStr);
                                        DateTime punchInTimeOnly = DateTime(
                                          2000,
                                          1,
                                          1,
                                          checkInParsed.hour,
                                          checkInParsed.minute,
                                          0,
                                        );
                                        DateTime beginTimeOnly = DateTime(
                                          2000,
                                          1,
                                          1,
                                          useTime.hour,
                                          useTime.minute,
                                          useTime.second,
                                        );
                                        isLateCheckIn = punchInTimeOnly
                                            .isAfter(beginTimeOnly);
                                      } catch (e) {
                                        isLateCheckIn = false;
                                      }
                                    }
                                  }

                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _attendanceStatCard(
                                          size,
                                          homeProvider.checkInTime,
                                          checkInString,
                                          const Color(0xff10B981),
                                          isLateCheckIn: isLateCheckIn,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: _attendanceStatCard(
                                          size,
                                          homeProvider.checkOutTime,
                                          checkOutString,
                                          const Color(0xffF43F5E),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: _attendanceStatCard(
                                          size,
                                          homeProvider.currentWorkingHours,
                                          workingHrsString,
                                          ColorConst.themeColor,
                                          isWorking: homeProvider
                                              .isCurrentlyWorking,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(height: 12),

                              // Row 3: Full Width Punch Button (Eliminates right-side blank space)
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: _buildPunchButton(
                                  size,
                                  provider,
                                  currentDay,
                                  isOffline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Range status pill (Interactive with Refresh) ───────────────────────────
  Widget _buildRangeStatusPill(
      SelfiePunchProvider provider, [
        bool isOffline = false,
      ]) {
    final bool isTodayVisit = provider.checkStatus?.todayVisit == true;
    final bool noLocation = provider.currentLocation == null;
    final bool inRange =
        !noLocation &&
            (provider.distance <= provider.allowedRadius || isTodayVisit);

    final color = noLocation
        ? Colors.orange
        : (inRange ? Colors.green : Colors.red);

    String text;
    if (noLocation) {
      text = locationPendingString;
    } else if (isTodayVisit) {
      text = 'In Range (Visit)';
    } else {
      if (provider.distance >= 1000) {
        text = inRange ? inRangeString : outOfRangeString;
      } else {
        text = inRange ? inRangeString : outOfRangeString;
      }
    }

    final bool showRefresh = !inRange || noLocation;

    return GestureDetector(
      onTap: showRefresh
          ? () async {
        if (provider.showLocationLoaders) return;
        provider.setLocationLoader(true);
        try {
          await provider.requestLocationPermission();
          await provider.getCurrentLocation(context: context);
        } finally {
          provider.setLocationLoader(false);
        }
      }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.showLocationLoaders)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 1.5,
                ),
              )
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showRefresh && !provider.showLocationLoaders) ...[
              const SizedBox(width: 4),
              Icon(Icons.refresh_rounded, color: color, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  // ── Face Match Accuracy Pill & Dialog ─────────────────────────────────────
  Widget _buildAccuracyPill() {
    return Tooltip(
      message: 'Face: ${(_identifyThreshold * 100).toInt()}% ($_accuracyTier)\nLiveness: ${(_livenessThreshold * 100).toInt()}% ($_livenessTier)',
      child: InkWell(
        onTap: _showAccuracySettingsDialog,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded, color: Colors.white, size: 13),
              const SizedBox(width: 4),
              Text(
                '${(_identifyThreshold * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _accuracyTier {
    if (_identifyThreshold < 0.70) return 'Lenient (Dim/Harsh Light)';
    if (_identifyThreshold < 0.80) return 'Balanced (Recommended)';
    if (_identifyThreshold < 0.88) return 'Strict';
    return 'Maximum';
  }

  String get _livenessTier {
    if (_livenessThreshold < 0.60) return 'Relaxed (Dim/Low Light)';
    if (_livenessThreshold < 0.75) return 'Balanced (Recommended)';
    if (_livenessThreshold < 0.85) return 'Strict Anti-Spoof';
    return 'Maximum Anti-Spoof';
  }

  Future<void> _showAccuracySettingsDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedId = prefs.getString('identify_threshold');
    final String? savedLive = prefs.getString('liveness_threshold');
    double tempThreshold = (savedId != null && savedId.trim().isNotEmpty)
        ? (double.tryParse(savedId.trim()) ?? _identifyThreshold)
        : _identifyThreshold;
    double tempLivenessThreshold = (savedLive != null && savedLive.trim().isNotEmpty)
        ? (double.tryParse(savedLive.trim()) ?? _livenessThreshold)
        : _livenessThreshold;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String accuracyLabel;
            Color accuracyColor;
            String accuracyTip;

            if (tempThreshold < 0.65) {
              accuracyLabel = 'Fast / Lenient (${(tempThreshold * 100).toInt()}%)';
              accuracyColor = Colors.orange.shade800;
              accuracyTip =
                  'Best for rapid recognition in dim light, varying angles, or glare.';
            } else if (tempThreshold < 0.78) {
              accuracyLabel = 'Balanced / Recommended (${(tempThreshold * 100).toInt()}%)';
              accuracyColor = const Color(0xFF10B981);
              accuracyTip =
                  'Recommended standard for office environments.';
            } else if (tempThreshold < 0.88) {
              accuracyLabel = 'Strict (${(tempThreshold * 100).toInt()}%)';
              accuracyColor = Colors.blue.shade700;
              accuracyTip =
                  'High security matching. Requires consistent, bright frontal lighting.';
            } else {
              accuracyLabel = 'Maximum Security (${(tempThreshold * 100).toInt()}%)';
              accuracyColor = Colors.purple.shade700;
              accuracyTip =
                  'Very strict matching. Face must be close and evenly lit.';
            }

            String livenessLabel;
            Color livenessColor;
            String livenessTip;

            if (tempLivenessThreshold < 0.60) {
              livenessLabel = 'Relaxed (50% - 59%)';
              livenessColor = Colors.orange.shade800;
              livenessTip =
                  'Reduces false spoof flags under dim lighting, high contrast, or older selfie cameras.';
            } else if (tempLivenessThreshold < 0.75) {
              livenessLabel = 'Balanced / Recommended (60% - 74%)';
              livenessColor = const Color(0xFF10B981);
              livenessTip =
                  'Recommended anti-spoof protection against printed photos, mobile screen replays, and video playback.';
            } else if (tempLivenessThreshold < 0.85) {
              livenessLabel = 'Strict Anti-Spoof (75% - 84%)';
              livenessColor = Colors.blue.shade700;
              livenessTip =
                  'High security real-person verification. Requires good direct frontal light and no glare.';
            } else {
              livenessLabel = 'Maximum Security (85% - 95%)';
              livenessColor = Colors.purple.shade700;
              livenessTip =
                  'Ultra-strict human liveness verification. Disallows any motion blur or low lighting.';
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ColorConst.themeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: ColorConst.themeColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Face & Liveness Settings',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tune match accuracy & anti-spoof sensitivity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.black54),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F1)),

                  // Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── SECTION 1: FACE MATCH ACCURACY ──────────────────
                          Row(
                            children: [
                              Icon(
                                Icons.face_retouching_natural_rounded,
                                color: ColorConst.themeColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Face Match Accuracy',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accuracyColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accuracyColor.withOpacity(0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        accuracyLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: accuracyColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accuracyColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${(tempThreshold * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  accuracyTip,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Match Sensitivity',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${(tempThreshold * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: accuracyColor,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: accuracyColor,
                              thumbColor: accuracyColor,
                              overlayColor: accuracyColor.withOpacity(0.2),
                              trackHeight: 5,
                            ),
                            child: Slider(
                              value: tempThreshold,
                              min: 0.40,
                              max: 0.90,
                              divisions: 50,
                              onChanged: (val) {
                                setModalState(() {
                                  tempThreshold = val;
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '40% (Lenient)',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                              ),
                              Text(
                                '55% (Recommended)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: ColorConst.themeColor,
                                ),
                              ),
                              Text(
                                '90% (Strict)',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            'Quick Match Presets:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPresetChip('Fast (50%)', 0.50, tempThreshold, (val) {
                                setModalState(() => tempThreshold = val);
                              }),
                              _buildPresetChip('Balanced (55%)', 0.55, tempThreshold, (val) {
                                setModalState(() => tempThreshold = val);
                              }),
                              _buildPresetChip('Standard (60%)', 0.60, tempThreshold, (val) {
                                setModalState(() => tempThreshold = val);
                              }),
                              _buildPresetChip('Strict (70%)', 0.70, tempThreshold, (val) {
                                setModalState(() => tempThreshold = val);
                              }),
                            ],
                          ),

                          const SizedBox(height: 22),
                          const Divider(height: 1, color: Color(0xFFEAEAEA)),
                          const SizedBox(height: 18),

                          // ── SECTION 2: LIVENESS SENSITIVITY ──────────────────
                          Row(
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: livenessColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Liveness (Anti-Spoofing)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: livenessColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: livenessColor.withOpacity(0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        livenessLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: livenessColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: livenessColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${(tempLivenessThreshold * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  livenessTip,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Liveness Sensitivity',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${(tempLivenessThreshold * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: livenessColor,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: livenessColor,
                              thumbColor: livenessColor,
                              overlayColor: livenessColor.withOpacity(0.2),
                              trackHeight: 5,
                            ),
                            child: Slider(
                              value: tempLivenessThreshold,
                              min: 0.50,
                              max: 0.95,
                              divisions: 45,
                              onChanged: (val) {
                                setModalState(() {
                                  tempLivenessThreshold = val;
                                });
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '50% (Relaxed)',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                              ),
                              Text(
                                '70% (Recommended)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
                                ),
                              ),
                              Text(
                                '95% (High Security)',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          const Text(
                            'Quick Liveness Presets:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPresetChip('Relaxed (60%)', 0.60, tempLivenessThreshold, (val) {
                                setModalState(() => tempLivenessThreshold = val);
                              }),
                              _buildPresetChip('Balanced (70%)', 0.70, tempLivenessThreshold, (val) {
                                setModalState(() => tempLivenessThreshold = val);
                              }),
                              _buildPresetChip('High (80%)', 0.80, tempLivenessThreshold, (val) {
                                setModalState(() => tempLivenessThreshold = val);
                              }),
                              _buildPresetChip('Strict (85%)', 0.85, tempLivenessThreshold, (val) {
                                setModalState(() => tempLivenessThreshold = val);
                              }),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Sticky Save & Apply Action Button
                  Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 12,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          offset: const Offset(0, -3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConst.themeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await RemoteConfigServices.updateCustomThresholds(
                            identify: tempThreshold,
                            liveness: tempLivenessThreshold,
                          );
                          if (mounted) {
                            setState(() {
                              _identifyThreshold = tempThreshold;
                              _livenessThreshold = tempLivenessThreshold;
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Face settings updated: Match ${(tempThreshold * 100).toInt()}%, Liveness ${(tempLivenessThreshold * 100).toInt()}%',
                                ),
                                backgroundColor: Colors.green.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save & Apply',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildPresetChip(
    String label,
    double value,
    double currentVal,
    ValueChanged<double> onSelected,
  ) {
    final bool isSelected = (currentVal * 100).round() == (value * 100).round();
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? ColorConst.themeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ColorConst.themeColor : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ── Punch button logic ─────────────────────────────────────────────────────

  Widget _buildPunchButton(
      Size size,
      SelfiePunchProvider provider,
      String currentDay, [
        bool isOffline = false,
      ]) {
    final bool hasCamera =
        _permissionsChecked &&
            provider.camerapermissionStatus == PermissionStatus.granted;

    // Camera not yet allowed
    if (!hasCamera) {
      return _customButton(
        label: cameraString,
        color: ColorConst.themeColor,
        onTap: () async {
          if (_isFlowRunning) return;
          await _retryPermissionFlow(provider);
        },
      );
    }

    // Location is loading
    if (provider.showLocationLoaders) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 1.5,
          ),
        ),
      );
    }

    // Location not obtained
    if (provider.currentLocation == null) {
      return _customButton(
        label: locationString,
        color: ColorConst.themeColor,
        onTap: () async {
          if (_isFlowRunning) return;
          await _retryPermissionFlow(provider);
        },
      );
    }

    // Camera is warming up after permissions granted — show spinner
    // This only triggers AFTER _permissionsChecked=true and camera is actively initializing
    if (_permissionsChecked &&
        (provider.readyCameraPreviewshow || provider.cameraisLoading)) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ColorConst.themeColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    // Permissions not yet checked — show disabled punch placeholder
    if (!_permissionsChecked) {
      return _customButton(
        label: punchString,
        color: ColorConst.themeColor.withOpacity(0.5),
        onTap: () {}, // disabled
      );
    }

    // Camera failed to initialize despite having permissions
    if (!provider.isCameraReady) {
      return _customButton(
        label: retryCameraString,
        color: Colors.orange,
        onTap: () {
          provider.startCamera(0);
        },
      );
    }

    // Punch loader or on-demand face verification active
    if (provider.PunchLoader || _scanStatus != FaceScanStatus.idle) {
      return GestureDetector(
        onTap: () {
          debugPrint('[FacePunch] Stuck button tapped by user: resetting to idle');
          if (mounted) {
            setState(() {
              _scanStatus = FaceScanStatus.idle;
              _cameraBoxMessage = null;
            });
          }
          provider.setPunchLoader(false);
          provider.setPunchBoxOnTapStart(false);
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorConst.themeColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_scanStatus == FaceScanStatus.scanning || provider.PunchLoader) ...[
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                _scanStatus == FaceScanStatus.scanning
                    ? LanguageProvider.translate("verifyingFace", "Verifying Face...")
                    : _scanStatus == FaceScanStatus.success
                        ? LanguageProvider.translate("faceVerifiedSuccess", "Face Verified!")
                        : _scanStatus == FaceScanStatus.failed
                            ? LanguageProvider.translate("faceNotVerified", "Face Not Verified")
                            : _scanStatus == FaceScanStatus.multipleFaces
                                ? LanguageProvider.translate("multipleFacesDetected", "Multiple People Detected")
                                : waitString,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Attendance status pending — but ONLY block if online.
    // When offline, checkStatus may legitimately be null on first open if prefs
    // load hasn't completed. Treat null checkStatus as "not punched yet" (Punch IN).
    if (!isOffline &&
        (provider.checkStatus == null ||
            provider.checkStatus!.attendenceLog == null)) {
      return _customButton(
        label: waitString,
        color: ColorConst.themeColor.withOpacity(0.5),
        onTap: () {},
      );
    }

    // 1. While checking face registration from API / downloading, DO NOT show Register Face!
    // Show disabled "Please Wait..." instead so user never sees premature "Register Face".
    if (_isFaceEnrolled == null || _isCheckingFaceStatus) {
      return _customButton(
        label: waitString,
        color: ColorConst.themeColor.withOpacity(0.5),
        onTap: () {},
      );
    }

    // 2. ONLY show "Register Face" AFTER API response confirmed user is truly not registered
    if (_isFaceEnrolled == false) {
      return _customButton(
        label: "Register Face",
        color: ColorConst.themeColor,
        onTap: () => _openFaceRegistration(),
      );
    }

    // Punch In / Punch Out
    final bool isPunchIn =
        provider.checkStatus!.attendenceLog!.isEmpty ||
            provider.checkStatus!.attendenceLog!.last.status != 'IN';

    final String buttonName = isPunchIn ? punchInString : punchOutString;
    final Color buttonColor = isPunchIn
        ? ColorConst.themeColor
        : Colors.red.shade600;

    // When opened from home screen widget, auto-trigger punch instantly as soon as camera is ready
    if (widget.isFromWidget && !_hasAutoPunchedFromWidget) {
      _hasAutoPunchedFromWidget = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scanStatus == FaceScanStatus.idle && !provider.PunchLoader) {
          _performFacePunch(provider, currentDay, isOffline);
        }
      });
    }

    return _customButton(
      label: buttonName,
      color: buttonColor,
      onTap: () {
        debugPrint('[FacePunch] >>> Punch button "$buttonName" tapped (isPunchIn=$isPunchIn, isOffline=$isOffline) <<<');
        _performFacePunch(provider, currentDay, isOffline);
      },
    );
  }

  Future<void> _performFacePunch(
    SelfiePunchProvider provider,
    String currentDay,
    bool isOffline,
  ) async {
    debugPrint('[FacePunch] ================= PUNCH FLOW STARTED =================');
    debugPrint(
      '[FacePunch] currentDay: $currentDay, isOffline: $isOffline, _scanStatus: $_scanStatus, _isFlowRunning: $_isFlowRunning',
    );
    debugPrint(
      '[FacePunch] curentUser ID: ${curentUser?['Id']}, Name: ${curentUser?['UserName']} / ${curentUser?['FirstName']}, FileName: ${curentUser?['FileName']}, FaceRegisterImg: ${curentUser?['FaceRegisterImg']}',
    );

    if (_isFlowRunning) {
      debugPrint('[FacePunch] WARNING: _isFlowRunning was true. Resetting to false.');
      _isFlowRunning = false;
    }

    if (_scanStatus != FaceScanStatus.idle) {
      debugPrint('[FacePunch] _scanStatus is $_scanStatus (not idle). Resetting to allow retry.');
      if (mounted) {
        setState(() {
          _scanStatus = FaceScanStatus.idle;
          _cameraBoxMessage = null;
        });
      }
      provider.setPunchLoader(false);
      provider.setPunchBoxOnTapStart(false);
      return;
    }

    Timer? stuckWatchdogTimer;

    try {
      // 12-second safety watchdog ensures button or loader never gets stuck indefinitely
      stuckWatchdogTimer = Timer(const Duration(seconds: 12), () {
        if (mounted && (_scanStatus != FaceScanStatus.idle || provider.PunchLoader)) {
          debugPrint('[FacePunch] Safety watchdog: Force-resetting stuck scan status / loader');
          setState(() {
            _scanStatus = FaceScanStatus.idle;
            _capturedFaceFile = null;
            _cameraBoxMessage = null;
          });
          provider.setPunchLoader(false);
          provider.setPunchBoxOnTapStart(false);
        }
      });

      PunchPerformanceTracker.start('Face Punch Flow');

      // In release builds, block Punch In/Out if Developer Mode is enabled
      if (await DeveloperModeService.isDeveloperModeRestricted()) {
        debugPrint('[FacePunch] BLOCKED: Developer mode restricted.');
        PunchPerformanceTracker.step('Developer Mode Check');
        PunchPerformanceTracker.finish(isSuccess: false, message: 'Developer Mode Restricted');
        if (context.mounted) {
          DeveloperModeService.showDeveloperModeWarningDialog(context);
        }
        return;
      }
      PunchPerformanceTracker.step('Developer Mode Check Passed');
      debugPrint('[FacePunch] Developer mode check passed.');

      // Check internet connection before proceeding with punch
      bool hasNoInternet = isOffline ||
          (context.mounted &&
              context.read<InternetConnectionProvider>().isOffline);

      if (!hasNoInternet) {
        try {
          final connectivityResults =
          await Connectivity().checkConnectivity();
          if (connectivityResults.contains(ConnectivityResult.none) ||
              connectivityResults.isEmpty) {
            hasNoInternet = true;
          }
        } catch (_) {}
      }
      PunchPerformanceTracker.step('Connectivity Check', 'Offline: $hasNoInternet');
      debugPrint('[FacePunch] Connectivity check: hasNoInternet=$hasNoInternet');

      if (hasNoInternet) {
        debugPrint('[FacePunch] BLOCKED: No internet connection.');
        PunchPerformanceTracker.finish(isSuccess: false, message: 'No internet connection');
        if (context.mounted) {
          _showNoInternetDialog(context);
        }
        return;
      }

      // ── Clear all previous face capture & provider image state immediately ──
      provider.imageFile = null;
      if (mounted) {
        setState(() {
          _capturedFaceFile = null;
          _scanStatus = FaceScanStatus.idle;
        });
      }
      PunchPerformanceTracker.step('Reset State & Clear Previous Image');

      // ── Load Settings & Check Enrolled Faces in Local SQLite ──
      await _loadSettings();
      final allPersons = await FaceSdkDatabase.loadAll();
      debugPrint('[FacePunch] FaceSdkDatabase loaded ${allPersons.length} persons: ${allPersons.map((p) => p.name).toList()}');

      final persons = _getEnrolledPersonsForCurrentUser(allPersons);
      debugPrint('[FacePunch] Matching enrolled persons for current user: ${persons.length}');

      // If local DB doesn't have the face yet, attempt on-demand server sync with forceServerCheck: true
      if (persons.isEmpty) {
        debugPrint('[FacePunch] No matching persons found locally. Attempting server sync (forceServerCheck: true)...');
        await FaceRegistrationSyncService.instance.checkFaceAvailabilityAndSync(forceServerCheck: true);
        final reloadedPersons = _getEnrolledPersonsForCurrentUser(await FaceSdkDatabase.loadAll());
        if (reloadedPersons.isNotEmpty) {
          persons.addAll(reloadedPersons);
          _isFaceEnrolled = true;
          debugPrint('[FacePunch] Server sync found ${persons.length} matching enrolled templates!');
        }
      }

      PunchPerformanceTracker.step('Load Settings & Enrolled Faces', 'Count: ${persons.length}');

      if (_isFaceEnrolled != true || persons.isEmpty) {
        debugPrint('[FacePunch] BLOCKED: _isFaceEnrolled=$_isFaceEnrolled, matching persons=${persons.length}');
        PunchPerformanceTracker.finish(isSuccess: false, message: 'No enrolled faces found');
        if (mounted) {
          _setCameraBoxMessage(
            persons.isEmpty ? 'Face Not Registered' : 'Face Sync Pending',
          );
          _showRegisterFacePromptDialog();
        }
        return;
      }

      final String currentUserId = (curentUser?['Id'] ?? '').toString().trim();
      final String currentFileName = (curentUser?['FileName'] ?? curentUser?['FaceRegisterImg'] ?? '').toString().trim();
      final String cleanFileName = currentFileName.split('/').last.split(r'\').last;
      final String base = apibaseurl.endsWith('/') ? apibaseurl : '$apibaseurl/';
      final String fullCompareUrl = currentFileName.startsWith('http')
          ? currentFileName
          : '${base}HRM/Uploads/$currentUserId/$cleanFileName';

      debugPrint('=================================================================');
      debugPrint('[FacePunch] ================= COMPARE IMAGE FULL URL =================');
      debugPrint('[FacePunch] USER ID: $currentUserId');
      debugPrint('[FacePunch] NAME: ${curentUser?['UserName']} / ${curentUser?['FirstName']}');
      debugPrint('[FacePunch] FILE NAME: $cleanFileName');
      debugPrint('[FacePunch] FULL COMPARE IMAGE URL: $fullCompareUrl');
      debugPrint('=================================================================');

      if (mounted) {
        setState(() {
          _scanStatus = FaceScanStatus.scanning;
        });
      }

      final startTime = DateTime.now();

      final attemptResult = await _verifyFaceOnDemand(
        timeout: const Duration(seconds: 4),
        enrolledPersons: persons,
      );

      final verifyResult = attemptResult.matchResult;
      PunchPerformanceTracker.step(
        'On-Demand Face Verification',
        attemptResult.isSuccess && verifyResult != null
            ? 'Matched: ${verifyResult.matchedName} (sim: ${(verifyResult.similarity * 100).toStringAsFixed(1)}%)'
            : 'Face Verification Failed: ${attemptResult.failureReason}',
      );

      if (!mounted) return;

      // Snappy scanning animation delay
      final elapsed = DateTime.now().difference(startTime);
      const minScanDuration = Duration(milliseconds: 150);
      if (elapsed < minScanDuration) {
        await Future.delayed(minScanDuration - elapsed);
      }
      PunchPerformanceTracker.step('Scanning Animation Delay');
      if (!mounted) return;

      if (attemptResult.isMultipleFaces || attemptResult.failureReason == 'MULTIPLE_FACES_DETECTED') {
        provider.imageFile = null;
        if (mounted) {
          setState(() {
            _capturedFaceFile = null;
            _scanStatus = FaceScanStatus.multipleFaces;
            _cameraBoxMessage = LanguageProvider.translate(
              'multipleFacesDetected',
              'Multiple People Detected',
            );
          });
        }
        debugPrint('[FacePunch] ================= PUNCH REJECTED: MULTIPLE PEOPLE DETECTED =================');
        PunchPerformanceTracker.finish(isSuccess: false, message: 'Multiple people detected. Punch rejected.');

        await Future.delayed(const Duration(milliseconds: 2500));
        return;
      }

      if (!attemptResult.isSuccess || verifyResult == null) {
        provider.imageFile = null;
        final String shortMsg;
        if (attemptResult.failureReason == 'PARTIAL_FACE_OUTSIDE_FRAME' ||
            attemptResult.failureReason == 'PARTIAL_FACE_DETECTED') {
          shortMsg = 'Keep Full Face Inside Frame';
        } else if (attemptResult.failureReason == 'FACE_NOT_LOOKING_STRAIGHT') {
          shortMsg = 'Look Straight at Camera';
        } else if (attemptResult.failureReason != null &&
            (attemptResult.failureReason!.toLowerCase().contains('liveness') ||
                attemptResult.failureReason!.toLowerCase().contains('spoof'))) {
          shortMsg = 'Real Face Not Detected (Anti-Spoof)';
        } else if (attemptResult.bestSimilarity > 0) {
          shortMsg = LanguageProvider.translate(
            'faceNotMatched',
            'Face Not Matched',
          );
        } else {
          shortMsg = LanguageProvider.translate(
            'faceNotDetected',
            'Face Not Detected',
          );
        }

        if (mounted) {
          setState(() {
            _capturedFaceFile = null;
            _scanStatus = FaceScanStatus.failed;
            _cameraBoxMessage = shortMsg;
          });
        }
        final String reason = attemptResult.failureReason ?? 'Face verification failed';
        debugPrint('[FacePunch] ================= PUNCH FAILED: VERIFICATION =================');
        debugPrint('[FacePunch] Reason: $reason (best sim: ${(attemptResult.bestSimilarity * 100).toStringAsFixed(1)}%, frames: ${attemptResult.framesAnalyzed})');
        PunchPerformanceTracker.finish(isSuccess: false, message: 'Face verification failed: $reason');

        await Future.delayed(const Duration(milliseconds: 1800));
        return;
      }

      debugPrint(
        '[FacePunch] >>> Face verified! Matched: ${verifyResult.matchedName} (similarity: ${(verifyResult.similarity * 100).toStringAsFixed(1)}%) <<<',
      );

      // Face is verified! Pass the real full-frame selfie (uncropped, unzoomed)
      if (verifyResult.fullFrameJpg != null) {
        try {
          final tempFile = File(
            '${Directory.systemTemp.path}/full_selfie_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}.jpg',
          );
          await tempFile.writeAsBytes(verifyResult.fullFrameJpg!, flush: true);
          try {
            PaintingBinding.instance.imageCache.evict(FileImage(tempFile));
          } catch (_) {}
          provider.imageFile = tempFile;
          _capturedFaceFile = tempFile;
          debugPrint('[FacePunch] Full selfie file written: ${tempFile.path} (${tempFile.lengthSync()} bytes)');
        } catch (e) {
          debugPrint('[FacePunch] Error writing verified full frame: $e');
        }
      }
      PunchPerformanceTracker.step('Write Verified Full-Frame File');

      if (mounted) {
        setState(() {
          _scanStatus = FaceScanStatus.success;
          _cameraBoxMessage = null;
        });
      }

      // Snappy checkmark display (200ms)
      await Future.delayed(const Duration(milliseconds: 200));
      PunchPerformanceTracker.step('Success Checkmark Display');
      if (!mounted) return;

      PunchPerformanceTracker.step('Invoking puchInOutHandleSubmit');
      debugPrint('[FacePunch] >>> Invoking provider.puchInOutHandleSubmit <<<');
      await provider.puchInOutHandleSubmit(
        context,
        currentDay,
        widget.isFromWidget,
        true, // Face verified
      );
      debugPrint('[FacePunch] >>> puchInOutHandleSubmit finished <<<');
    } catch (e, stack) {
      debugPrint('[FacePunch] ERROR in _performFacePunch: $e\n$stack');
      if (mounted) {
        _setCameraBoxMessage('Punch Failed. Please Try Again.');
      }
    } finally {
      stuckWatchdogTimer?.cancel();
      provider.imageFile = null;
      if (mounted) {
        setState(() {
          _scanStatus = FaceScanStatus.idle;
          _capturedFaceFile = null;
          _cameraBoxMessage = null;
        });
      }
      provider.setPunchLoader(false);
      provider.setPunchBoxOnTapStart(false);
      _isFlowRunning = false;

      // Fast auto-restart if camera stopped or became uninitialized during verification
      final ctrl = selfiePunchProvider.cameraController;
      if (ctrl == null || !ctrl.value.isInitialized || !selfiePunchProvider.isCameraReady) {
        debugPrint('[FacePunch] Camera not ready after punch flow, auto-restarting fast...');
        _cameraAutoRestartAttempts = 0;
        selfiePunchProvider.startCamera(0);
      }
    }
  }

  // ── No Internet Connection Dialog ──────────────────────────────────────────
  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 44,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  LanguageProvider.translate(
                    "noInternetConnection",
                    "No Internet Connection",
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  internetDecString,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConst.themeColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      okayString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Custom solid button with colored drop shadow ───────────────────────────
  Widget _customButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _attendanceStatCard(
      Size size,
      String time,
      String label,
      Color accentColor, {
        bool isWorking = false,
        bool isLateCheckIn = false,
      }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: size.width * 0.015,
        horizontal: size.width * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWorking
              ? const Color(0xff10B981).withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: TextStyle(
              color: isLateCheckIn ? Colors.redAccent : Colors.white,
              fontFamily: fontInterSemiBoldString,
              fontWeight: FontWeight.bold,
              fontSize: size.width * 0.030,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWorking) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xff10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: fontInterSemiBoldString,
                    fontWeight: FontWeight.w600,
                    fontSize: size.width * 0.020,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OverlayHoleClipper extends CustomClipper<Path> {
  final double top;
  final double left;
  final double right;
  final double height;
  final double radius;

  OverlayHoleClipper({
    required this.top,
    required this.left,
    required this.right,
    required this.height,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, size.width - right, top + height),
          Radius.circular(radius),
        ),
      );
    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(covariant OverlayHoleClipper oldClipper) {
    return oldClipper.top != top ||
        oldClipper.left != left ||
        oldClipper.right != right ||
        oldClipper.height != height ||
        oldClipper.radius != radius;
  }
}
