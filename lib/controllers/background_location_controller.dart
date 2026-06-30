import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
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
    // 1. Check User Model flag
    final isFetchLocation = BackgroundLocationRepository.isFetchLocationEnabled();
    if (!isFetchLocation) {
      return;
    }

    // 2. Check hardware location service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // 3. Single-prompt compliant permission flow for background location tracking
    if (context != null && context.mounted) {
      final success = await LocationPermissionService.executeAppleCompliantFlow(context);
      if (!success) {
        return;
      }
    } else {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Permission.locationAlways.request();
        perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      }
    }

    // 4. Initialize worker services
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastSentLat');
    await prefs.remove('lastSentLng');

    final service = FlutterBackgroundService();
    await service.startService();
    await registerLocationWorkManager();

    _isTrackingActive = true;
    notifyListeners();
  }

  /// Stops tracking upon employee Punch Out.
  void stopLocationTracking() {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    cancelLocationWorkManager();

    _isTrackingActive = false;
    notifyListeners();
  }
}
