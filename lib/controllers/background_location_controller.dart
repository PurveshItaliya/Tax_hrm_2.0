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
      print('========== FOREGROUND NOTIF DEBUG (UI) ==========');
      print('1. startLocationTracking() called');
      // 1. Check User Model flag
      final isFetchLocation = BackgroundLocationRepository.isFetchLocationEnabled();
      if (!isFetchLocation) {
        print('2. FAILED: isFetchLocationEnabled is FALSE');
        return;
      }
      print('2. SUCCESS: isFetchLocationEnabled is TRUE');

    // 2. Check hardware location service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('3. FAILED: GPS hardware is disabled');
      return;
    }
    print('3. SUCCESS: GPS hardware is enabled');

    // 3. Single-prompt compliant permission flow for background location tracking
    if (context != null && context.mounted) {
      print('4. Running LocationPermissionService.executeAppleCompliantFlow...');
      final success = await LocationPermissionService.executeAppleCompliantFlow(context);
      if (!success) {
        print('4. FAILED: Apple compliant permission flow denied');
        return;
      }
      print('4. SUCCESS: Apple compliant permission flow granted');
    } else {
      print('4. Checking raw permissions (no context)...');
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Permission.locationAlways.request();
        perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          print('4. FAILED: Raw permission denied');
          return;
        }
      }
      print('4. SUCCESS: Raw permission granted');
    }

    // 4. Initialize worker services
    print('5. Clearing old coordinates from SharedPreferences...');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastSentLat');
    await prefs.remove('lastSentLng');

    print('6. Showing immediate persistent notification...');
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
        print('Exception showing direct notification: $e');
      }
    }

    print('7. Initializing FlutterBackgroundService...');
    if (Platform.isAndroid) {
      await initializeBackgroundService();
      final service = FlutterBackgroundService();
      await service.startService();
      print('8. flutter_background_service startService() completed');
    }
    
    await registerLocationWorkManager();
    print('9. registerLocationWorkManager() completed');

    await prefs.setBool('isTrackingActive', true);
    print('10. isTrackingActive saved to SharedPreferences');
    print('=================================================');

    } catch (e, stacktrace) {
      print('========== EXCEPTION IN startLocationTracking ==========');
      print('Error: $e');
      print('Stacktrace: $stacktrace');
      print('========================================================');
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
