// ignore_for_file: deprecated_member_use, strict_top_level_inference, use_build_context_synchronously

import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/provider/language_provider.dart';
import 'package:tax_hrm/provider/selfie_punch_provider.dart';
import 'package:tax_hrm/services/permission_flow_service.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/widigets/loadersshow.dart';

class SelfiePunchScreen extends StatefulWidget {
  const SelfiePunchScreen({super.key});

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
    if (_isFlowRunning) return;
    _isFlowRunning = true;
    _permissionsChecked = true;

    final provider = Provider.of<SelfiePunchProvider>(context, listen: false);
    try {
      final result = await PermissionFlowService.run(
        context,
        isFetchLocation: provider.isFetchLocation,
      );
      if (mounted) {
        await _onPermissionsResolved(provider, result);
      }
    } catch (e) { /* ignored */ } finally {
      _isFlowRunning = false;
    }
  }

  Future<void> _checkPermissionsAfterSettings(SelfiePunchProvider provider) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _initializePage();
  }

  // ── Post-flow initialisation ───────────────────────────────────────────────

  Future<void> _onPermissionsResolved(
      SelfiePunchProvider provider, PermissionFlowResult result) async {
    if (!mounted) return;

    if (result.cameraGranted) {
      await provider.startCamera(0);
      if (!mounted) return;
    }

    if (result.locationGranted) {
      await provider.getCurrentLocation(context: context);
      if (!mounted) return;
    }

    provider.startLiveTime();
    if (!mounted) return;
    await provider.callApi(context);
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
                    child: ClipRect(
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
                  );
                }
                return Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 64),
                  ),
                );
              },
            ),

            // 2. UI overlays
            Consumer<SelfiePunchProvider>(
              builder: (context, provider, child) {
                bool showLoading =
                    (provider.isLoading || provider.readyCameraPreviewshow == true) &&
                        _permissionsChecked;

                if (showLoading) return scanloading();

                return Stack(
                  children: [
                    // Unified Control Center (Location + Range Status + Punch Button)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 90,
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
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                _buildRangeStatusPill(provider),
                                const SizedBox(height: 12),

                                // Row 3: Full Width Punch Button (Eliminates right-side blank space)
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: _buildPunchButton(size, provider, currentDay),
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
  Widget _buildRangeStatusPill(SelfiePunchProvider provider) {
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
    final text = inRange ? 'In Range' : 'Out of Range (${provider.distance.toStringAsFixed(1)}m)';

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
      Size size, SelfiePunchProvider provider, String currentDay) {
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

    // Camera starting
    if (provider.readyCameraPreviewshow) {
      return _customButton(
        label: 'Start Cam',
        color: ColorConst.themeColor,
        onTap: () => provider.startCamera(0),
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

    // Attendance status pending
    if (provider.checkStatus == null ||
        provider.checkStatus!.attendenceLog == null) {
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
        await provider.puchInOutHandleSubmit(context, currentDay);
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