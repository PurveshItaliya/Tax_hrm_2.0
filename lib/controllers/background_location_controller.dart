// ignore_for_file: avoid_print

import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/repository/background_location_repository.dart';
import 'package:tax_hrm/services/background_location_service.dart';
import 'package:tax_hrm/services/location_batch_service.dart';
import 'package:tax_hrm/services/location_permission_service.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/utils/background_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// iOS Tracking State (module-level singletons)
//
// Held outside the ChangeNotifier class so they survive widget rebuilds and
// provider recreation. A single guard flag prevents duplicate streams after
// foreground/background lifecycle transitions.
// ─────────────────────────────────────────────────────────────────────────────
StreamSubscription<Position>? _iosLocationSubscription;
Timer? _iosBatchUploadTimer;
bool _iosStreamActive = false;

/// Controller orchestrating the background location lifecycle.
///
/// Android: unchanged — FlutterBackgroundService (foreground service) + WorkManager.
/// iOS    : Geolocator position stream with AppleSettings
///          (allowBackgroundLocationUpdates, distanceFilter=15, showBackgroundLocationIndicator)
///          paired with a Dart-side 10-minute batch-upload timer that mirrors the
///          Android batching schedule.
class BackgroundLocationController extends ChangeNotifier {
  bool _isTrackingActive = false;
  bool get isTrackingActive => _isTrackingActive;

  /// iOS tracking status string – drives the LocationTrackingBannerWidget.
  /// Values: 'active' | 'permission_denied' | 'location_disabled' |
  ///         'reduced_accuracy' | 'inactive'
  String _iosTrackingStatus = 'inactive';
  String get iosTrackingStatus => _iosTrackingStatus;

  void _setIosStatus(String status) {
    if (_iosTrackingStatus != status) {
      _iosTrackingStatus = status;
      BackgroundLogger.log('[iOS-TRACKING-STATUS] → $status', name: 'BackgroundLocationController');
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Start Tracking
  // ─────────────────────────────────────────────────────────────────────────

  /// Starts the tracking flow following Apple HIG policies.
  /// If [IsFetchLocation] is false, tracking is skipped and user proceeds to dashboard.
  Future<void> startLocationTracking({BuildContext? context}) async {
    try {
      BackgroundLogger.log('========== FOREGROUND NOTIF DEBUG (UI) ==========', name: 'BackgroundLocationController');
      BackgroundLogger.log('1. startLocationTracking() called', name: 'BackgroundLocationController');

      // 1. Check User Model flag
      final isFetchLocation = BackgroundLocationRepository.isFetchLocationEnabled();
      if (!isFetchLocation) {
        BackgroundLogger.log('2. FAILED: isFetchLocationEnabled is FALSE (Tracking will not start)', name: 'BackgroundLocationController');
        return;
      }
      BackgroundLogger.log('2. SUCCESS: isFetchLocationEnabled is TRUE', name: 'BackgroundLocationController');

      // 2. Check hardware location service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        BackgroundLogger.log('3. FAILED: GPS hardware is disabled (Location Services OFF)', name: 'BackgroundLocationController');
        if (Platform.isIOS) _setIosStatus('location_disabled');
        return;
      }
      BackgroundLogger.log('3. SUCCESS: GPS hardware is enabled', name: 'BackgroundLocationController');

      // 3. Single-prompt compliant permission flow for background location tracking
      if (context != null && context.mounted) {
        BackgroundLogger.log('4. Running LocationPermissionService.executeAppleCompliantFlow...', name: 'BackgroundLocationController');
        final success = await LocationPermissionService.executeAppleCompliantFlow(context);
        if (!success) {
          BackgroundLogger.log('4. FAILED: Apple compliant permission flow denied by user', name: 'BackgroundLocationController');
          if (Platform.isIOS) _setIosStatus('permission_denied');
          return;
        }
        BackgroundLogger.log('4. SUCCESS: Apple compliant permission flow granted', name: 'BackgroundLocationController');
      } else {
        BackgroundLogger.log('4. Checking raw permissions (no context)...', name: 'BackgroundLocationController');
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          await Permission.locationAlways.request();
          perm = await Geolocator.checkPermission();
          if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
            BackgroundLogger.log('4. FAILED: Raw permission denied ($perm)', name: 'BackgroundLocationController');
            if (Platform.isIOS) _setIosStatus('permission_denied');
            return;
          }
        }
        BackgroundLogger.log('4. SUCCESS: Raw permission granted ($perm)', name: 'BackgroundLocationController');
      }

      // 4. Initialize worker services
      BackgroundLogger.log('5. Clearing old coordinates from SharedPreferences...', name: 'BackgroundLocationController');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('lastSentLat');
      await prefs.remove('lastSentLng');

      // ── 5a. ANDROID path — completely unchanged ──────────────────────────
      if (Platform.isAndroid) {
        BackgroundLogger.log('6. [ANDROID] Showing immediate persistent notification...', name: 'BackgroundLocationController');
        try {
          final notifPlugin = FlutterLocalNotificationsPlugin();
          await notifPlugin.show(
            id: 888, // kLocationTrackingNotifId
            title: 'Location Tracking Active',
            body: 'Tracking is active until you Punch Out.',
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'location_tracking_channel', // kNotifChannelId
                'Location Tracking',         // kNotifChannelName
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
                ongoing: true,
                autoCancel: false,
              ),
            ),
          );
        } catch (e) {
          BackgroundLogger.log('Exception showing direct notification: $e', name: 'BackgroundLocationController', error: e);
        }

