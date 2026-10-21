// ignore_for_file: invalid_return_type_for_catch_error, deprecated_member_use, strict_top_level_inference, use_build_context_synchronously

import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/selfie_punch_provider.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/provider/attendanceemp.dart';
import 'package:tax_hrm/provider/setting_provider.dart';
import 'package:tax_hrm/services/permission_flow_service.dart';
import 'package:tax_hrm/services/face_registration_sync_service.dart';
import 'package:tax_hrm/services/remote_config_services.dart';
import 'package:tax_hrm/services/developer_mode_service.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/loadersshow.dart';
import 'package:tax_hrm/widigets/punch_sync_summary_dialog.dart';

class SelfiePunchScreen extends StatefulWidget {
  final bool isFromWidget;
  const SelfiePunchScreen({super.key, this.isFromWidget = false});

  @override
  State<SelfiePunchScreen> createState() => _SelfiePunchScreenState();
}

class _SelfiePunchScreenState extends State<SelfiePunchScreen>
    with WidgetsBindingObserver {
  // ── Guards ────────────────────────────────────────────────────────────────
  bool _isFlowRunning = false; // true while PermissionFlowService is active
  bool _permissionsChecked = false;
  bool _wentToSettings = false;
  bool _hasAutoPunchedFromWidget = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  bool _isInitFlowRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      // 1. Shift data & working hours (non-UI background tasks)
      _fetchShiftDataAndStartTimer();

      // 2. Initialize permissions & camera preview
      if (!_permissionsChecked) {
        await _initializePage();
      }

      if (!mounted) return;

      // 3. Face Registration check (ONLY AFTER permissions are done & camera is granted)
      final bool camGranted = await Permission.camera.status.isGranted;
      if (camGranted) {
        await _checkFaceRegistration();
      }

      if (!mounted) return;

      // 4. Punch Sync Summary dialog (ONLY AFTER face registration is done / dismissed)
      await PunchSyncSummaryDialog.showIfNeeded(context);
    } catch (e) {
      debugPrint('[SelfiePunch] Sequential init flow error: $e');
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
    }
  }

  @override
  void dispose() {
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
        camGranted = await Permission.camera.status.isGranted.timeout(
          const Duration(seconds: 2),
        );
        locGranted = await Permission.location.status.isGranted.timeout(
          const Duration(seconds: 2),
        );
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

  Future<void> _checkFaceRegistration() async {
    // Remote kill-switch: skip face registration dialog when feature is OFF
    if (!RemoteConfigServices.isFaceVerifyEnabled) return;
    if (curentUser?['Role'] == 'Admin') return;

    // Check availability locally first (Offline First)
    final bool isRegistered = await FaceRegistrationSyncService.instance
        .checkFaceAvailabilityAndSync(forceServerCheck: false);

    // If face is already enrolled locally or on server, DO NOT show registration dialog!
    if (isRegistered) return;

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
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
                      color: ColorConst.themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      'assets/images/faceid.svg',
                      height: 48,
                      width: 48,
                      color: ColorConst.themeColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    faceRegistrationRequiredString,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    faceRegistrationDescString,
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
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConst.themeColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final selfieProvider =
                            Provider.of<SelfiePunchProvider>(
                              context,
                              listen: false,
                            );
                        selfieProvider.disposeCamera();

                        final success = await FaceRegistrationSyncService
                            .instance
                            .openFaceRegistrationScreen(context);

                        if (success) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            selfieProvider.startCamera(0);
                          }
                        } else {
                          if (context.mounted) {
                            selfieProvider.startCamera(0);
                          }
                        }
                      },
                        child: Text(
                          registerFaceNowString,
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
        },
      );
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
              if (cameraController != null) {
                return Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: cameraController.value.previewSize!.height,
                              height: cameraController.value.previewSize!.width,
                              child: CameraPreview(cameraController),
                            ),
                          ),
                        ),
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                        child: Container(color: Colors.black.withOpacity(0.8)),
                      ),
                      // Second Camera Box inside the frame (Avoids excessive cropping)
                      Positioned(
                        top:
                            MediaQuery.of(context).size.height *
                            (widget.isFromWidget ? 0.20 : 0.15),
                        left: 20,
                        right: 20,
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color.fromARGB(
                                255,
                                80,
                                79,
                                79,
                              ).withOpacity(0.8),
                              width: 2.5,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width:
                                    cameraController.value.previewSize!.height,
                                height:
                                    cameraController.value.previewSize!.width,
                                child: CameraPreview(cameraController),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Positioned.fill(child: Container(color: Colors.black));
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
                              const SizedBox(width: 12),
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

    // Punch loader active
    if (provider.PunchLoader) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ColorConst.themeColor,
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

    // Punch In / Punch Out
    final bool isPunchIn =
        provider.checkStatus!.attendenceLog!.isEmpty ||
        provider.checkStatus!.attendenceLog!.last.status != 'IN';

    final String buttonName = isPunchIn ? punchInString : punchOutString;
    final Color buttonColor = isPunchIn
        ? ColorConst.themeColor
        : Colors.red.shade600;

    // When opened from home screen widget, auto-trigger punch instantly as soon as ready
    if (widget.isFromWidget && !_hasAutoPunchedFromWidget) {
      _hasAutoPunchedFromWidget = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !provider.PunchLoader && !_isFlowRunning) {
          _performPunch(provider, currentDay, isOffline);
        }
      });
    }

    return _customButton(
      label: buttonName,
      color: buttonColor,
      onTap: () => _performPunch(provider, currentDay, isOffline),
    );
  }

  Future<void> _performPunch(
    SelfiePunchProvider provider,
    String currentDay,
    bool isOffline,
  ) async {
    if (_isFlowRunning) return;

    // In release builds, block Punch In/Out if Developer Mode is enabled
    if (await DeveloperModeService.isDeveloperModeRestricted()) {
      if (context.mounted) {
        DeveloperModeService.showDeveloperModeWarningDialog(context);
      }
      return;
    }

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

    if (hasNoInternet) {
      if (context.mounted) {
        _showNoInternetDialog(context);
      }
      return;
    }

    await provider.puchInOutHandleSubmit(
      context,
      currentDay,
      widget.isFromWidget,
    );
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
