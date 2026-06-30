import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tax_hrm/widigets/permission_dialog_widget.dart';

/// Service handling location permissions, step-by-step Apple HIG flow,
/// lifecycle resume detection, and settings redirects.
class LocationPermissionService {
  
  /// Checks current GPS permission state.
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Opens system app settings.
  static Future<bool> openSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Waits for the app to resume from the system settings screen.
  static Future<void> waitForAppResume() async {
    final completer = Completer<void>();
    late final _ResumeObserver observer;
    observer = _ResumeObserver(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    WidgetsBinding.instance.addObserver(observer);
    await completer.future.timeout(const Duration(minutes: 5), onTimeout: () {});
    WidgetsBinding.instance.removeObserver(observer);
  }

  /// Waits until the app lifecycle is 'resumed'. Useful to block execution 
  /// while a system dialog (which moves the app to inactive state) is showing.
  static Future<void> waitForSystemDialogToClose() async {
    // Give OS time to present the dialog and change state to inactive
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      return; // No dialog is showing, or it closed incredibly fast
    }
    
    final completer = Completer<void>();
    late final _ResumeObserver observer;
    observer = _ResumeObserver(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    WidgetsBinding.instance.addObserver(observer);
    await completer.future.timeout(const Duration(minutes: 2), onTimeout: () {});
    WidgetsBinding.instance.removeObserver(observer);
  }

  /// Executes the permission flow for background location tracking (IsFetchLocation = true).
  ///
  /// Requests "Always Allow" in ONE system dialog — does NOT call "When In Use" first.
  ///   - Android 10 : dialog shows "Allow all the time" / "While using" / "Deny".
  ///   - Android 11+: opens Settings (system restriction — background requires settings).
  ///   - iOS        : shows standard location prompt; iOS manages any Always upgrade.
  ///
  /// A pre-permission explanation dialog is shown first per Apple HIG §Location.
  static Future<bool> executeAppleCompliantFlow(BuildContext context) async {
    LocationPermission currentPerm = await checkPermission();

    // Guard: already at Always — nothing to do
    if (currentPerm == LocationPermission.always) {
      return true;
    }

    // ── Pre-permission explanation dialog (Apple HIG requirement) ─────────────
    if (!context.mounted) return false;
    final agreedToContinue = await PermissionDialogWidget.showPrePermissionDialog(context);
    if (!agreedToContinue) {
      return false;
    }

    // ── Step 1: Request basic permission if denied ───────────────────────────
    if (currentPerm == LocationPermission.denied) {
      // iOS and Android both request basic permission first
      currentPerm = await Geolocator.requestPermission();

      if (currentPerm == LocationPermission.denied ||
          currentPerm == LocationPermission.deniedForever) {
        if (context.mounted) {
          final openSet = await PermissionDialogWidget.showPermissionDeniedDialog(context);
          if (openSet) {
            await openSettings();
            await waitForAppResume();
            currentPerm = await checkPermission();
          }
        }
        if (currentPerm != LocationPermission.always && currentPerm != LocationPermission.whileInUse) {
          return false;
        }
      }
    }

    // ── Step 2: Request Always permission ────────────────────────────────────
    // Uncomment the Platform.isIOS block below once iOS bg location is ready.
    if (currentPerm == LocationPermission.whileInUse) {
      // if (Platform.isIOS) {
      //   // IMPORTANT: 500ms delay lets iOS fully register the whileInUse grant.
      //   // Without this, requestAlwaysAuthorization() may silently no-op.
      //   final alwaysStatus = await Permission.locationAlways.status;
      //   if (!alwaysStatus.isGranted) {
      //     await Future.delayed(const Duration(milliseconds: 500));
      //     await Permission.locationAlways.request();
      //     await waitForSystemDialogToClose();
      //   }
      // } else {
        // Android Step 2: request Always upgrade
        if (!Platform.isIOS) {
          final alwaysStatus = await Permission.locationAlways.status;
          if (!alwaysStatus.isGranted) {
            await Permission.locationAlways.request();
            await waitForSystemDialogToClose();
          }
        }
      // }

      currentPerm = await checkPermission();

      // Fallback: If still only whileInUse, show settings upgrade dialog
      if (currentPerm == LocationPermission.whileInUse && !Platform.isIOS) {
        if (context.mounted) {
          final openSet = await PermissionDialogWidget.showEnableAlwaysDialog(context);
          if (openSet) {
            await openSettings();
            await waitForAppResume();
            currentPerm = await checkPermission();
          }
        }
      }
    }

    final finalPerm = await checkPermission();
    return finalPerm == LocationPermission.always;
  }
}

class _ResumeObserver extends WidgetsBindingObserver {
  final VoidCallback onResumed;
  _ResumeObserver(this.onResumed);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
