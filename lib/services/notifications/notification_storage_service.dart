import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/services/notifications/notification_logger_service.dart';

class NotificationStorageService {
  static const String _versionKey = 'notif_schedule_version';
  static const String _lastScheduledDateKey = 'notif_last_scheduled_date';
  static const String _expiryDateKey = 'notif_expiry_date';
  static const String _scheduledIdsKey = 'notif_scheduled_ids';
  static const String _companyIdKey = 'notif_company_id';
  static const String _userIdKey = 'notif_user_id';

  // User info keys
  static const String _userInfoUserId = 'notif_user_info_id';
  static const String _userInfoCompanyId = 'notif_user_info_company_id';
  static const String _userInfoRole = 'notif_user_info_role';
  static const String _userInfoRoleClass = 'notif_user_info_role_class';
  static const String _userInfoEmpName = 'notif_user_info_emp_name';

  static const String currentVersion = '1.0.0';

  /// Stores user info after successful login or app initialization
  static Future<void> storeUserInfo({
    required int userId,
    required int companyId,
    required String role,
    required String employeeName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final roleClassification = _determineRoleClassification(role);

    await prefs.setInt(_userInfoUserId, userId);
    await prefs.setInt(_userInfoCompanyId, companyId);
    await prefs.setString(_userInfoRole, role);
    await prefs.setString(_userInfoRoleClass, roleClassification);
    await prefs.setString(_userInfoEmpName, employeeName);

    NotificationLoggerService.permission(
      'Stored user info: UserId=$userId, CompanyId=$companyId, Role=$role ($roleClassification), Name=$employeeName',
    );
  }

  static String _determineRoleClassification(String role) {
    final r = role.trim().toLowerCase();
    if (r == 'admin' || r == 'owner' || r == 'sub-admin' || r == 'hr' || r == 'director') {
      return 'Admin';
    } else if (r.contains('manager') || r.contains('tl') || r.contains('lead') || r.contains('supervisor')) {
      return 'Manager';
    } else {
      return 'Employee';
    }
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getInt(_userInfoUserId),
      'companyId': prefs.getInt(_userInfoCompanyId),
      'role': prefs.getString(_userInfoRole),
      'roleClassification': prefs.getString(_userInfoRoleClass) ?? 'Employee',
      'employeeName': prefs.getString(_userInfoEmpName) ?? '',
    };
  }

  /// Checks if the currently stored 7-day schedule is valid and doesn't need API calls/regeneration
  static Future<bool> isScheduleValid(int companyId, int userId) async {
    final prefs = await SharedPreferences.getInstance();

    final storedVersion = prefs.getString(_versionKey);
    if (storedVersion != currentVersion) {
      NotificationLoggerService.duplicatePrevention(
        'Schedule invalid: Version mismatch (stored: $storedVersion, current: $currentVersion)',
      );
      return false;
    }

    final storedCompanyId = prefs.getInt(_companyIdKey);
    final storedUserId = prefs.getInt(_userIdKey);
    if (storedCompanyId != companyId || storedUserId != userId) {
      NotificationLoggerService.duplicatePrevention(
        'Schedule invalid: User/Company changed (stored: C$storedCompanyId/U$storedUserId, target: C$companyId/U$userId)',
      );
      return false;
    }

    final lastScheduledStr = prefs.getString(_lastScheduledDateKey);
    final expiryStr = prefs.getString(_expiryDateKey);
    if (lastScheduledStr == null || expiryStr == null) {
      NotificationLoggerService.duplicatePrevention('Schedule invalid: No stored schedule metadata found.');
      return false;
    }

    final lastScheduledDate = DateTime.tryParse(lastScheduledStr);
    final expiryDate = DateTime.tryParse(expiryStr);
    final now = DateTime.now();

    if (lastScheduledDate == null || expiryDate == null) {
      NotificationLoggerService.duplicatePrevention('Schedule invalid: Corrupted date metadata.');
      return false;
    }

    if (now.isAfter(expiryDate)) {
      NotificationLoggerService.duplicatePrevention('Schedule invalid: Schedule expired on $expiryStr.');
      return false;
    }

    // Check if we entered a new calendar day (new scheduling window)
    if (lastScheduledDate.year != now.year ||
        lastScheduledDate.month != now.month ||
        lastScheduledDate.day != now.day) {
      NotificationLoggerService.duplicatePrevention(
        'Schedule invalid: Entered a new scheduling window (last scheduled on ${lastScheduledDate.toLocal().toString().split(' ').first}, today is ${now.toLocal().toString().split(' ').first}).',
      );
      return false;
    }

    NotificationLoggerService.duplicatePrevention(
      'Schedule valid for CompanyId=$companyId, UserId=$userId (Generated today, expires: ${expiryDate.toLocal().toString().split(' ').first}). Skipping API calls & duplicate notifications.',
    );
    return true;
  }

  /// Stores metadata after generating and scheduling notifications for the next 7 days
  static Future<void> saveScheduleMetadata({
    required int companyId,
    required int userId,
    required List<int> scheduledIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 7));

    await prefs.setString(_versionKey, currentVersion);
    await prefs.setInt(_companyIdKey, companyId);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_lastScheduledDateKey, now.toIso8601String());
    await prefs.setString(_expiryDateKey, expiry.toIso8601String());
    await prefs.setString(_scheduledIdsKey, jsonEncode(scheduledIds));

    NotificationLoggerService.scheduling(
      'Saved schedule metadata: C$companyId/U$userId, ${scheduledIds.length} notifications scheduled until ${expiry.toLocal().toString().split(' ').first}',
    );
  }

  /// Retrieves previously scheduled notification IDs so they can be cancelled before rescheduling
  static Future<List<int>> getScheduledNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final idsStr = prefs.getString(_scheduledIdsKey);
    if (idsStr == null || idsStr.isEmpty) return [];

    try {
      final List<dynamic> list = jsonDecode(idsStr);
      return list.map((e) => e as int).toList();
    } catch (e) {
      NotificationLoggerService.error('Failed to decode scheduled notification IDs: $e');
      return [];
    }
  }

  /// Clears stored schedule metadata (e.g., on logout or force refresh)
  static Future<void> invalidateSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_versionKey);
    await prefs.remove(_lastScheduledDateKey);
    await prefs.remove(_expiryDateKey);
    await prefs.remove(_scheduledIdsKey);
    NotificationLoggerService.scheduling('Schedule metadata invalidated.');
  }
}
