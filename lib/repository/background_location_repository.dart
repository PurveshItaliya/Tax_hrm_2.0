import 'package:tax_hrm/models/fixeddat.dart';

/// Repository responsible for reading user tracking settings from the active session.
class BackgroundLocationRepository {
  
  /// Reads whether continuous background location tracking is enabled for the logged-in employee.
  static bool isFetchLocationEnabled() {
    try {
      if (curentUser == null) {
        return false;
      }
      if (curentUser?['Role'] == 'Admin') {
        return false;
      }
      
      if (curentUser is Map) {
      } else {
      }
      final val = curentUser?['IsFetchLocation'];
      
      if (val == null) return false; // Changed default from true to false
      if (val is bool) return val;
      final str = val.toString().toLowerCase().trim();
      return str == 'true' || str == '1' || str == 'yes';
    } catch (e) {
      return false;
    }
  }
}