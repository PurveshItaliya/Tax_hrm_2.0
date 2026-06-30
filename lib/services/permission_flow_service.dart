// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tax_hrm/services/location_permission_service.dart';
import 'package:tax_hrm/widigets/permission_dialog_widget.dart';

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
///   - A custom explanation dialog is always shown BEFORE every system dialog.
///   - The system dialog is NEVER opened directly.
///   - App Settings are opened ONLY after a permanent denial.
///   - If the user taps "Not Now", the flow moves to the next permission.
///   - All permissions are attempted regardless of individual denials.
class PermissionFlowService {
  // ─── Public API ────────────────────────────────────────────────────────────

  /// Runs the full sequential permission flow and returns a [PermissionFlowResult].
  static Future<PermissionFlowResult> run(
    BuildContext context, {
    required bool isFetchLocation,
  }) async {
    
    while (true) {
      if (!context.mounted) break;
      
      final List<PermissionType> pending = await _buildPendingList(isFetchLocation);
      if (pending.isEmpty) break; // All granted!

      // Check if any pending permission is permanently denied
      PermissionType? permanentlyDeniedType;
      for (final type in pending) {
        final status = await _getStatus(type);
        if (status.isPermanentlyDenied) {
          permanentlyDeniedType = type;
          break;
        }
      }

      // If permanently denied, show the settings redirect dialog.
      if (permanentlyDeniedType != null) {
        if (!context.mounted) break;
        final openSettings = await PermissionDialogWidget.showPermanentlyDeniedDialog(
            context, permanentlyDeniedType);
        if (openSettings && context.mounted) {
          await openAppSettings();
          await LocationPermissionService.waitForAppResume();
          // The user returned from Settings. Re-check permissions!
          continue; 
        }
        break; // Stop the flow if they hit Cancel/Not Now.
      }

      // Show ONE combined dialog listing all pending permissions
      if (!context.mounted) break;
      final continuePressed = await PermissionDialogWidget.showCombinedExplanationDialog(
          context, pending);
          
      if (!continuePressed) break; // Fallback in case of cancellation

      // Sequentially request system dialogs for all pending permissions
      bool anyDeniedThisRound = false;
      for (final type in pending) {
        if (!context.mounted) break;

        // Background location requires foreground to be granted first
        if (type == PermissionType.backgroundLocation) {
          final fgStatus = await Permission.location.status;
          if (!fgStatus.isGranted) {
            anyDeniedThisRound = true;
            continue;
          }
        }

        await _requestSystemPermissionSilent(type);
        
        // Brief pause so the system dialog transitions smoothly
        await Future.delayed(const Duration(milliseconds: 350));
        
        final newStatus = await _getStatus(type);
        if (!newStatus.isGranted) {
          anyDeniedThisRound = true;
        }
      }

      // If none were denied, the next loop will find pending.isEmpty and break.
      // If any were denied, it loops and re-shows the combined dialog for the remaining.
      if (!anyDeniedThisRound) {
        break;
      }
    }

    return _buildResult();
  }

  // ─── Build pending list ─────────────────────────────────────────────────────

  static Future<List<PermissionType>> _buildPendingList(bool isFetchLocation) async {
    final List<PermissionType> pending = [];

    if (!(await Permission.notification.status).isGranted) {
      pending.add(PermissionType.notification);
    }
    if (!(await Permission.camera.status).isGranted) {
      pending.add(PermissionType.camera);
    }
    if (!(await Permission.location.status).isGranted) {
      pending.add(PermissionType.foregroundLocation);
    }
    if (Platform.isAndroid && isFetchLocation) {
      if (!(await Permission.locationAlways.status).isGranted) {
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
    switch (type) {
      case PermissionType.notification:
        return Permission.notification.status;
      case PermissionType.camera:
        return Permission.camera.status;
      case PermissionType.foregroundLocation:
        return Permission.location.status;
      case PermissionType.backgroundLocation:
        return Permission.locationAlways.status;
    }
  }

  static Future<PermissionFlowResult> _buildResult() async {
    final notifGranted = (await Permission.notification.status).isGranted;
    final camGranted = (await Permission.camera.status).isGranted;
    final fgGranted = (await Permission.location.status).isGranted;
    final bgGranted =
        Platform.isAndroid && (await Permission.locationAlways.status).isGranted;
    final locGranted = fgGranted || bgGranted;

    return PermissionFlowResult(
      notificationGranted: notifGranted,
      cameraGranted: camGranted,
      locationGranted: locGranted,
    );
  }
}