        BackgroundLogger.log('7. [ANDROID] Initializing FlutterBackgroundService...', name: 'BackgroundLocationController');
        await initializeBackgroundService();
        final service = FlutterBackgroundService();
        await service.startService();
        BackgroundLogger.log('8. [ANDROID] flutter_background_service startService() completed', name: 'BackgroundLocationController');
      }

      // WorkManager: runs on Android; no-ops on iOS (plugin stubs it out).
      await registerLocationWorkManager();
      BackgroundLogger.log('9. registerLocationWorkManager() completed', name: 'BackgroundLocationController');

      await prefs.setBool('isTrackingActive', true);
      BackgroundLogger.log('10. isTrackingActive saved to SharedPreferences as TRUE', name: 'BackgroundLocationController');

      // ── 5b. iOS path — Geolocator stream ──────────────────────────────────
      if (Platform.isIOS) {
        await _startIosLocationStream();
      }

      final String userDataStr = await SaveUser().getUserDatas();
      if (userDataStr.isNotEmpty) {
        BackgroundLogger.log('11. Uploading any pending batch from previous session', name: 'BackgroundLocationController');
        final dynamic userData = jsonDecode(userDataStr);
        await LocationBatchStorage.uploadPendingBatch(userData: userData);
      }

      _isTrackingActive = true;
      notifyListeners();
      BackgroundLogger.log('========== SUCCESS: TRACKING STARTED ==========', name: 'BackgroundLocationController');
    } catch (e, st) {
      BackgroundLogger.log('========== EXCEPTION IN startLocationTracking ==========', name: 'BackgroundLocationController');
      BackgroundLogger.log('Error: $e', name: 'BackgroundLocationController', error: e, stackTrace: st);
      BackgroundLogger.log('========================================================', name: 'BackgroundLocationController');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // iOS – Start the Geolocator position stream
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _startIosLocationStream() async {
    // Guard — never create a second stream if one is already running.
    if (_iosStreamActive) {
      BackgroundLogger.log('[iOS-STREAM] Already active — skipping duplicate start.', name: 'BackgroundLocationController');
      return;
    }

    // ── Detect reduced-accuracy mode (Precise Location disabled) ──────────
    final LocationAccuracyStatus accuracyStatus =
        await Geolocator.getLocationAccuracy();
    if (accuracyStatus == LocationAccuracyStatus.reduced) {
      BackgroundLogger.log('[iOS-STREAM] ⚠️ Precise Location is OFF — proceeding with reduced accuracy.', name: 'BackgroundLocationController');
      _setIosStatus('reduced_accuracy');
      // We continue: reduced accuracy is better than no tracking.
    }

    // ── AppleSettings ─────────────────────────────────────────────────────
    // distanceFilter=15  → iOS OS-level gate matching the Android 15 m rule.
    //                       LocationBatchStorage.appendLocation also filters by
    //                       15 m, but the OS gate avoids waking the app at all.
    // allowBackgroundLocationUpdates=true → keeps stream alive while minimised.
    //   Requires the `location` UIBackgroundMode in Info.plist (added separately).
    // pauseLocationUpdatesAutomatically=false → prevents the OS from pausing the
    //   stream when the device appears stationary; batch storage handles dedup.
    // showBackgroundLocationIndicator=true → required by Apple policy; shows the
    //   blue pill indicator so the user is always aware of active location use.
    final LocationSettings locationSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.other,
      distanceFilter: 15,
      allowBackgroundLocationUpdates: true,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
    );

    _iosStreamActive = true;
    BackgroundLogger.log('[iOS-STREAM] Starting position stream — distanceFilter=15m, allowBackground=true.', name: 'BackgroundLocationController');

    _iosLocationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        BackgroundLogger.log(
          '[iOS-STREAM] 📍 Update received | lat=${position.latitude.toStringAsFixed(5)} '
          'lng=${position.longitude.toStringAsFixed(5)} '
          'accuracy=${position.accuracy.toStringAsFixed(1)}m',
          name: 'BackgroundLocationController'
        );
        await LocationBatchStorage.appendLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          entryTime: DateTime.now(),
          accuracy: position.accuracy,
        );
      },
      onError: (Object error) {
        BackgroundLogger.log('[iOS-STREAM] ❌ Stream error: $error', name: 'BackgroundLocationController', error: error);
        _iosStreamActive = false;
        _setIosStatus('location_disabled');
      },
      cancelOnError: false, // keep stream alive after transient errors
    );

    // ── 10-minute batch upload timer ───────────────────────────────────────
    // Exactly mirrors the Android 10-minute batching interval.
    // Map-screen mode (5 min) is supported via the isMapScreen flag.
    _cancelIosBatchTimer();
    _iosBatchUploadTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      BackgroundLogger.log('[iOS-BATCH] ⏰ 10-min timer fired — uploading pending batch.', name: 'BackgroundLocationController');
      final String userDataStr = await SaveUser().getUserDatas();
      if (userDataStr.isEmpty) {
        BackgroundLogger.log('[iOS-BATCH] ⚠️ User data empty, skipping upload.', name: 'BackgroundLocationController');
        return;
      }
      final dynamic userData = jsonDecode(userDataStr);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final bool isMapScreen = prefs.getBool('MapActive') ?? false;
      final bool isAppForeground = prefs.getBool('AppForeground') ?? false;

      await LocationBatchStorage.uploadPendingBatch(
        userData: userData,
        isMapScreen: isMapScreen,
        isAppForeground: isAppForeground,
      );
    });

    if (_iosTrackingStatus != 'reduced_accuracy') {
      _setIosStatus('active');
    }
    BackgroundLogger.log('[iOS-STREAM] ✅ Stream and 10-min batch timer started successfully.', name: 'BackgroundLocationController');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // iOS – Cancel helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _cancelIosLocationStream() {
    if (_iosLocationSubscription != null) {
      _iosLocationSubscription?.cancel();
      _iosLocationSubscription = null;
      _iosStreamActive = false;
      BackgroundLogger.log('[iOS-STREAM] Position stream cancelled.', name: 'BackgroundLocationController');
    }
  }

  void _cancelIosBatchTimer() {
    if (_iosBatchUploadTimer != null) {
      _iosBatchUploadTimer?.cancel();
      _iosBatchUploadTimer = null;
      BackgroundLogger.log('[iOS-BATCH] Batch upload timer cancelled.', name: 'BackgroundLocationController');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // iOS – Refresh tracking status (call on foreground resume)
  //
  // Re-validates permission/service state and restarts the stream if it died
  // (e.g. after a transient error or a deeply-backgrounded period).
  // Android: no-op.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> refreshIosTrackingStatus() async {
    if (!Platform.isIOS) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool shouldBeTracking = prefs.getBool('isTrackingActive') ?? false;
    if (!shouldBeTracking) {
      BackgroundLogger.log('[iOS-REFRESH] isTrackingActive is FALSE. Tracking remains inactive.', name: 'BackgroundLocationController');
      _setIosStatus('inactive');
      return;
    }
    
    BackgroundLogger.log('[iOS-REFRESH] Checking tracking status on resume...', name: 'BackgroundLocationController');

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      BackgroundLogger.log('[iOS-REFRESH] ❌ Location services disabled.', name: 'BackgroundLocationController');
      _setIosStatus('location_disabled');
      _cancelIosLocationStream();
      _cancelIosBatchTimer();
      return;
    }

    final LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      BackgroundLogger.log('[iOS-REFRESH] ❌ Permission denied: $perm', name: 'BackgroundLocationController');
      _setIosStatus('permission_denied');
      _cancelIosLocationStream();
      _cancelIosBatchTimer();
      return;
    }

    final LocationAccuracyStatus accuracyStatus = await Geolocator.getLocationAccuracy();
    if (accuracyStatus == LocationAccuracyStatus.reduced) {
      BackgroundLogger.log('[iOS-REFRESH] ⚠️ Location accuracy reduced.', name: 'BackgroundLocationController');
      _setIosStatus('reduced_accuracy');
    } else {
      _setIosStatus('active');
    }

    // Restart the stream if it died silently
    if (!_iosStreamActive) {
      BackgroundLogger.log('[iOS-REFRESH] Stream not active — restarting...', name: 'BackgroundLocationController');
      await _startIosLocationStream();
    } else {
      BackgroundLogger.log('[iOS-REFRESH] Stream already active. All good.', name: 'BackgroundLocationController');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stop Tracking (Punch Out / Logout / Session invalidation)
  // ─────────────────────────────────────────────────────────────────────────

  /// Stops tracking upon employee Punch Out.
  void stopLocationTracking() async {
    BackgroundLogger.log('[TRACKING] stopLocationTracking() called.', name: 'BackgroundLocationController');

    final String userDataStr = await SaveUser().getUserDatas();
    if (userDataStr.isNotEmpty) {
      BackgroundLogger.log('[TRACKING] Uploading final batch before stopping', name: 'BackgroundLocationController');
      final dynamic userData = jsonDecode(userDataStr);
      await LocationBatchStorage.uploadPendingBatch(userData: userData);
    }

    // ── Android cleanup — unchanged ────────────────────────────────────────
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    cancelLocationWorkManager();

    try {
      if (Platform.isAndroid) {
        final notifPlugin = FlutterLocalNotificationsPlugin();
        await notifPlugin.cancel(id: 888); // kLocationTrackingNotifId
      }
    } catch (e) {
      BackgroundLogger.log('[TRACKING] Error cancelling Android notification: $e', name: 'BackgroundLocationController', error: e);
    }

    // ── iOS cleanup ────────────────────────────────────────────────────────
    if (Platform.isIOS) {
      _cancelIosLocationStream();
      _cancelIosBatchTimer();
      _setIosStatus('inactive');
      developer.log('[iOS-STREAM] All tracking resources released on Punch Out.', name: 'BackgroundLocationController');
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTrackingActive', false);

    _isTrackingActive = false;
    notifyListeners();
    developer.log('[TRACKING] ✅ Tracking stopped successfully.', name: 'BackgroundLocationController');
  }
}
