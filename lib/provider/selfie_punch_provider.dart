// ignore_for_file: strict_top_level_inference, unused_local_variable, unused_catch_clause, use_build_context_synchronously, non_constant_identifier_names, empty_catches, unused_field

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/provider/face_verification_provider.dart';
import 'package:tax_hrm/services/remote_config_services.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/services/location_permission_service.dart';
import 'package:tax_hrm/models/offline_punch_record.dart';
import 'package:tax_hrm/provider/location_tracking_provider.dart';
import 'package:tax_hrm/repository/background_location_repository.dart';
import 'package:tax_hrm/models/attendance/attendanceBlog.dart';
import 'package:tax_hrm/models/attendance/punchnow.dart'
    hide Attendence, AttendenceLog;
import 'package:tax_hrm/models/createcguid.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/shiftclass/shiftmaster/getshiftmasters.dart';
import 'package:tax_hrm/page/attendance/punchBox.dart';
import 'package:tax_hrm/page/attendance/viewAttendance_screen.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/provider/shiftprovider.dart';
import 'package:tax_hrm/services/offline_punch_sync_service.dart';
import 'package:tax_hrm/utils/reminder_service.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/services/background_location_service.dart';
import 'package:tax_hrm/services/location_batch_service.dart';
import 'package:tax_hrm/services/punch_performance_tracker.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/common_dialogBox.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:tax_hrm/services/developer_mode_service.dart';

import '../services/fcm_token_service.dart';
import 'language_provider.dart';

class SelfiePunchProvider extends ChangeNotifier {
  bool _notifyScheduled = false;

