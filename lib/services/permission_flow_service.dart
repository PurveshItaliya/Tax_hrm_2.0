// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tax_hrm/services/location_permission_service.dart';
import 'package:tax_hrm/widigets/permission_dialog_widget.dart';
import 'package:tax_hrm/services/fcm_token_service.dart';

/// The type of permission being processed.
enum PermissionType { notification, camera, foregroundLocation, backgroundLocation }

/// Result returned after the full permission flow completes.
class PermissionFlowResult {
  final bool notificationGranted;
  final bool cameraGranted;
  final bool locationGranted;

  const PermissionFlowResult({
    required this.notificationGranted,
    required this.cameraGranted,
    required this.locationGranted,
  });

  /// True when the minimum permissions required for punching are available.
  bool get canPunch => cameraGranted && locationGranted;
}

/// Sequential permission flow engine.
///
/// Permissions are requested in order, one at a time:
///   1. Notification
///   2. Camera
///   3. Foreground Location
///   4. Background Location (Android only, when [isFetchLocation] is true)
///
/// Rules enforced:
///   - A custom explanation dialog is shown ONCE before system dialogs.
///   - If all permissions are already granted, exits instantly without showing any dialog.
///   - Tapping "Continue" requests the pending permissions once and completes without looping.
///   - Tapping "Not Now" cancels cleanly and exits.
///   - App Settings are opened ONLY after a permanent denial of essential permissions.
class PermissionFlowService {
  /// Global flag to indicate if the permission flow is currently active.
  static bool isFlowRunning = false;
  static Future<PermissionFlowResult>? _runningFuture;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Runs the full sequential permission flow and returns a [PermissionFlowResult].
  static Future<PermissionFlowResult> run(
    BuildContext context, {
    required bool isFetchLocation,
    bool notificationOnly = false,
  }) async {
    // If a flow is already running, join and return the same future.
    if (isFlowRunning && _runningFuture != null) {
      return await _runningFuture!;
    }

    final completer = Completer<PermissionFlowResult>();
    _runningFuture = completer.future;
    isFlowRunning = true;

    try {
      if (!context.mounted) {
        final res = await _buildResult();
        completer.complete(res);
        return res;
      }

      // Check pending permissions upfront
      final List<PermissionType> pending =
          await _buildPendingList(isFetchLocation, notificationOnly);

      // If all required permissions are already granted, exit immediately without showing any dialog!
      if (pending.isEmpty) {
        final res = await _buildResult();
        completer.complete(res);
        return res;
      }

      // Check if any critical permission is permanently denied
      PermissionType? permanentlyDeniedType;
      for (final type in pending) {
        final status = await _getStatus(type);
        if (status.isPermanentlyDenied) {
          permanentlyDeniedType = type;
          break;
        }
      }

      // If a critical permission is permanently disabled, show settings dialog ONCE
      if (permanentlyDeniedType != null) {
        if (permanentlyDeniedType == PermissionType.camera ||
            permanentlyDeniedType == PermissionType.foregroundLocation ||
            notificationOnly) {
          if (context.mounted) {
            final openSettings =
                await PermissionDialogWidget.showPermanentlyDeniedDialog(
                    context, permanentlyDeniedType);
            if (openSettings && context.mounted) {
              await openAppSettings();
              await LocationPermissionService.waitForAppResume();
            }
          }
          final res = await _buildResult();
          completer.complete(res);
          return res;
        }
      }

      if (!context.mounted) {
        final res = await _buildResult();
        completer.complete(res);
        return res;
      }

      // Show ONE combined explanation dialog listing pending permissions
      final continuePressed =
          await PermissionDialogWidget.showCombinedExplanationDialog(
              context, pending);

      if (!continuePressed || !context.mounted) {
        // User tapped "Not Now" or dismissed dialog
        final res = await _buildResult();
        completer.complete(res);
        return res;
      }

      // User tapped "Continue". Request system permissions ONCE for each pending type.
      for (final type in pending) {
        if (!context.mounted) break;

        // Background location requires foreground to be granted first
        if (type == PermissionType.backgroundLocation) {
          final fgStatus = await Permission.location.status;
          if (!fgStatus.isGranted) {
            continue;
          }
        }

        await _requestSystemPermissionSilent(type);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Execution complete! Never loop back to show the explanation dialog again!
      final result = await _buildResult();
      completer.complete(result);
      return result;
    } catch (e) {
      debugPrint('[PermissionFlowService] Error in run: $e');
      final fallback = await _buildResult();
      if (!completer.isCompleted) completer.complete(fallback);
      return fallback;
    } finally {
      isFlowRunning = false;
      _runningFuture = null;
    }
  }

  // ─── Build pending list ─────────────────────────────────────────────────────

  static Future<List<PermissionType>> _buildPendingList(
      bool isFetchLocation, bool notificationOnly) async {
    final List<PermissionType> pending = [];

    if (notificationOnly) {
      if (!(await _getSafeStatus(PermissionType.notification)).isGranted) {
        pending.add(PermissionType.notification);
      }
      return pending;
    }

    if (!(await _getSafeStatus(PermissionType.camera)).isGranted) {
      pending.add(PermissionType.camera);
    }
    if (!(await _getSafeStatus(PermissionType.foregroundLocation)).isGranted) {
      pending.add(PermissionType.foregroundLocation);
    }
    if (!(await _getSafeStatus(PermissionType.notification)).isGranted) {
      pending.add(PermissionType.notification);
    }

    // Only check background location on Android if foreground location is already granted,
    // isFetchLocation is true, and it hasn't been permanently denied.
    if (Platform.isAndroid && isFetchLocation) {
      final fgStatus = await _getSafeStatus(PermissionType.foregroundLocation);
      final bgStatus = await _getSafeStatus(PermissionType.backgroundLocation);
      if (fgStatus.isGranted && !bgStatus.isGranted && !bgStatus.isPermanentlyDenied) {
        pending.add(PermissionType.backgroundLocation);
      }
    }

    return pending;
  }

  // ─── System permission request dispatcher ──────────────────────────────────

  static Future<void> _requestSystemPermissionSilent(PermissionType type) async {
    switch (type) {
      case PermissionType.notification:
        await Permission.notification.request();
        break;
      case PermissionType.camera:
        await Permission.camera.request();
        break;
      case PermissionType.foregroundLocation:
        await Permission.location.request();
        break;
      case PermissionType.backgroundLocation:
        await Permission.locationAlways.request();
        await LocationPermissionService.waitForSystemDialogToClose();
        break;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static Future<PermissionStatus> _getStatus(PermissionType type) async {
    return await _getSafeStatus(type);
  }

  static Future<PermissionStatus> _getSafeStatus(PermissionType type) async {
    try {
      switch (type) {
        case PermissionType.notification:
          return await Permission.notification.status.timeout(const Duration(seconds: 2));
        case PermissionType.camera:
          return await Permission.camera.status.timeout(const Duration(seconds: 2));
        case PermissionType.foregroundLocation:
          return await Permission.location.status.timeout(const Duration(seconds: 2));
        case PermissionType.backgroundLocation:
          return await Permission.locationAlways.status.timeout(const Duration(seconds: 2));
      }
    } catch (e) {
      debugPrint("Timeout or error getting status for $type: $e");
      return PermissionStatus.denied;
    }
  }

  static Future<PermissionFlowResult> _buildResult() async {
    final notifGranted = (await _getSafeStatus(PermissionType.notification)).isGranted;
    if (notifGranted) {
      FcmTokenService.instance.handleTokenSync();
    }
    final camGranted = (await _getSafeStatus(PermissionType.camera)).isGranted;
    final fgGranted = (await _getSafeStatus(PermissionType.foregroundLocation)).isGranted;
    final bgGranted =
        Platform.isAndroid && (await _getSafeStatus(PermissionType.backgroundLocation)).isGranted;
    final locGranted = fgGranted || bgGranted;

    return PermissionFlowResult(
      notificationGranted: notifGranted,
      cameraGranted: camGranted,
      locationGranted: locGranted,
    );
  }
}
