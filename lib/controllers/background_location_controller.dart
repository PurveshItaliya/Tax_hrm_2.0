// ignore_for_file: avoid_print

import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/repository/background_location_repository.dart';
import 'package:tax_hrm/services/background_location_service.dart';
import 'package:tax_hrm/services/location_permission_service.dart';

/// Controller orchestrating the background location lifecycle, Apple HIG
/// permission flow, foreground worker, and WorkManager periodic execution.
class BackgroundLocationController extends ChangeNotifier {
  bool _isTrackingActive = false;
  bool get isTrackingActive => _isTrackingActive;

  /// Starts the tracking flow following Apple HIG policies.
  /// If [IsFetchLocation] is false, tracking is skipped and user proceeds to dashboard.
  Future<void> startLocationTracking({BuildContext? context}) async {
    try {
      log('========== FOREGROUND NOTIF DEBUG (UI) ==========');
      log('1. startLocationTracking() called');
      // 1. Check User Model flag
      final isFetchLocation = BackgroundLocationRepository.isFetchLocationEnabled();
      if (!isFetchLocation) {
        log('2. FAILED: isFetchLocationEnabled is FALSE');
        return;
      }
      log('2. SUCCESS: isFetchLocationEnabled is TRUE');

    // 2. Check hardware location service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log('3. FAILED: GPS hardware is disabled');
      return;
    }
    log('3. SUCCESS: GPS hardware is enabled');

    // 3. Single-prompt compliant permission flow for background location tracking
    if (context != null && context.mounted) {
      log('4. Running LocationPermissionService.executeAppleCompliantFlow...');
      final success = await LocationPermissionService.executeAppleCompliantFlow(context);
      if (!success) {
        log('4. FAILED: Apple compliant permission flow denied');
        return;
      }
      log('4. SUCCESS: Apple compliant permission flow granted');
    } else {
      log('4. Checking raw permissions (no context)...');
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Permission.locationAlways.request();
        perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          log('4. FAILED: Raw permission denied');
          return;
        }
      }
      log('4. SUCCESS: Raw permission granted');
    }

    // 4. Initialize worker services
    log('5. Clearing old coordinates from SharedPreferences...');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastSentLat');
    await prefs.remove('lastSentLng');

    log('6. Showing immediate persistent notification...');
    if (Platform.isAndroid) {
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
        log('Exception showing direct notification: $e');
      }
    }

    log('7. Initializing FlutterBackgroundService...');
    if (Platform.isAndroid) {
      await initializeBackgroundService();
      final service = FlutterBackgroundService();
      await service.startService();
      log('8. flutter_background_service startService() completed');
    }
    
    await registerLocationWorkManager();
    log('9. registerLocationWorkManager() completed');

    await prefs.setBool('isTrackingActive', true);
    log('10. isTrackingActive saved to SharedPreferences');
    log('=================================================');

    } catch (e, stacktrace) {
      log('========== EXCEPTION IN startLocationTracking ==========');
      log('Error: $e');
      log('Stacktrace: $stacktrace');
      log('========================================================');
    }
  }

  /// Stops tracking upon employee Punch Out.
  void stopLocationTracking() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    cancelLocationWorkManager();

    try {
      if (Platform.isAndroid) {
        final notifPlugin = FlutterLocalNotificationsPlugin();
        await notifPlugin.cancel(id: 888); // kLocationTrackingNotifId
      }
    } catch (_) {}

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTrackingActive', false);

    _isTrackingActive = false;
    notifyListeners();
  }
}
