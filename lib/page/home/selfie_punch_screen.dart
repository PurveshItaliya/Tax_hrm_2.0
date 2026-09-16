// ignore_for_file: deprecated_member_use, strict_top_level_inference, use_build_context_synchronously

import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/internetcheck.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/selfie_punch_provider.dart';
import 'package:tax_hrm/services/permission_flow_service.dart';
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
  // ── Guards ─────────────────────────────────────────────────────────────────
  bool _isFlowRunning = false;   // true while PermissionFlowService is active
  bool _permissionsChecked = false;
  bool _wentToSettings = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isFlowRunning && !_permissionsChecked) {
        _initializePage();
      }
      // Show punch sync summary dialog if there are unviewed results.
      PunchSyncSummaryDialog.showIfNeeded(context);
    });
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
    }
  }

  @override
  void dispose() {
    selfiePunchProvider.disposeCamera();
    WidgetsBinding.instance.removeObserver(this);
    selfiePunchProvider.stopLiveTime();
    _isFlowRunning = false;
    _permissionsChecked = false;
    super.dispose();
  }

  late SelfiePunchProvider selfiePunchProvider;

  // ── Permission flow entry points ───────────────────────────────────────────

  Future<void> _initializePage() async {
    debugPrint("INITPAGE: 1. _initializePage called. _isFlowRunning=$_isFlowRunning");
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
        camGranted = await Permission.camera.status.isGranted.timeout(const Duration(seconds: 2));
        locGranted = await Permission.location.status.isGranted.timeout(const Duration(seconds: 2));
        debugPrint("INITPAGE: 3. Fast path results: camGranted=$camGranted, locGranted=$locGranted");
      } catch (e) {
        debugPrint("INITPAGE: 4. Fast path permission check failed or timed out: $e");
      }

      bool cameraStarted = false;
      if (mounted && camGranted) {
        debugPrint("INITPAGE: 5. Fast path calling startCamera(0)");
        provider.startCamera(0);
        cameraStarted = true;
      }

      if (mounted && locGranted) {
        debugPrint("INITPAGE: 6. Fast path locGranted is true, proceeding with API calls");
        provider.startLiveTime();
        Future.wait([
          provider.getCurrentLocation(context: context),
          provider.callApi(context),
        ]);
        
        debugPrint("INITPAGE: 7. Calling PermissionFlowService.run in background");
        PermissionFlowService.run(
          context,
          isFetchLocation: provider.isFetchLocation,
        ).then((result) {
          debugPrint("INITPAGE: 8. Background PermissionFlowService.run completed with cameraGranted=${result.cameraGranted}");
          if (mounted && result.cameraGranted && !cameraStarted) {
            debugPrint("INITPAGE: 9. Calling startCamera(0) from background flow");
            provider.startCamera(0);
          } else if (mounted && !result.cameraGranted && !cameraStarted) {
            debugPrint("INITPAGE: 10. Resetting loaders from background flow");
            provider.cameraisLoading = false;
            provider.readyCameraPreviewshow = false;
            provider.setLoading(provider.isLoading);
          }
        }).catchError((e) {
          debugPrint("INITPAGE: 11. Background PermissionFlowService.run caught error: $e");
          if (mounted && !cameraStarted) {
            debugPrint("INITPAGE: 12. Resetting loaders from background flow catchError");
            provider.cameraisLoading = false;
            provider.readyCameraPreviewshow = false;
            provider.setLoading(provider.isLoading);
          }
          return const PermissionFlowResult(
            notificationGranted: false,
            cameraGranted: false,
            locationGranted: false);
        }).whenComplete(() {
          debugPrint("INITPAGE: 13. Background PermissionFlowService.run whenComplete");
          _isFlowRunning = false;
        });
        return; // Fast path successful!
      }

      debugPrint("INITPAGE: 14. SLOW PATH started (locGranted=false)");
      // SLOW PATH: We don't have location yet, so we MUST wait for the flow.
      final result = await PermissionFlowService.run(
        context,
        isFetchLocation: provider.isFetchLocation,
      );
      debugPrint("INITPAGE: 15. SLOW PATH PermissionFlowService.run completed with cameraGranted=${result.cameraGranted}");
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

        provider.startLiveTime();
        await provider.getCurrentLocation(context: context);
        await provider.callApi(context);
      }
    } finally {
      debugPrint("INITPAGE: 17. _initializePage finally block");
      _isFlowRunning = false;
    }
  }

  Future<void> _checkPermissionsAfterSettings(SelfiePunchProvider provider) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _isFlowRunning = false; // Reset so it can run again
    await _initializePage();
  }

  // ── Post-flow initialisation ───────────────────────────────────────────────

  Future<void> _onPermissionsResolved(
      SelfiePunchProvider provider, PermissionFlowResult result, [bool cameraStarted = false]) async {
    if (!mounted) return;

    if (result.cameraGranted && !cameraStarted) {
      // Start camera in background so it doesn't block location and API calls
      provider.startCamera(0);
    } else if (!result.cameraGranted && !cameraStarted) {
      provider.cameraisLoading = false;
      provider.readyCameraPreviewshow = false;
      provider.setLoading(provider.isLoading);
    }

    provider.startLiveTime();
    
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

    final provider = Provider.of<SelfiePunchProvider>(context);
    Provider.of<LanguageProvider>(context);

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Removes back button
          backgroundColor: ColorConst.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${curentUser["FirstName"] ?? ''} ${curentUser["LastName"] ?? ''}",
                style: TextStyle(
                  color: ColorConst.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Punch Attendance',
                style: TextStyle(
                  color: ColorConst.textgrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            // Live clock time badge
            Center(
              child: ValueListenableBuilder<String>(
                valueListenable: provider.currentTimeNotifier,
                builder: (context, time, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorConst.themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: ColorConst.themeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
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
                        
                      ],
                    ),
                  );
                }
                return Positioned.fill(
                  child: Container(
                    color: Colors.black,
                  ),
                );
              },
            ),

            // 2. UI overlays
            Consumer<SelfiePunchProvider>(
              builder: (context, provider, child) {
                // Only show full-screen loader during API/punch operations.
                // Camera warmup (readyCameraPreviewshow) already shows the black
                // placeholder from layer 1 — no extra overlay needed.
                bool showLoading = provider.isLoading && _permissionsChecked;

                if (showLoading) return scanloading();

                // ── Offline state (read outside the inner Consumer to avoid extra rebuild) ──
                final bool isOffline =
                    context.watch<InternetConnectionProvider>().isOffline;

                return Stack(
                  children: [
                    // Unified Control Center (Location + Range Status + Punch Button)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: widget.isFromWidget ? 20 : 90,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.wifi_off_rounded, color: Colors.red, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'Offline Mode — Punch will sync when online',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Row 1: Address Pin + Text (Wrapping allowed to fix cropping) + Refresh
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: ColorConst.themeColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        provider.currentLocation != null
                                            ? provider.currentLocation.toString()
                                            : 'No location details.',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildRefreshButton(provider),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Row 2: Range Status (Compact Badge aligned left)
                                _buildRangeStatusPill(provider, isOffline),
                                const SizedBox(height: 12),

                                // Row 3: Full Width Punch Button (Eliminates right-side blank space)
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: _buildPunchButton(size, provider, currentDay, isOffline),
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

  // ── Range status pill (Compact text badge style) ───────────────────────────
  Widget _buildRangeStatusPill(SelfiePunchProvider provider, [bool isOffline = false]) {
    if (provider.currentLocation == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text(
              'Location Pending',
              style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final bool inRange = provider.distance <= provider.allowedRadius;
    final color = inRange ? Colors.green : Colors.red;

    String distanceText;
    if (provider.distance >= 1000) {
      int km = (provider.distance / 1000).floor();
      int m = (provider.distance % 1000).round();
      distanceText = m > 0 ? '${km}km ${m}m' : '${km}km';
    } else {
      distanceText = '${provider.distance.toStringAsFixed(1)}m';
    }

    final text = inRange ? 'In Range' : 'Out of Range ($distanceText)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Refresh button ─────────────────────────────────────────────────────────
  Widget _buildRefreshButton(SelfiePunchProvider provider) {
    return GestureDetector(
      onTap: () async {
        if (provider.showLocationLoaders) return;
        provider.setLocationLoader(true);
        try {
          await provider.requestLocationPermission();
          await provider.getCurrentLocation(context: context);
        } finally {
          provider.setLocationLoader(false);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: provider.showLocationLoaders
            ? const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 1.5,
                ),
              )
            : const Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
      ),
    );
  }

  // ── Punch button logic ─────────────────────────────────────────────────────

  Widget _buildPunchButton(
      Size size, SelfiePunchProvider provider, String currentDay, [bool isOffline = false]) {
    final bool hasCamera =
        _permissionsChecked &&
        provider.camerapermissionStatus == PermissionStatus.granted;

    // Camera not yet allowed
    if (!hasCamera) {
      return _customButton(
        label: 'Camera',
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
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
        ),
      );
    }

    // Location not obtained
    if (provider.currentLocation == null) {
      return _customButton(
        label: 'Location',
        color: ColorConst.themeColor,
        onTap: () async {
          if (_isFlowRunning) return;
          await _retryPermissionFlow(provider);
        },
      );
    }

    // Camera is warming up after permissions granted — show spinner
    // This only triggers AFTER _permissionsChecked=true and camera is actively initializing
    if (_permissionsChecked && (provider.readyCameraPreviewshow || provider.cameraisLoading)) {
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
        label: 'Punch',
        color: ColorConst.themeColor.withOpacity(0.5),
        onTap: () {}, // disabled
      );
    }

    // Camera failed to initialize despite having permissions
    if (!provider.isCameraReady) {
      return _customButton(
        label: 'Retry Camera',
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
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
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
        label: 'Wait...',
        color: ColorConst.themeColor.withOpacity(0.5),
        onTap: () {},
      );
    }

    // Punch In / Punch Out
    final bool isPunchIn = provider.checkStatus!.attendenceLog!.isEmpty ||
        provider.checkStatus!.attendenceLog!.last.status != 'IN';

    final String buttonName = isPunchIn ? punchInString : punchOutString;
    final Color buttonColor = isPunchIn ? ColorConst.themeColor : Colors.red.shade600;

    return _customButton(
      label: buttonName,
      color: buttonColor,
      onTap: () async {
        if (_isFlowRunning) return;
        await provider.puchInOutHandleSubmit(context, currentDay, widget.isFromWidget);
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
}