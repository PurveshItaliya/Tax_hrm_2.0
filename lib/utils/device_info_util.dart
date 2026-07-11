// ignore_for_file: empty_catches

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Returns the native device identifier:
///   • Android → `androidId`  (Settings.Secure.ANDROID_ID)
///   • iOS     → `identifierForVendor` (IDFV)
///
/// Falls back to an empty string if the value cannot be retrieved.
Future<String> getDeviceId() async {
  try {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // androidId is null only on very old OS versions or emulators.
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      // identifierForVendor is unique per app-vendor per device.
      return iosInfo.identifierForVendor ?? '';
    }
  } catch (_) {}

  return '';
}
