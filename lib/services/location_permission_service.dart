import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
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
    developer.log('[iOS-PERMISSION] Starting executeAppleCompliantFlow...', name: 'LocationPermissionService');
    LocationPermission currentPerm = await checkPermission();
    developer.log('[iOS-PERMISSION] Initial permission state: $currentPerm', name: 'LocationPermissionService');

    // Guard: On iOS, whileInUse is perfectly sufficient for background tracking via the blue indicator.
    // On Android, we strictly need Always.
    if (Platform.isIOS) {
      if (currentPerm == LocationPermission.always || currentPerm == LocationPermission.whileInUse) {
        developer.log('[iOS-PERMISSION] ✅ Already have $currentPerm. Sufficient for iOS. Proceeding.', name: 'LocationPermissionService');
        return true;
      }
    } else {
      if (currentPerm == LocationPermission.always) {
        developer.log('[iOS-PERMISSION] ✅ Already have LocationPermission.always. Proceeding.', name: 'LocationPermissionService');
        return true;
      }
    }

    // ── Pre-permission explanation dialog (Apple HIG requirement) ─────────────
    if (!context.mounted) return false;
    developer.log('[iOS-PERMISSION] Showing Pre-Permission dialog...', name: 'LocationPermissionService');
    final agreedToContinue = await PermissionDialogWidget.showPrePermissionDialog(context);
    if (!agreedToContinue) {
      developer.log('[iOS-PERMISSION] ❌ User cancelled Pre-Permission dialog.', name: 'LocationPermissionService');
      return false;
    }
    developer.log('[iOS-PERMISSION] User agreed to continue to system prompt.', name: 'LocationPermissionService');

    // ── Step 1: Request basic permission if denied ───────────────────────────
    if (currentPerm == LocationPermission.denied) {
      developer.log('[iOS-PERMISSION] Requesting initial Geolocator permission...', name: 'LocationPermissionService');
      // iOS and Android both request basic permission first
      currentPerm = await Geolocator.requestPermission();
      developer.log('[iOS-PERMISSION] Initial request resulted in: $currentPerm', name: 'LocationPermissionService');

      if (currentPerm == LocationPermission.denied ||
          currentPerm == LocationPermission.deniedForever) {
        developer.log('[iOS-PERMISSION] ❌ Permission denied or deniedForever after prompt.', name: 'LocationPermissionService');
        if (context.mounted) {
          final openSet = await PermissionDialogWidget.showPermissionDeniedDialog(context);
          if (openSet) {
            developer.log('[iOS-PERMISSION] User chose to Open Settings.', name: 'LocationPermissionService');
            await openSettings();
            await waitForAppResume();
            currentPerm = await checkPermission();
            developer.log('[iOS-PERMISSION] Returned from Settings. New permission: $currentPerm', name: 'LocationPermissionService');
          }
        }
        if (currentPerm != LocationPermission.always && currentPerm != LocationPermission.whileInUse) {
          developer.log('[iOS-PERMISSION] ❌ Flow failed. Required at least whileInUse.', name: 'LocationPermissionService');
          return false;
        }
      }
    }

    // ── Step 2: Request Always permission ────────────────────────────────────
    if (currentPerm == LocationPermission.whileInUse) {
      developer.log('[iOS-PERMISSION] Current state is whileInUse. Checking for Always upgrade...', name: 'LocationPermissionService');
      if (Platform.isIOS) {
        // iOS Apple HIG: request Always only after whileInUse is confirmed.
        // The 500ms delay is required — iOS silently no-ops requestAlwaysAuthorization
        // if the whileInUse grant has not been fully committed to the system yet.
        final alwaysStatus = await Permission.locationAlways.status;
        if (!alwaysStatus.isGranted) {
          developer.log('[iOS-PERMISSION] Requesting iOS locationAlways...', name: 'LocationPermissionService');
          await Future.delayed(const Duration(milliseconds: 500));
          await Permission.locationAlways.request();
          await waitForSystemDialogToClose();
        }
      } else {
        // Android Step 2: request Always upgrade
        final alwaysStatus = await Permission.locationAlways.status;
        if (!alwaysStatus.isGranted) {
          await Permission.locationAlways.request();
          await waitForSystemDialogToClose();
        }
      }

      currentPerm = await checkPermission();
      developer.log('[iOS-PERMISSION] Permission after Always request step: $currentPerm', name: 'LocationPermissionService');

      // Fallback: If still only whileInUse on Android, show settings upgrade dialog.
      // On iOS whileInUse is acceptable — the stream works in foreground/background.
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
    // On iOS, whileInUse is acceptable: the Geolocator stream with
    // allowBackgroundLocationUpdates=true will still deliver updates while
    // the app is backgrounded (blue indicator shown), even without Always.
    if (Platform.isIOS) {
      final bool iosSuccess = finalPerm == LocationPermission.always || finalPerm == LocationPermission.whileInUse;
      if (iosSuccess) {
        developer.log('[iOS-PERMISSION] ✅ Flow successful for iOS ($finalPerm).', name: 'LocationPermissionService');
      } else {
        developer.log('[iOS-PERMISSION] ❌ Flow failed for iOS ($finalPerm).', name: 'LocationPermissionService');
      }
      return iosSuccess;
    }
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
