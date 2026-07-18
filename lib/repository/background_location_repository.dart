// ignore_for_file: avoid_print
import 'dart:developer';

import 'package:tax_hrm/models/fixeddat.dart';

/// Repository responsible for reading user tracking settings from the active session.
class BackgroundLocationRepository {

  /// Reads whether continuous background location tracking is enabled for the logged-in employee.
  static bool isFetchLocationEnabled() {
    try {
      if (curentUser == null) {
        log('[BgLocation] curentUser is NULL');
        return false;
      }
      if (curentUser?['Role'] == 'Admin') {
        return false;
      }

      final val = curentUser?['IsFetchLocation'];
      final name = '${curentUser?['FirstName'] ?? ''} ${curentUser?['LastName'] ?? ''}'.trim();
      final username = curentUser?['UserName'] ?? curentUser?['Username'] ?? '';

      log('[BgLocation] User: "$name" ($username)  |  IsFetchLocation raw value: $val  (${val.runtimeType})');

      if (val == null) return false;
      if (val is bool) return val;
      final str = val.toString().toLowerCase().trim();
      return str == 'true' || str == '1' || str == 'yes';
    } catch (e) {
      log('[BgLocation] isFetchLocationEnabled error: $e');
      return false;
    }
  }
}