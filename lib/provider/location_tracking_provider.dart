import 'package:flutter/material.dart';
import 'package:tax_hrm/controllers/background_location_controller.dart';
import 'package:tax_hrm/repository/background_location_repository.dart';
import 'package:tax_hrm/services/background_location_service.dart';

/// Legacy provider wrapper inheriting from [BackgroundLocationController]
/// to maintain backward compatibility with existing selfie punch screens.
class LocationTrackingProvider extends BackgroundLocationController {

  bool get isFetchLocation => BackgroundLocationRepository.isFetchLocationEnabled();

  /// Called immediately after a successful Punch In.
  Future<void> startTracking({BuildContext? context}) async {
    await startLocationTracking(context: context);
  }

  /// Called immediately after a successful Punch Out.
  void stopTracking() {
    stopLocationTracking();
  }
}