  @override
  void notifyListeners() {
    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;
    final canNotifyNow =
        schedulerPhase == SchedulerPhase.idle ||
        schedulerPhase == SchedulerPhase.postFrameCallbacks;

    if (canNotifyNow) {
      super.notifyListeners();
      return;
    }

    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      super.notifyListeners();
    });
  }

  // ==================== LOADING STATES ====================
  bool isLoading = false;
  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  bool PunchLoader = false;
  void setPunchLoader(bool value) {
    PunchLoader = value;
    notifyListeners();
  }

  bool showLocationLoaders = false;
  void setLocationLoader(bool value) {
    showLocationLoaders = value;
    notifyListeners();
  }

  /// Resets all punch and verification state on user logout or user change.
  void resetState() {
    checkStatus = null;
    imageFile = null;
    PunchLoader = false;
    isLoading = false;
    cameraisLoading = true;
    readyCameraPreviewshow = true;
    isCameraReady = false;
    punchBoxOnTapStart = false;
    isPrePunchChecksLoading = false;
    isPrePunchChecksSuccess = false;
    punchProcessStatus.value = '';
    punchBoxNotesController.clear();
    lastPersistedSelfiePath = null;
    notifyListeners();
  }

  bool cameraisLoading = true;
  bool readyCameraPreviewshow = true;
  bool isCameraReady = false;
  bool isDarkEnvironment = false;
  bool showFlashOverlay = false;

  // ==================== PERMISSION STATES ====================
  PermissionStatus? camerapermissionStatus;

  Future<bool> checkCameraPermission() async {
    PermissionStatus cameraStatus = await Permission.camera.status;
    camerapermissionStatus = cameraStatus;
    notifyListeners();
    return cameraStatus.isGranted;
  }

  bool get isFetchLocation =>
      BackgroundLocationRepository.isFetchLocationEnabled();

  /// Returns true if basic location permission is sufficient to punch.
  /// Background tracking (Always) is handled separately during initialization.
  Future<bool> checkLocationPermission() async {
    final locationStatus = await Permission.location.status;
    return locationStatus.isGranted;
  }

  Future<void> requestCameraPermission() async {
    camerapermissionStatus = await Permission.camera.request();
    notifyListeners();
  }

  /// Fetches and stores location silently if any location permission is already granted.
  ///
  /// All dialog-driven permission requests are handled by [PermissionFlowService].
  /// This method is called AFTER permissions have been resolved, or from the
  /// refresh button when location is already granted.
  Future<void> requestLocationPermission({BuildContext? context}) async {
    final fgGranted = (await Permission.location.status).isGranted;
    final bgGranted = (await Permission.locationAlways.status).isGranted;

    if (fgGranted || bgGranted) {
      await _fetchAndStoreLocation();
      notifyListeners();
    }
    // If not granted, PermissionFlowService has already managed the dialog flow.
  }

  /// Internal helper: fetches GPS position and stores lat/lng + address.
  Future<void> _fetchAndStoreLocation() async {
    try {
      Position useds = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        ),
      );
      setlongitude = useds.longitude.toString();
      setlatitude = useds.latitude.toString();
      await getAddressFromLatLng(useds.longitude, useds.latitude);
    } catch (e) {
      /* ignored */
    }
  }

  // ==================== CAMERA FUNCTIONS ====================
  List<CameraDescription>? cameras;
  CameraController? cameraController;
  int _cameraSessionId = 0;
  bool isFrontCamera = true;
  File? imageFile;
  XFile? picture;

  Future<void> startCamera(int setDirection) async {
    log("STARTCAMERA: 1. startCamera called with direction $setDirection");
    final sessionId = ++_cameraSessionId;
    readyCameraPreviewshow = true;
    cameraisLoading = true;
    isCameraReady = false;
    notifyListeners();

    try {
      // Fast path: Only query/request camera permission if not already granted
      if (camerapermissionStatus != PermissionStatus.granted) {
        log("STARTCAMERA: 2. Checking permission status");
        try {
          camerapermissionStatus = await Permission.camera.status.timeout(
            const Duration(seconds: 2),
          );
          log("STARTCAMERA: 3. Status is $camerapermissionStatus");
          if (camerapermissionStatus != PermissionStatus.granted) {
            log("STARTCAMERA: 4. Requesting permission");
            camerapermissionStatus = await Permission.camera.request().timeout(
              const Duration(seconds: 3),
            );
            log("STARTCAMERA: 5. Request result is $camerapermissionStatus");
          }
        } catch (e) {
          log("STARTCAMERA: Permission check timed out or failed: $e");
          camerapermissionStatus = PermissionStatus.denied;
        }

        if (camerapermissionStatus != PermissionStatus.granted) {
          log("STARTCAMERA: 6. Permission not granted, returning");
          readyCameraPreviewshow = false;
          cameraisLoading = false;
          notifyListeners();
          return;
        }
      }

      // Fast path: Reuse previously queried camera hardware list
      if (cameras == null || cameras!.isEmpty) {
        log("STARTCAMERA: 7. Getting available cameras");
        try {
          cameras = await availableCameras().timeout(const Duration(seconds: 3));
          log("STARTCAMERA: 8. Got ${cameras?.length} cameras");
        } catch (e) {
          log("STARTCAMERA: availableCameras timeout or error: $e");
          readyCameraPreviewshow = false;
          cameraisLoading = false;
          notifyListeners();
          return;
        }
      }

      if (cameras == null || cameras!.isEmpty) {
        log("STARTCAMERA: 9. No cameras found, returning");
        readyCameraPreviewshow = false;
        cameraisLoading = false;
        notifyListeners();
        return;
      }

      CameraDescription selectedCamera = cameras!.firstWhere(
        (camera) => setDirection == 0
            ? camera.lensDirection == CameraLensDirection.front
            : camera.lensDirection == CameraLensDirection.back,
      );

      log("STARTCAMERA: 10. Disposing old controller");
      final oldController = cameraController;
      cameraController = null;
      if (oldController != null) {
        if (oldController.value.isStreamingImages) {
          try {
            await oldController.stopImageStream();
          } catch (_) {}
        }
        try {
          await oldController.dispose().timeout(const Duration(seconds: 2));
          log("STARTCAMERA: 11. Disposed old controller");
        } catch (e) {
          log("STARTCAMERA: oldController dispose error: $e");
        }
      }

      if (sessionId != _cameraSessionId) {
        log("STARTCAMERA: 12. Session ID mismatch after dispose, returning");
        // Reset loading flags so the UI doesn't freeze on a spinner forever.
        cameraisLoading = false;
        readyCameraPreviewshow = false;
        notifyListeners();
        return;
      }

      log("STARTCAMERA: 13. Initializing new controller");
      final newController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      cameraController = newController;
      try {
        await cameraController!.initialize().timeout(
          const Duration(seconds: 5),
        );
        log("STARTCAMERA: 14. Initialized new controller successfully");

        // Non-blocking zoom and brightness adjustments so camera readiness is instant
        cameraController!.getMinZoomLevel().then((minZoom) {
          cameraController?.setZoomLevel(minZoom).catchError((_) {});
        }).catchError((_) {});
        ScreenBrightness().setScreenBrightness(1.0).catchError((_) {});

        // Brightness streaming disabled to prevent camera platform crashes
        isDarkEnvironment = false;
      } catch (e) {
        log("STARTCAMERA: Camera initialize timeout or error: $e");
        readyCameraPreviewshow = false;
        cameraisLoading = false;
        notifyListeners();
        return;
      }

      if (sessionId != _cameraSessionId) {
        log(
          "STARTCAMERA: 15. Session ID mismatch after init, disposing and returning",
        );
        try {
          await newController.dispose().timeout(const Duration(seconds: 2));
        } catch (e) {}
        // Reset loading flags so the UI doesn't freeze on a spinner forever.
        cameraisLoading = false;
        readyCameraPreviewshow = false;
        notifyListeners();
        return;
      }
      log("STARTCAMERA: 16. Camera is completely ready!");
      isCameraReady = true;
      readyCameraPreviewshow = false;
    } on CameraException catch (e) {
      log("STARTCAMERA: CameraException: $e");
      readyCameraPreviewshow = false;
      isCameraReady = false;
    } catch (e) {
      log("STARTCAMERA: General Exception: $e");
      readyCameraPreviewshow = false;
      isCameraReady = false;
    } finally {
      log("STARTCAMERA: 17. Finally block executed");
      cameraisLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchCamera() async {
    if (cameras == null || cameras!.isEmpty || cameraController == null) return;
    final sessionId = ++_cameraSessionId;

    isFrontCamera = !isFrontCamera;
    isCameraReady = false;
    readyCameraPreviewshow = true;
    notifyListeners();

    final newCamera = cameras!.firstWhere(
      (camera) =>
          camera.lensDirection ==
          (isFrontCamera
              ? CameraLensDirection.front
              : CameraLensDirection.back),
    );

    final oldController = cameraController;
    cameraController = null;
    if (oldController != null) {
      if (oldController.value.isStreamingImages) {
        try {
          await oldController.stopImageStream();
        } catch (_) {}
      }
      try {
        await oldController.dispose().timeout(const Duration(seconds: 2));
      } catch (e) {
        log("switchCamera dispose error: $e");
      }
    }
    if (sessionId != _cameraSessionId) return;

    final newController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    cameraController = newController;

    try {
      await newController.initialize().timeout(const Duration(seconds: 5));

      // Set to max zoom out (min zoom level)
      try {
        final double minZoom = await newController.getMinZoomLevel();
        await newController.setZoomLevel(minZoom);
      } catch (e) {
        log("Could not set min zoom level on switch: $e");
      }
    } catch (e) {
      log("switchCamera initialize timeout or error: $e");
      await newController.dispose();
      cameraController = null;
      isCameraReady = false;
      readyCameraPreviewshow = false;
      notifyListeners();
      return;
    }
    if (sessionId != _cameraSessionId) {
      await newController.dispose();
      cameraController = null;
      return;
    }
    isCameraReady = true;
    readyCameraPreviewshow = false;
    notifyListeners();
  }

  Future<void> disposeCamera() async {
    _cameraSessionId++;
    final oldController = cameraController;
    cameraController = null;
    isCameraReady = false;
    readyCameraPreviewshow = true;
    showFlashOverlay = false;

    // Restore screen brightness
    try {
      await ScreenBrightness().resetScreenBrightness();
    } catch (_) {}

    if (oldController != null) {
      if (oldController.value.isStreamingImages) {
        try {
          await oldController.stopImageStream();
        } catch (_) {}
      }
      try {
        await oldController.dispose().timeout(const Duration(seconds: 2));
      } catch (e) {
        log("disposeCamera error: $e");
      }
    }
    notifyListeners();
  }

  Future<void> takePicture() async {
    try {
      if (cameraController == null ||
          cameraController!.value.isInitialized == false) {
        return;
      }
      if (cameraController!.value.isStreamingImages) {
        try {
          await cameraController!.stopImageStream();
        } catch (_) {}
      }
      picture = await cameraController!.takePicture();
      if (picture != null) {
        imageFile = File(picture!.path);
      }
    } catch (e) {
      /* ignored */
    }
  }

  Future<File> flipCapturedImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fixedBytes = await Isolate.run(() {
        final originalImage = img.decodeImage(bytes);
        if (originalImage == null) return bytes;
        final flippedImage = img.flipHorizontal(originalImage);
        return img.encodeJpg(flippedImage);
      });
      if (fixedBytes == bytes) return file;
      final newFile = File(file.path)..writeAsBytesSync(fixedBytes);
      return newFile;
    } catch (e) {
      return file;
    }
  }

  // ==================== LOCATION FUNCTIONS ====================
  Position? currentPosition;
  String? setlongitude;
  String? setlatitude;
  String? currentLocation;
  String? postalCode;
  double distance = 0;
  double allowedRadius = 0;

  // ── Static office coordinates (TAX541 = Surat, TAY967 = Bhavnagar) ──────────
  // These two companies use hardcoded coords. All other companies use dynamic
  // lat / lng / locationRadius returned from the CompanyList API.
  // static const double _staticSuratLat = 21.209324791829328;
  // static const double _staticSuratLng = 72.83361489980567;
  static const double _staticSuratLat = 21.209468;
  static const double _staticSuratLng = 72.833596;
  static const double _staticBhavLat = 21.763838;
  static const double _staticBhavLng = 72.146873;

  /// True for companies that use hardcoded office coordinates.
  bool get _isStaticCompany =>
      curentUser?['CustId'] == 'TAX541' || curentUser?['CustId'] == 'TAY967';

  // ── Dynamic helpers — read from the currently selected company object ────────
  double? get _companyLat => selectedcurentcompany?.latitude;
  double? get _companyLng => selectedcurentcompany?.longitude;
  double? get _companyRadius => selectedcurentcompany?.locationRadius;

  /// True when a non-static company has office coordinates set in the backend.
  bool get _hasCompanyLocation =>
      !_isStaticCompany &&
      _companyLat != null &&
      _companyLng != null &&
      _companyRadius != null &&
      _companyRadius! > 0;

  static bool _isValNullOrEmpty(dynamic val) {
    if (val == null) return true;
    final s = val.toString().trim().toLowerCase();
    return s.isEmpty || s == 'null' || s == '-';
  }

  /// True when attendance from any location is allowed:
  /// - WorkType is 'Home' (case-insensitive)
  /// - Both WorkType and OfficeLocation are null / empty
  /// - Today visit is allowed
  /// - Background location fetch is enabled
  bool get isLocationBypassed {
    final rawWorkType = curentUser?['WorkType'] ?? curentUser?['workType'];
    final bool isWorkTypeNull = _isValNullOrEmpty(rawWorkType);
    final bool isWorkFromHome =
        !isWorkTypeNull &&
        rawWorkType.toString().trim().toLowerCase() == 'home';

    if (isWorkFromHome) return true;

    final rawOfficeLoc =
        curentUser?['OfficeLocation'] ?? curentUser?['officeLocation'];
    final bool isOfficeLocNull = _isValNullOrEmpty(rawOfficeLoc);

    if (isWorkTypeNull && isOfficeLocNull) return true;

    if (checkStatus?.todayVisit == true) return true;

    if (Platform.isAndroid &&
        BackgroundLocationRepository.isFetchLocationEnabled()) {
      return true;
    }

    return false;
  }

  /// Whether office range proximity check is required for this punch.
  bool get needOfficeRangeCheck {
    if (isLocationBypassed) return false;

    if (_isStaticCompany) {
      final rawOfficeLoc =
          curentUser?['OfficeLocation'] ?? curentUser?['officeLocation'];
      return !_isValNullOrEmpty(rawOfficeLoc);
    } else {
      return _hasCompanyLocation;
    }
  }

  /// Whether current location is within allowed punch range.
  bool get isInRange {
    if (!needOfficeRangeCheck) return true;
    return distance <= allowedRadius;
  }

  bool _isFetchingLocation = false;

  Future<void> getCurrentLocation({BuildContext? context}) async {
    if (_isFetchingLocation) return;
    _isFetchingLocation = true;
    // ── 1. INSTANT LOCATION LOAD ──
    try {
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        setlongitude = lastKnown.longitude.toString();
        setlatitude = lastKnown.latitude.toString();
        await _computeDistanceOnly(lastKnown.longitude, lastKnown.latitude);
        await _restoreCachedAddress();
        if (currentLocation == null || currentLocation!.isEmpty) {
          currentLocation = 'Fetching Address...';
        }
        notifyListeners(); // Unlocks UI instantly
      }
    } catch (_) {}

    // ── 2. FETCH LATEST IN BACKGROUND ──
    setLocationLoader(true);
    try {
      currentPosition = await getPosition(context: context);
      if (currentPosition != null) {
        setlongitude = currentPosition!.longitude.toString();
        setlatitude = currentPosition!.latitude.toString();

        // Calculate distance immediately so the "In Range" badge updates instantly
        await _computeDistanceOnly(
          currentPosition!.longitude,
          currentPosition!.latitude,
        );

        // Set temporary address so the punch button unblocks instantly
        currentLocation = 'Fetching Address...';
        notifyListeners();

        // Do slow reverse geocoding in the background
        final bool offline = await _checkIsOffline();
        if (offline) {
          await _restoreCachedAddress();
        } else {
          await getAddressFromLatLng(
            currentPosition!.longitude,
            currentPosition!.latitude,
          );
        }
      }
    } catch (e) {
      showtoastmessage(unableToGetLocationGpsString);
    } finally {
      _isFetchingLocation = false;
      setLocationLoader(false);
      notifyListeners();
    }
  }

  // ── Address cache keys ──────────────────────────────────────────────────────
  static const String _kCachedAddress = 'cached_address';
  static const String _kCachedPostalCode = 'cached_postal_code';

  /// Saves the current address + postalCode to SharedPreferences so it can be
  /// restored when the device is offline.
  Future<void> _saveAddressToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (currentLocation != null) {
        await prefs.setString(_kCachedAddress, currentLocation!);
      }
      if (postalCode != null) {
        await prefs.setString(_kCachedPostalCode, postalCode!);
      }
    } catch (_) {}
  }

  /// Restores the last known address + postalCode from SharedPreferences.
  /// Called when the device is offline so the UI shows the same data as online.
  Future<void> _restoreCachedAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cached = prefs.getString(_kCachedAddress);
      final String? cached_pc = prefs.getString(_kCachedPostalCode);
      if (cached != null && cached.isNotEmpty) {
        currentLocation = cached;
      }
      if (cached_pc != null) {
        postalCode = cached_pc;
      }
    } catch (_) {}
  }

  /// Computes distance/radius without any network call (for offline use).
  Future<void> _computeDistanceOnly(double long, double lat) async {
    if (isLocationBypassed) {
      allowedRadius = 0;
      distance = 0;
      return;
    }
    if (_isStaticCompany) {
      final officeLoc = curentUser?['OfficeLocation'];
      if (officeLoc == null ||
          officeLoc.toString().trim().isEmpty ||
          officeLoc.toString().toLowerCase() == 'null') {
        allowedRadius = 0;
        distance = 0;
      } else {
        final bool isSurat = officeLoc.toString().toLowerCase() == 'surat';
        allowedRadius = isSurat ? 25 : (Platform.isAndroid ? 20 : 25);
        distance = Geolocator.distanceBetween(
          isSurat ? _staticSuratLat : _staticBhavLat,
          isSurat ? _staticSuratLng : _staticBhavLng,
          lat,
          long,
        );
      }
    } else if (_hasCompanyLocation) {
      allowedRadius = _companyRadius!;
      distance = Geolocator.distanceBetween(
        _companyLat!,
        _companyLng!,
        lat,
        long,
      );
    } else {
      allowedRadius = 0;
      distance = 0;
    }
  }

  Future<Position> getPosition({BuildContext? context}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null) {
        bool? openSettings = await showGpsDisabledDialog(context);
        if (openSettings == true) {
          bool isNowEnabled = await Geolocator.isLocationServiceEnabled();
          if (isNowEnabled) {
            return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
          }
        }
      } else {
        await Geolocator.openLocationSettings();
      }
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final bool isFetchLocation =
          BackgroundLocationRepository.isFetchLocationEnabled();
      if (isFetchLocation) {
        // if (Platform.isIOS) {
        //   // iOS: When In Use MUST come before Always (OS-enforced)
        //   permission = await Geolocator.requestPermission();
        //   if (permission != LocationPermission.denied &&
        //       permission != LocationPermission.deniedForever) {
        //     await Permission.locationAlways.request();
        //     await LocationPermissionService.waitForSystemDialogToClose();
        //     permission = await Geolocator.checkPermission();
        //   }
        // } else {
        // Android: request Always directly (single dialog on Android 10)
        if (!Platform.isIOS) {
          await Permission.locationAlways.request();
          await LocationPermissionService.waitForSystemDialogToClose();
          permission = await Geolocator.checkPermission();
        } else {
          // iOS: basic When In Use only (Always flow disabled for now)
          permission = await Geolocator.requestPermission();
        }
        // }
      } else {
        // Normal flow: just When In Use
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
      );
    } catch (e) {
      Position? lastKnown;
      try {
        lastKnown = await Geolocator.getLastKnownPosition();
      } catch (_) {
        /* ignored */
      }
      if (lastKnown != null) {
        return lastKnown;
      }
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e2) {
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest,
            timeLimit: const Duration(seconds: 5),
          );
        } catch (e3) {
          // FINAL SAFETY NET: If testing on iOS Simulator with Location set to 'None',
          // or inside a deep indoor dead zone (kCLErrorDomain error 0), return office coordinates
          // so the user is never blocked from punching in or testing.
          return Position(
            latitude: _isStaticCompany ? _staticSuratLat : (_companyLat ?? 0.0),
            longitude: _isStaticCompany
                ? _staticSuratLng
                : (_companyLng ?? 0.0),
            timestamp: DateTime.now(),
            accuracy: 50.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        }
      }
    }
  }

  Future<void> getAddressFromLatLng(double long, double lat) async {
    // 1. Calculate distance and allowed radius first (does not require internet)
    if (isLocationBypassed) {
      allowedRadius = 0;
      distance = 0;
    } else if (_isStaticCompany) {
      // ── Static path: TAX541 (Surat) / TAY967 (Bhavnagar) ─────────────
      final officeLoc = curentUser?['OfficeLocation'];
      if (officeLoc == null ||
          officeLoc.toString().trim().isEmpty ||
          officeLoc.toString().toLowerCase() == 'null') {
        allowedRadius = 0;
        distance = 0;
      } else {
        final bool isSurat = officeLoc.toString().toLowerCase() == 'surat';
        allowedRadius = isSurat ? 25 : (Platform.isAndroid ? 20 : 25);
        distance = Geolocator.distanceBetween(
          isSurat ? _staticSuratLat : _staticBhavLat,
          isSurat ? _staticSuratLng : _staticBhavLng,
          lat,
          long,
        );
      }
    } else if (_hasCompanyLocation) {
      // ── Dynamic path: company has coords from API ─────────────────────
      allowedRadius = _companyRadius!;
      distance = Geolocator.distanceBetween(
        _companyLat!,
        _companyLng!,
        lat,
        long,
      );
    } else {
      // ── No location config — no distance restriction ──────────────────
      allowedRadius = 0;
      distance = 0;
    }
            
    // 2. Try to get physical address (requires internet)
    try {
      final bool offline = await _checkIsOffline();
      if (!offline) {
        List<Placemark> placemark = await Geocoding()
            .placemarkFromCoordinates(lat, long)
            .timeout(const Duration(seconds: 5));

        if (placemark.isNotEmpty) {
          Placemark place = placemark[0];
          postalCode = place.postalCode;

          if (_isStaticCompany &&
              distance <= allowedRadius &&
              allowedRadius > 0 &&
              curentUser?['OfficeLocation'].toString().toLowerCase() ==
                  'surat') {
            currentLocation =
                '601-602, Shubh square, Laldarwaja Main Rd, Patel Vadi, Patel Nagar, Surat, Gujarat 395004';
          } else {
            currentLocation =
                '${place.subThoroughfare ?? ''} ${place.thoroughfare ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.subAdministrativeArea ?? ''}, ${place.administrativeArea ?? ''} ${place.postalCode ?? ''}, ${place.country ?? ''}';
          }
          // ── Cache the resolved address for offline use ───────────────
          await _saveAddressToCache();
        }
      } else {
        // Offline: restore cached address so display & API data match online mode
        await _restoreCachedAddress();
      }
    } catch (e) {
      // If geocoding fails, try cached address; final fallback = empty string
      await _restoreCachedAddress();
      if (currentLocation == null || currentLocation!.isEmpty) {
        currentLocation = '';
        postalCode = '';
      }
    }

    notifyListeners();
  }

  Future<bool> checkAndPunch(BuildContext context) async {
    Position pos;
    try {
      pos = await getPosition(context: context);
    } catch (e) {
      punchDeniedShowDialog(e.toString(), context);
      return false;
    }

    if (isLocationBypassed) {
      allowedRadius = 0;
      distance = 0;
    } else if (_isStaticCompany) {
      // ── Static path: TAX541 (Surat) / TAY967 (Bhavnagar) ─────────────────
      final officeLoc = curentUser?['OfficeLocation'];
      if (officeLoc == null ||
          officeLoc.toString().trim().isEmpty ||
          officeLoc.toString().toLowerCase() == 'null') {
        allowedRadius = 0;
        distance = 0;
      } else {
        final bool isSurat = officeLoc.toString().toLowerCase() == 'surat';
        allowedRadius = isSurat ? 25 : (Platform.isAndroid ? 20 : 25);
        distance = Geolocator.distanceBetween(
          isSurat ? _staticSuratLat : _staticBhavLat,
          isSurat ? _staticSuratLng : _staticBhavLng,
          pos.latitude,
          pos.longitude,
        );
      }
    } else if (_hasCompanyLocation) {
      // ── Dynamic path: company has coords from API ─────────────────────────
      allowedRadius = _companyRadius!;
      distance = Geolocator.distanceBetween(
        _companyLat!,
        _companyLng!,
        pos.latitude,
        pos.longitude,
      );
    } else {
      allowedRadius = 0;
      distance = 0;
    }
    await getAddressFromLatLng(pos.longitude, pos.latitude);
    return true;
  }

  // ==================== ATTENDANCE FUNCTIONS ====================
  AttendanceDayBlog? checkStatus;
  DateTime dateTime = DateTime.now();
  DateTime get newDateTime =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  GetShiftMasterData? getUserShift;
  DateTime showInTime = DateTime.now();
  DateTime showoutTime = DateTime.now();
  bool setOutTime = false;
  String showTotalHours = '';

  // Punch box state
  TextEditingController punchBoxNotesController = TextEditingController();
  bool punchBoxOnTapStart = false;
  bool punchBoxIsKeyboardOpen = false;

  void setPunchBoxNotes(String value) {
    punchBoxNotesController.text = value;
    notifyListeners();
  }

  void setPunchBoxOnTapStart(bool value) {
    punchBoxOnTapStart = value;
    notifyListeners();
  }

  void setPunchBoxKeyboardOpen(bool value) {
    punchBoxIsKeyboardOpen = value;
    notifyListeners();
  }

  // Pre-punch checks tracking
  ValueNotifier<String> punchProcessStatus = ValueNotifier<String>(
    'Processing...',
  );
  bool isPrePunchChecksLoading = false;
  bool isPrePunchChecksSuccess = false;

  // ── Offline helper ──────────────────────────────────────────────────────────
  static Future<bool> _checkIsOffline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.contains(ConnectivityResult.none) || result.isEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> processPrePunchChecks(BuildContext context) async {
    // In release builds, block Punch if Developer Mode is enabled
    if (await DeveloperModeService.isDeveloperModeRestricted()) {
      isPrePunchChecksLoading = false;
      notifyListeners();
      if (context.mounted) {
        Navigator.pop(context); // Close punch confirmation dialog
        DeveloperModeService.showDeveloperModeWarningDialog(context);
      }
      return;
    }

    isPrePunchChecksLoading = true;
    isPrePunchChecksSuccess = false;
    punchProcessStatus.value = 'Processing...';
    notifyListeners();

    try {
      final bool offline = await _checkIsOffline();

      if (offline) {
        // ── OFFLINE PATH ────────────────────────────────────────────────────
        // Skip server auth + history fetch — use cached state.
        // Location/radius check below still uses cached company coordinates.
        punchProcessStatus.value = 'Offline mode — checking location...';

        // If no company location config is available offline, block the punch.
        if (needOfficeRangeCheck && !_isStaticCompany && !_hasCompanyLocation) {
          showtoastmessage(
            'Location configuration is unavailable offline. '
            'Connect to the internet and try again.',
          );
          Navigator.pop(context); // Close dialog
          return;
        }
      } else {
        // ── ONLINE PATH ─────────────────────────────────────────
        punchProcessStatus.value = 'Syncing attendance...';
        if (checkStatus == null || checkStatus!.attendenceLog == null) {
          await refreshLastPunchOnly(curentUser['Id']);
          if (!context.mounted) return;
        }
      }

      punchProcessStatus.value = 'Checking Location Range...';
      if (needOfficeRangeCheck) {
        final bool locationSuccess = await checkAndPunch(context);
        if (!context.mounted) return;

        if (!locationSuccess) {
          Navigator.pop(context); // Close dialog
          return;
        }

        if (distance > allowedRadius) {
          Navigator.pop(context); // Close dialog
          punchDeniedShowDialog(
            "You are not within the Company selected area, Punch is not allowed.",
            context,
          );
          return;
        }
      }

      isPrePunchChecksSuccess = true;
      punchProcessStatus.value = offline
          ? 'Ready to punch offline!'
          : 'Ready to Punch!';
    } catch (e) {
      showtoastmessage(checksFailedString);
      Navigator.pop(context); // Close dialog
    } finally {
      isPrePunchChecksLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkLastPunch(
    int employeid,
    BuildContext context, {
    bool showLoading = false,
  }) async {
    if (showLoading) setLoading(true);
    try {
      final compId =
          selectedcurentcompany?.companyId ?? curentUser?['CompanyId'] ?? 0;
      final targetDate = DateTime.now();
      checkStatus = await AttendanceApis().getDateBlogEmp(
        DateTime(targetDate.year, targetDate.month, targetDate.day),
        employeid,
        compId,
      );
    } catch (e) {
      /* ignored */
    } finally {
      if (checkStatus == null) {
        checkStatus = AttendanceDayBlog(attendenceLog: []);
      } else if (checkStatus!.attendenceLog == null) {
        checkStatus!.attendenceLog = [];
      }
      await _mergePendingOfflinePunches(employeid);
      _sortLogsAscending();
      if (showLoading) setLoading(false);
    }
    notifyListeners();
  }

  Future<void> refreshLastPunchOnly(
    int employeid, {
    bool showLoading = false,
  }) async {
    if (showLoading) setLoading(true);
    try {
      final compId =
          selectedcurentcompany?.companyId ?? curentUser?['CompanyId'] ?? 0;
      final targetDate = DateTime.now();
      checkStatus = await AttendanceApis().getDateBlogEmp(
        DateTime(targetDate.year, targetDate.month, targetDate.day),
        employeid,
        compId,
      );
    } catch (e) {
      /* ignored */
    } finally {
      if (checkStatus == null) {
        checkStatus = AttendanceDayBlog(attendenceLog: []);
      } else if (checkStatus!.attendenceLog == null) {
        checkStatus!.attendenceLog = [];
      }
      await _mergePendingOfflinePunches(employeid);
      _sortLogsAscending();
      if (showLoading) setLoading(false);
    }
    notifyListeners();
  }

  void _sortLogsAscending() {
    if (checkStatus?.attendenceLog != null) {
      checkStatus!.attendenceLog!.sort((a, b) {
        final rawA = (a.time ?? a.attendenceDate ?? '').toString().trim();
        final rawB = (b.time ?? b.attendenceDate ?? '').toString().trim();
        final dtA = DateTime.tryParse(rawA);
        final dtB = DateTime.tryParse(rawB);
        if (dtA != null && dtB != null) {
          return dtA.compareTo(dtB);
        }
        return rawA.compareTo(rawB);
      });
    }
  }

  Future<void> _mergePendingOfflinePunches(int employeid) async {
    try {
      final today = DateTime.now();
      final String dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final allOfflineRecords = await OfflinePunchSyncService.instance
          .getAllRecords();

      final todayOfflineRecords = allOfflineRecords.where((r) {
        if (r.empId != employeid) return false;
        try {
          final DateTime rTime = DateTime.parse(r.punchTimestamp);
          final String rDateKey =
              '${rTime.year}-${rTime.month.toString().padLeft(2, '0')}-${rTime.day.toString().padLeft(2, '0')}';
          return rDateKey == dateKey;
        } catch (_) {
          return false;
        }
      }).toList();

      checkStatus ??= AttendanceDayBlog();
      checkStatus!.attendenceLog ??= [];

      for (final r in todayOfflineRecords) {
        final bool alreadyExists = checkStatus!.attendenceLog!.any(
          (log) => (log.cguid ?? '').isNotEmpty && log.cguid == r.cguid,
        );
        if (!alreadyExists) {
          checkStatus!.attendenceLog!.add(
            AttendenceLog(
              logId: -1,
              empId: r.empId,
              status: r.punchStatus,
              time: r.punchTimestamp,
              attendenceDate: r.attendenceDate,
              cguid: r.cguid,
              location: r.location,
              latitude: r.latitude,
              longitude: r.longitude,
              isOffline: true,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> callApi(BuildContext context) async {
    // ── 1. INSTANT CACHE LOAD: show last known punch status instantly ──
    await _loadOfflinePunchStatus();

    final bool offline = await _checkIsOffline();
    if (offline) {
      return;
    }

    // ── 2. ONLINE PATH: fetch from server in background to get latest ──
    await refreshLastPunchOnly(curentUser['Id']);
    if (!context.mounted) return;
    if (checkStatus != null &&
        checkStatus!.attendenceLog != null &&
        checkStatus!.attendenceLog!.isNotEmpty) {
      if (checkStatus!.attendenceLog!.last.status == 'IN') {
        if (setlatitude == null && setlongitude == null) {
          await getCurrentLocation(context: context);
        }
        if (setlatitude != null && setlongitude != null) {
          await LocationBatchStorage.appendLocation(
            latitude: double.parse(setlatitude!),
            longitude: double.parse(setlongitude!),
            entryTime: DateTime.now(),
          );
          final String userDataStr = await SaveUser().getUserDatas();
          if (userDataStr.isNotEmpty) {
            final dynamic userData = jsonDecode(userDataStr);
            await LocationBatchStorage.uploadPendingBatch(
              userData: userData,
              isMapScreen: false,
              isAppForeground: true,
            );
          }
        }
      }
    }
  }

  /// Loads cached punch status from SharedPreferences and OfflinePunchSyncService for offline mode.
  /// Ensures the Punch IN / Punch OUT button status is calculated correctly.
  Future<void> _loadOfflinePunchStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final DateTime today = DateTime.now();
      final String dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      checkStatus ??= AttendanceDayBlog();
      checkStatus!.attendenceLog ??= [];

      // Filter out any logs in checkStatus that are NOT from today
      checkStatus!.attendenceLog!.removeWhere((log) {
        final rawVal = (log.time ?? log.attendenceDate ?? '').toString().trim();
        if (rawVal.isEmpty) return true;
        DateTime? logTime = DateTime.tryParse(rawVal);
        if (logTime == null && log.attendenceDate != null) {
          logTime = DateTime.tryParse(log.attendenceDate.toString().trim());
        }
        if (logTime != null) {
          final String logDateKey =
              '${logTime.year}-${logTime.month.toString().padLeft(2, '0')}-${logTime.day.toString().padLeft(2, '0')}';
          return logDateKey != dateKey;
        }
        return false;
      });

      // Fetch all offline queued records for today
      final allOfflineRecords = await OfflinePunchSyncService.instance
          .getAllRecords();

      final todayOfflineRecords = allOfflineRecords.where((r) {
        try {
          final DateTime rTime = DateTime.parse(r.punchTimestamp);
          final String rDateKey =
              '${rTime.year}-${rTime.month.toString().padLeft(2, '0')}-${rTime.day.toString().padLeft(2, '0')}';
          return rDateKey == dateKey;
        } catch (_) {
          return false;
        }
      }).toList();

      for (final r in todayOfflineRecords) {
        final bool alreadyExists = checkStatus!.attendenceLog!.any(
          (log) => (log.cguid ?? '').isNotEmpty && log.cguid == r.cguid,
        );
        if (!alreadyExists) {
          checkStatus!.attendenceLog!.add(
            AttendenceLog(
              logId: -1,
              empId: r.empId,
              status: r.punchStatus,
              time: r.punchTimestamp,
              attendenceDate: r.attendenceDate,
              cguid: r.cguid,
              location: r.location,
              latitude: r.latitude,
              longitude: r.longitude,
              isOffline: true,
            ),
          );
        }
      }

      // Fallback to boolean flags if still empty
      if (checkStatus!.attendenceLog!.isEmpty) {
        final bool punchedIn = prefs.getBool('punched_in_$dateKey') ?? false;
        final bool punchedOut = prefs.getBool('punched_out_$dateKey') ?? false;

        final DateTime workingDate = DateTime(
          today.year,
          today.month,
          today.day,
        );
        final int empId = curentUser != null
            ? (curentUser['Id'] as int? ?? 0)
            : 0;

        if (punchedIn && !punchedOut) {
          checkStatus!.attendenceLog!.add(
            AttendenceLog(
              logId: -1,
              empId: empId,
              status: 'IN',
              time: today.toIso8601String(),
              attendenceDate: workingDate.toIso8601String(),
              cguid: 'offline_cached_in',
              isOffline: true,
            ),
          );
        } else if (punchedOut) {
          checkStatus!.attendenceLog!.add(
            AttendenceLog(
              logId: -1,
              empId: empId,
              status: 'IN',
              time: today.toIso8601String(),
              attendenceDate: workingDate.toIso8601String(),
              cguid: 'offline_cached_in',
              isOffline: true,
            ),
          );
          checkStatus!.attendenceLog!.add(
            AttendenceLog(
              logId: -2,
              empId: empId,
              status: 'OUT',
              time: today.toIso8601String(),
              attendenceDate: workingDate.toIso8601String(),
              cguid: 'offline_cached_out',
              isOffline: true,
            ),
          );
        }
      }

      // Sort attendenceLog by time ascending so last element is the latest punch
      checkStatus!.attendenceLog!.sort((a, b) {
        final String tA = (a.time ?? '').toString();
        final String tB = (b.time ?? '').toString();
        return tA.compareTo(tB);
      });

      notifyListeners();
    } catch (_) {}
  }

  Future<void> punchNowCall(
    BuildContext context,
    int employeid,
    File userImages,
    String setUsreLoaction,
    String usersetLatitude,
    String usersetLongitude,
    String setUserRemarks,
    bool setweekoffStatus, [
    bool isFromWidget = false,
  ]) async {
    PunchPerformanceTracker.step('punchNowCall: Started');
    // Validation before calling the Punch API
    if (await DeveloperModeService.isDeveloperModeRestricted()) {
      log('[SelfiePunchProvider] Punch API blocked: Developer Mode active in release build.');
      PunchPerformanceTracker.step('punchNowCall: Blocked by Developer Mode');
      PunchPerformanceTracker.finish(isSuccess: false, message: 'Developer Mode active');
      setPunchBoxOnTapStart(false);
      setPunchLoader(false);
      if (context.mounted) {
        DeveloperModeService.showDeveloperModeWarningDialog(context);
      }
      return;
    }
    PunchPerformanceTracker.step('punchNowCall: Developer Mode Check Passed');

    final bool offline = await _checkIsOffline();
    PunchPerformanceTracker.step('punchNowCall: Offline Check Done', 'Offline: $offline');

    if (offline) {
      // ═══════════════════════════════════════════════════════════════════════
      // OFFLINE PATH — save to local queue; do NOT call any server API
      // ═══════════════════════════════════════════════════════════════════════
      final bool saved = await _saveOfflinePunch(
        context: context,
        employeid: employeid,
        setUsreLoaction: setUsreLoaction,
        usersetLatitude: usersetLatitude,
        usersetLongitude: usersetLongitude,
        setUserRemarks: setUserRemarks,
        setweekoffStatus: setweekoffStatus,
      );
      setPunchBoxOnTapStart(false);
      setPunchLoader(false);

      if (!saved) {
        log('🔴 [SelfiePunchProvider] Offline punch saving failed. STRICTLY KEEPING APP OPEN.');
        return;
      }

      showtoastmessage(punchSavedOfflineString);

      if (!context.mounted) return;
      if (isFromWidget) {
        final navigator = Navigator.of(context);
        navigator.pop(); // Pop the dialog

        // CRITICAL: Stop the camera before closing the app to prevent ImageReader Surface crashes
        await disposeCamera();

        try {
          await const MethodChannel(
            'punch_widget/open',
          ).invokeMethod('move_to_background');
        } catch (_) {}
        SystemNavigator.pop();
      } else {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const AttendanceScreen(empData: null),
          ),
        );
      }

      return;
    }

    // =========================================================================
    // ONLINE PATH — original implementation, 100% unchanged
    // =========================================================================
    String setGuid = generateCustomUuid();
    final navigator = Navigator.of(context);

    try {
      PunchPerformanceTracker.step('AttendanceApis: Sending callPunch API Request');
      final response = await AttendanceApis().callPunch(
        sendCguid: setGuid.toString(),
        setRemarks: setUserRemarks,
        weekoffStatus: setweekoffStatus,
      );
      PunchPerformanceTracker.step('AttendanceApis: callPunch API Response Received');

      PunchNow punchResponse = response as PunchNow;
      if (punchResponse.success == true) {
        final String punchStatus =
            punchResponse.attendenceLog!.last.status ?? '';
        showtoastmessage('$punchString $punchStatus $successfullyString');

        // ── Explicitly log punch location to timeline batch ────────
        try {
          if (usersetLatitude.isNotEmpty && usersetLongitude.isNotEmpty) {
            await LocationBatchStorage.appendLocation(
              latitude: double.parse(usersetLatitude),
              longitude: double.parse(usersetLongitude),
              entryTime: DateTime.now(),
            );
          }
        } catch (_) {}

        // ── Location tracking & timeline batch upload (Background Unawaited) ──
        if (context.mounted) {
          final locationTracker = Provider.of<LocationTrackingProvider>(
            context,
            listen: false,
          );
          unawaited(Future(() async {
            try {
              if (punchStatus == 'IN') {
                await locationTracker.startTracking();
              } else if (punchStatus == 'OUT') {
                locationTracker.stopTracking();
              }

              final String userDataStr = await SaveUser().getUserDatas();
              if (userDataStr.isNotEmpty) {
                final dynamic userData = jsonDecode(userDataStr);
                await LocationBatchStorage.uploadPendingBatch(
                  userData: userData,
                  isMapScreen: false,
                  isAppForeground: true,
                );
              }
            } catch (e) {
              log('[SelfiePunchProvider] Background tracking/batch upload error: $e');
            }
          }));
        }
        // ──────────────────────────────────────────────────────────

        // Reschedule reminders now that punch status is persisted correctly.
        Future.microtask(() async {
          try {
            final prefs = await SharedPreferences.getInstance();
            final DateTime now = DateTime.now();
            final String dateKey =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
            if (punchStatus == 'IN') {
              await prefs.setBool('punched_in_\$dateKey', true);
              await prefs.setBool('punched_out_\$dateKey', false);
            } else if (punchStatus == 'OUT') {
              await prefs.setBool('punched_out_\$dateKey', true);
            }
          } catch (_) {}
          await ReminderNotificationService.scheduleReminders();
        });

        // Run refreshLastPunchOnly in background so navigation happens instantly without network block
        unawaited(refreshLastPunchOnly(employeid));
        if (context.mounted) {
          try {
            Provider.of<HomeProvider>(
              context,
              listen: false,
            ).refreshWorkingHours(context);
          } catch (_) {}
        }
        PunchPerformanceTracker.step('punchNowCall: Punch API Confirmed');
        PunchPerformanceTracker.finish(isSuccess: true, message: 'Punch $punchStatus confirmed');

        // ── 1. Upload selfie photo while strictly remaining in the FOREGROUND ──
        log('🟠 [SelfiePunchProvider] Punch API confirmed! Uploading photo in foreground before any navigation...');
        punchProcessStatus.value = 'Uploading photo...';
        notifyListeners();

        // Resolve valid upload file: check userImages first, fallback to lastPersistedSelfiePath
        File? uploadFile = userImages;
        if (!uploadFile.existsSync() || uploadFile.lengthSync() == 0) {
          if (lastPersistedSelfiePath != null) {
            final fallback = File(lastPersistedSelfiePath!);
            if (fallback.existsSync() && fallback.lengthSync() > 0) {
              uploadFile = fallback;
              log('[SelfiePunchProvider] Using fallback persisted selfie: ${fallback.path}');
            }
          }
        }

        bool isImageUploadSuccess = false;
        const int maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
          punchProcessStatus.value = 'Uploading photo ($attempt/$maxAttempts)...';
          notifyListeners();
          try {
            PunchPerformanceTracker.step('AttendanceApis: Uploading Selfie Photo (attempt #$attempt)');
            final uploadResult = await AttendanceApis().callWithImgPunch(
              listenRes: (val) {
                log('[SelfiePunchProvider] callWithImgPunch response: $val');
              },
              FILES: uploadFile,
              setCguid: setGuid,
              setLatitude: usersetLatitude,
              setLocation: setUsreLoaction,
              setLongitude: usersetLongitude,
            );
            if (uploadResult != null) {
              isImageUploadSuccess = true;
              PunchPerformanceTracker.step('AttendanceApis: Selfie Photo Uploaded');
              log('🟢 [SelfiePunchProvider] Image upload succeeded on attempt #$attempt.');
              break;
            } else {
              log('🟠 [SelfiePunchProvider] Image upload returned null on attempt #$attempt');
            }
          } catch (e) {
            PunchPerformanceTracker.step('AttendanceApis: Selfie Upload Error ($e)');
            log('🟠 [SelfiePunchProvider] Image upload attempt #$attempt error: $e');
          }
          if (!isImageUploadSuccess && attempt < maxAttempts) {
            await Future.delayed(Duration(milliseconds: attempt * 1000));
          }
        }

        setPunchBoxOnTapStart(false);
        setPunchLoader(false);

        // ── 2. Strictly close widget ONLY if BOTH punch API and image upload succeeded ──
        if (isFromWidget) {
          if (isImageUploadSuccess) {
            log('🟢 [WidgetDebug] Punch API & Image Upload BOTH succeeded! Strictly closing widget app.');
            imageFile = null;
            lastPersistedSelfiePath = null;
            if (context.mounted) {
              final nav = Navigator.of(context);
              nav.pop(); // Pop the dialog
            }
            await disposeCamera();
            try {
              await const MethodChannel(
                'punch_widget/open',
              ).invokeMethod('move_to_background');
            } catch (_) {}
            SystemNavigator.pop();
          } else {
            log('🔴 [WidgetDebug] Image upload failed ($isImageUploadSuccess). STRICTLY KEEPING APP OPEN.');
            showtoastmessage(LanguageProvider.translate(
              'punchRecordedPhotoPending',
              'Punch recorded, but photo upload failed. Please keep app open to sync.',
            ));
            // CRITICAL: DO NOT call move_to_background!
            // CRITICAL: DO NOT call SystemNavigator.pop()!
            // App strictly stays open so the user can verify, retry, or stay connected until sync.
            if (context.mounted) {
              final nav = Navigator.of(context);
              nav.pop();
            }
          }
        } else {
          imageFile = null;
          lastPersistedSelfiePath = null;
          if (context.mounted) {
            final nav = Navigator.of(context);
            nav.pop();
            nav.push(
              MaterialPageRoute(
                builder: (context) => const AttendanceScreen(empData: null),
              ),
            );
          }
        }
      } else {
        log('🔴 [SelfiePunchProvider] Punch API response success != true. STRICTLY KEEPING APP OPEN.');
        setPunchBoxOnTapStart(false);
        setPunchLoader(false);
        showtoastmessage(punchTryAgainString);
      }
    } catch (e) {
      log('🔴 [SelfiePunchProvider] Punch API error: $e. STRICTLY KEEPING APP OPEN.');
      setPunchBoxOnTapStart(false);
      setPunchLoader(false);
      showtoastmessage(errorOccurredString);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Save offline punch to local queue
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> _saveOfflinePunch({
    required BuildContext context,
    required int employeid,
    required String setUsreLoaction,
    required String usersetLatitude,
    required String usersetLongitude,
    required String setUserRemarks,
    required bool setweekoffStatus,
  }) async {
    try {
      final String localId = generateCustomUuid();
      final DateTime now = DateTime.now();

      // Determine punch status from current in-memory state (same logic as online)
      final String punchStatus =
          (checkStatus == null ||
              checkStatus!.attendenceLog == null ||
              checkStatus!.attendenceLog!.isEmpty)
          ? 'IN'
          : (checkStatus!.attendenceLog!.last.status == 'IN' ? 'OUT' : 'IN');

      // Working date (start of day ISO)
      final DateTime workingDate = DateTime(now.year, now.month, now.day);

      // Company details from cached global
      final int companyId = selectedcurentcompany?.companyId ?? 0;
      final String custId =
          selectedcurentcompany?.custId ??
          curentUser?['CustId']?.toString() ??
          '';

      final record = OfflinePunchRecord(
        localId: localId,
        cguid: localId, // same as localId for API idempotency
        empId: employeid,
        companyId: companyId,
        custId: custId,
        punchStatus: punchStatus,
        attendenceDate: workingDate.toIso8601String(),
        punchTimestamp: now.toIso8601String(),
        latitude: usersetLatitude,
        longitude: usersetLongitude,
        location: setUsreLoaction,
        postalCode: postalCode,
        remarks: setUserRemarks,
        weekOff: setweekoffStatus,
        persistentImagePath: lastPersistedSelfiePath,
        syncStatus: OfflineSyncStatus.pending,
      );

      await OfflinePunchSyncService.instance.savePendingPunch(record);

      // ── Register dedicated WorkManager task so sync fires when internet returns
      // even if the app is completely closed. Works for ALL users regardless
      // of IsFetchLocation flag, role, or whether location tracking is active.
      unawaited(registerOfflineSyncWorkManager());

      // ── Update local SharedPreferences punch cache so UI reflects new state ─
      final prefs = await SharedPreferences.getInstance();
      final dateKey =
          '${workingDate.year}-${workingDate.month.toString().padLeft(2, '0')}-${workingDate.day.toString().padLeft(2, '0')}';
      if (punchStatus == 'IN') {
        await prefs.setBool('punched_in_$dateKey', true);
        await prefs.setBool('punched_out_$dateKey', false);
      } else {
        await prefs.setBool('punched_out_$dateKey', true);
      }

      // ── Update in-memory checkStatus so button flips correctly ──────────────
      // Create a synthetic log entry to mirror the new punch state.
      checkStatus ??= AttendanceDayBlog();
      checkStatus!.attendenceLog ??= [];
      checkStatus!.attendenceLog!.add(
        AttendenceLog(
          logId: -1, // Synthetic — not from server
          empId: employeid,
          status: punchStatus,
          time: now.toIso8601String(),
          attendenceDate: workingDate.toIso8601String(),
          cguid: localId,
          isOffline: true,
        ),
      );
      notifyListeners();

      if (context.mounted) {
        try {
          Provider.of<HomeProvider>(
            context,
            listen: false,
          ).refreshWorkingHours(context);
        } catch (_) {}
      }

      showtoastmessage(punchSavedOfflineWillSyncString);
      return true;
    } catch (e) {
      showtoastmessage(failedToSaveOfflineString);
      return false;
    }
  }

  /// Path where the persisted selfie was copied for offline punches.
  String? lastPersistedSelfiePath;

  Future<void> puchInOutHandleSubmit(
    BuildContext context,
    String currentDay, [
    bool isFromWidget = false,
    bool skipFaceVerification = false,
  ]) async {
    log('[PunchFlow] ==================== puchInOutHandleSubmit STARTED ====================');
    log('[PunchFlow] currentDay: $currentDay, isFromWidget: $isFromWidget, skipFaceVerification: $skipFaceVerification');
    log('[PunchFlow] curentUser ID: ${curentUser?['Id']}, Name: ${curentUser?['UserName']}');
    log('[PunchFlow] PunchLoader: $PunchLoader');
    if (PunchLoader == true) {
      log('[PunchFlow] WARNING: PunchLoader was true. Resetting to false to allow punch to proceed.');
      PunchLoader = false;
    }

    // In release builds, block Punch In/Out if Developer Mode is enabled
    if (await DeveloperModeService.isDeveloperModeRestricted()) {
      log('[SelfiePunchProvider] Punch blocked: Developer Mode active in release build.');
      if (context.mounted) {
        DeveloperModeService.showDeveloperModeWarningDialog(context);
      }
      return;
    }

    // Only fetch fresh location if not already obtained
    if (setlatitude == null || setlatitude!.isEmpty || setlongitude == null || setlongitude!.isEmpty) {
      log('[PunchFlow] Fetching current location coordinates...');
      await getCurrentLocation(context: context);
      log(
        '[PunchFlow] Location fetched. Distance: $distance, Allowed Radius: $allowedRadius, needOfficeRangeCheck: $needOfficeRangeCheck, Lat: $setlatitude, Lng: $setlongitude',
      );
    } else {
      log('[PunchFlow] Location already available (Lat: $setlatitude, Lng: $setlongitude, Distance: $distance). Skipping redundant fetch.');
    }

    if (needOfficeRangeCheck && distance > allowedRadius) {
      log(
        '[PunchFlow] BLOCKED: Distance ($distance) is greater than allowed radius ($allowedRadius). Showing Out of Range dialog.',
      );
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                      Icons.location_off_rounded,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Out of Range",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "You are ${distance.toStringAsFixed(1)}m away from the office. Please move within the allowed ${allowedRadius}m radius to punch.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Okay",
                        style: TextStyle(
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
          ),
        );
      }
      return;
    }

    log('Setting PunchLoader to true');
    setPunchLoader(true);
    try {
      log('Fetching shift data...');
      // Fetch shift data in the background while processing face
      final shiftDataFuture = shiftMasterDataGet(context);

      String punchTypeString =
          (checkStatus == null ||
              checkStatus!.attendenceLog == null ||
              checkStatus!.attendenceLog!.isEmpty)
          ? punchInString
          : (checkStatus!.attendenceLog!.last.status == 'IN'
                ? punchOutString
                : punchInString);

      String internalPunchType =
          (checkStatus == null ||
              checkStatus!.attendenceLog == null ||
              checkStatus!.attendenceLog!.isEmpty)
          ? 'IN'
          : (checkStatus!.attendenceLog!.last.status == 'IN' ? 'OUT' : 'IN');

      log('punchTypeString: $punchTypeString');
      log('internalPunchType: $internalPunchType');

      // --- Face Verification Intercept (Silent, in-screen) ---
      bool isVerified = true;
      if (!skipFaceVerification) {
        try {
          final role = curentUser?['Role'];
          final faceId = curentUser?["FaceRegisterId"];
          log(
            'Role: $role, FaceId: $faceId, isFaceVerifyEnabled: ${RemoteConfigServices.isFaceVerifyEnabled}',
          );
          if (!RemoteConfigServices.isFaceVerifyEnabled) {
            // Remote kill-switch: face verification feature is OFF
            log(
              "[SelfiePunchProvider] Face verification disabled via Remote Config.",
            );
            isVerified = true;
          } else if (role != 'Admin') {
            if (faceId == null || faceId.toString().isEmpty) {
              log(
                "[SelfiePunchProvider] Face verification failed: No registered FaceId.",
              );
              isVerified = false; // Strictly enforce face registration
            } else {
              log(
                "[SelfiePunchProvider] Starting live stream face verification for FaceId: $faceId",
              );
              final faceProvider = Provider.of<FaceVerificationProvider>(
                context,
                listen: false,
              );
              if (cameraController != null &&
                  cameraController!.value.isInitialized) {
                isVerified = await faceProvider.verifyLiveStream(
                  cameraController!,
                  faceId.toString(),
                );
              } else {
                isVerified = false;
              }
              log("[SelfiePunchProvider] Face verification result: $isVerified");
            }
          } else {
            log("[SelfiePunchProvider] Admin bypasses face verification.");
            isVerified = true;
          }
        } catch (e) {
          log("[SelfiePunchProvider] Face verification error: $e");
          log('Exception during face verification: $e');
          isVerified = false;
        }
      } else {
        log(
          "[SelfiePunchProvider] Face already verified via FaceSDK. Skipping secondary verification.",
        );
        isVerified = true;
      }

      if (!isVerified) {
        log('Face verification failed. Aborting punch.');
        setPunchLoader(false);
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      verificationFailedString,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      verificationFailedDescString,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
            ),
          );
        }
        return; // Verification failed, abort punch
      }
      // -----------------------------------

      PunchPerformanceTracker.step('puchInOutHandleSubmit: Started');

      // Stop the image stream safely BEFORE taking a picture.
      if (cameraController != null &&
          cameraController!.value.isStreamingImages) {
        try {
          await cameraController!.stopImageStream();
        } catch (_) {}
      }
      PunchPerformanceTracker.step('puchInOutHandleSubmit: Stop Image Stream');

      if (isDarkEnvironment) {
        log('Dark environment detected, showing flash overlay.');
        showFlashOverlay = true;
        notifyListeners();
        // Short delay to let the screen render white before capture
        await Future.delayed(const Duration(milliseconds: 300));
      }

      log('Taking picture immediately after verification...');
      if (imageFile == null && cameraController != null && cameraController!.value.isInitialized) {
        try {
          await takePicture();
          if (imageFile != null &&
              (cameraController!.description.lensDirection ==
                      CameraLensDirection.front ||
                  isFrontCamera)) {
            imageFile = await flipCapturedImage(imageFile!);
          }
        } catch (e) {
          log('takePicture error: $e');
        }
      }
      log('Picture ready. imageFile: ${imageFile?.path}');
      PunchPerformanceTracker.step('puchInOutHandleSubmit: Picture Ready');

      if (isDarkEnvironment) {
        showFlashOverlay = false;
        notifyListeners();
      }

      log('Waiting for shift data...');
      await shiftDataFuture;
      log('Shift data fetched.');
      PunchPerformanceTracker.step('puchInOutHandleSubmit: Shift Data Loaded');

      // Restart camera preview if it was stopped by the verification stream
      if (cameraController != null && cameraController!.value.isInitialized) {
        try {
          // ensure preview is running
          await cameraController!.resumePreview();
        } catch (_) {}
      }

      if (imageFile == null) {
        log('[PunchFlow] ERROR: imageFile is null. Showing error and returning.');
        showtoastmessage(cameraImageNotCapturedString);
        PunchPerformanceTracker.finish(isSuccess: false, message: 'Camera image not captured');
        setPunchLoader(false);
        return;
      }

      // Use the captured image directly without auto-flipping horizontally
      File sendImg = imageFile!;
      log('[PunchFlow] Captured selfie ready: ${sendImg.path}');

      // ── Persist selfie to permanent storage immediately after capture ───────
      lastPersistedSelfiePath =
          await OfflinePunchSyncService.persistSelfieImage(sendImg.path);
      log('[PunchFlow] Selfie persisted at: $lastPersistedSelfiePath');
      PunchPerformanceTracker.step('puchInOutHandleSubmit: Persist Selfie to Storage');

      log('[PunchFlow] Calling onTapPunchs(punchType: $punchTypeString, isVerified: $isVerified)...');
      PunchPerformanceTracker.step('puchInOutHandleSubmit: Calling onTapPunchs');
      await onTapPunchs(context, currentDay, punchTypeString, isFromWidget, isVerified);
      log('[PunchFlow] onTapPunchs completed.');
      setPunchLoader(false); // Hide the loading screen behind the dialog
    } catch (e) {
      PunchPerformanceTracker.finish(isSuccess: false, message: 'Exception: $e');
      log('Exception in puchInOutHandleSubmit: $e');
      showtoastmessage(punchFailedString);
      setPunchLoader(false);
    }
  }

  Future<void> onTapPunchs(
    BuildContext context,
    String currentDay,
    String punchType, [
    bool isFromWidget = false,
    bool isFaceVerified = false,
  ]) async {
    bool setTodayWeekOff = false;
    log(
      '[PunchFlow] >>> In onTapPunchs: Current Day: $currentDay, Punch Type: $punchType, isFaceVerified: $isFaceVerified, currentLocation: $currentLocation <<<',
    );
    if (getUserShift != null) {
      log("getUserShift: $getUserShift");
      String dayAbbr = currentDay.toString().substring(0, 3).toLowerCase();
      if ((getUserShift!.mon != null &&
              getUserShift!.sun == false &&
              dayAbbr == 'sun') ||
          (getUserShift!.mon == false && dayAbbr == 'mon') ||
          (getUserShift!.tue == false && dayAbbr == 'tue') ||
          (getUserShift!.wed == false && dayAbbr == 'wed') ||
          (getUserShift!.thu == false && dayAbbr == 'thu') ||
          (getUserShift!.fri == false && dayAbbr == 'fri') ||
          (getUserShift!.sat == false && dayAbbr == 'sat')) {
        setTodayWeekOff = true;
        notifyListeners();
      }
    }

    if (currentLocation != null) {
      if (!context.mounted) return;

      // Validation before displaying Punch Confirmation
      if (await DeveloperModeService.isDeveloperModeRestricted()) {
        log('[SelfiePunchProvider] Developer Mode active in release build. Blocking Punch Confirmation.');
        setPunchLoader(false);
        if (context.mounted) {
          DeveloperModeService.showDeveloperModeWarningDialog(context);
        }
        return;
      }

      final File? currentImage = imageFile;
      if (currentImage == null) {
        log('[SelfiePunchProvider] imageFile is null before showing PunchBoxConfirmation');
        showtoastmessage(cameraImageNotCapturedString);
        setPunchLoader(false);
        return;
      }

      PunchPerformanceTracker.step('onTapPunchs: Location & Developer Mode Validated');
      punchBoxNotesController.clear();
      setPunchBoxOnTapStart(false);
      isPrePunchChecksLoading = true;
      isPrePunchChecksSuccess = false;
      punchProcessStatus.value = 'Checking location...';
      setPunchLoader(true);
      PunchPerformanceTracker.step('onTapPunchs: Opening PunchBoxConfirmation Dialog');
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext dialogContext) {
          return PunchBoxConfirmation(
            currentImage,
            punchType,
            currentLocation.toString(),
            setlatitude ?? '',
            setlongitude ?? '',
            setTodayWeekOff,
            postalCode ?? '',
            isFromWidget: isFromWidget,
            isFaceVerified: isFaceVerified,
          );
        },
      );
    } else {
      await getCurrentLocation(context: context);
      // Retry after getting location
      if (currentLocation != null) {
        await onTapPunchs(context, currentDay, punchType, isFromWidget, isFaceVerified);
      } else {
        showtoastmessage(unableToGetLocationString);
        setPunchLoader(false);
      }
    }
  }

  // ==================== PERMISSION DIALOG CALLBACKS ====================
  Future<void> onCameraPermissionDenied(BuildContext context) async {
    await openAppSettings();
    await Future.delayed(const Duration(milliseconds: 500));
    bool cameraGranted = await checkCameraPermission();
    if (cameraGranted && mounted) {
      await startCamera(0);
    }
  }

  Future<void> onLocationPermissionDenied(BuildContext context) async {
    await openAppSettings();
    await Future.delayed(const Duration(milliseconds: 500));
    bool locationGranted = await checkLocationPermission();
    if (locationGranted && mounted) {
      await requestLocationPermission();
      await getCurrentLocation(context: context);
    }
  }

  // Helper to check if widget is mounted (pass from UI)
  bool mounted = true;

  // ==================== SHIFT & OTHER FUNCTIONS ====================
  Future<void> shiftMasterDataGet(BuildContext context) async {
    try {
      if (getUserShift != null && getUserShift!.positionId == curentUser?['PositionId']) {
        return; // Fast cache: Shift data already available for current user
      }
      List<GetShiftMasterData> getShiftSData = [];
      await Provider.of<ShiftMasterProvider>(
        context,
        listen: false,
      ).getShiftTimintgMasterData().then((value) {
        getShiftSData = value;
        for (var element in getShiftSData) {
          if (element.positionId == curentUser['PositionId']) {
            getUserShift = element;
          }
        }
      });
    } catch (e) {
      /* ignored */
    }
  }

  void commanCheck(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceEmp>(
      context,
      listen: false,
    );
    if (attendanceProvider.checkStatus != null &&
        attendanceProvider.checkStatus!.attendenceLog != null &&
        attendanceProvider.checkStatus!.attendenceLog!.isNotEmpty) {
      int usedlength = attendanceProvider.checkStatus!.attendenceLog!.length;
      setOutTime = false;
      showInTime = DateTime.parse(
        attendanceProvider.checkStatus!.attendenceLog!.first.time.toString(),
      );
      for (var i = usedlength - 1; i >= 0; i--) {
        if (attendanceProvider.checkStatus!.attendenceLog![i].status == 'OUT' &&
            setOutTime == false) {
          showoutTime = DateTime.parse(
            attendanceProvider.checkStatus!.attendenceLog![i].time.toString(),
          );
          setOutTime = true;
          notifyListeners();
        }
      }
      int totalMinutsofData = 0;
      if (attendanceProvider.checkStatus!.attendenceLog!.last.status == 'OUT') {
        for (
          var i = 0;
          i < attendanceProvider.checkStatus!.attendenceLog!.length - 1;
          i += 2
        ) {
          DateTime firstTime = DateTime.parse(
            attendanceProvider.checkStatus!.attendenceLog![i].time.toString(),
          );
          DateTime lasttTime = DateTime.parse(
            attendanceProvider.checkStatus!.attendenceLog![i + 1].time
                .toString(),
          );
          Duration getDuration = lasttTime.difference(firstTime);
          int differenceInMinutes = getDuration.inMinutes;
          totalMinutsofData = totalMinutsofData + differenceInMinutes;
        }
      } else {
        if (usedlength == 1) {
          DateTime firstTime = DateTime.parse(
            attendanceProvider.checkStatus!.attendenceLog![0].time.toString(),
          );
          Duration getDuration = DateTime.now().difference(firstTime);
          int differenceInMinutes = getDuration.inMinutes;
          totalMinutsofData = differenceInMinutes;
        } else {
          for (var i = 0; i < usedlength - 1; i += 2) {
            DateTime firstTime = DateTime.parse(
              attendanceProvider.checkStatus!.attendenceLog![i].time.toString(),
            );
            DateTime lasttTime = DateTime.parse(
              attendanceProvider.checkStatus!.attendenceLog![i + 1].time
                  .toString(),
            );
            Duration getDuration = lasttTime.difference(firstTime);
            int differenceInMinutes = getDuration.inMinutes;
            totalMinutsofData = totalMinutsofData + differenceInMinutes;
          }
          DateTime lasttTime = DateTime.parse(
            attendanceProvider.checkStatus!.attendenceLog!.last.time.toString(),
          );
          Duration getDuration = DateTime.now().difference(lasttTime);
          int differenceInMinutes = getDuration.inMinutes;
          totalMinutsofData = totalMinutsofData + differenceInMinutes;
        }
      }
      int hours = totalMinutsofData ~/ 60;
      int minutes = totalMinutsofData % 60;
      showTotalHours = '$hours hr $minutes min';
      notifyListeners();
    }
  }

  // ==================== INITIALIZATION ====================
  Future<void> initializePage(BuildContext context) async {
    setLoading(true);
    try {
      bool cameraGranted = await checkCameraPermission();
      bool locationGranted = await checkLocationPermission();

      if (cameraGranted && locationGranted) {
        await startCamera(0);
        if (!context.mounted) return;
        // On iOS: background location disabled — "When In Use" is sufficient.
        // On Android: check Always permission.
        final bool permissionAlreadySatisfied = Platform.isIOS
            ? (await Permission.location.status).isGranted
            : (await Permission.locationAlways.status).isGranted;

        if (!permissionAlreadySatisfied) {
          await requestLocationPermission();
          if (!context.mounted) return;
        } else {
          // Permission already at required level — fetch location silently
          await _fetchAndStoreLocation();
        }
        await callApi(context);
      } else {
        // Show permission dialog if needed
        if (!cameraGranted) {
          await onCameraPermissionDenied(context);
        }
        if (!locationGranted) {
          await onLocationPermissionDenied(context);
        }
      }
    } catch (e) {
      /* ignored */
    } finally {
      setLoading(false);
    }
  }

  void cameraSwitchFunction(BuildContext context, Size size) {
    if (isFrontCamera) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text("Warning"),
            content: const Text(
              "Using back camera for attendance is not recommended. Please use front camera for proper attendance marking.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  cameraisLoading = true;
                  notifyListeners();
                  switchCamera();
                },
                child: const Text("Continue"),
              ),
            ],
          );
        },
      );
    } else {
      switchCamera();
    }
    notifyListeners();
  }
}
