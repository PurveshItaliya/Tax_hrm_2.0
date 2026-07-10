import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:tax_hrm/api/holidayapi.dart';
import 'package:tax_hrm/api/leaveapi.dart';
import 'package:tax_hrm/models/Holidays/getholiday.dart';
import 'package:tax_hrm/models/leavetype/getuserList.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/services/fcm_token_service.dart';
import 'package:tax_hrm/api/employeapi.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/services/notifications/notification_generator_service.dart';
import 'package:tax_hrm/services/notifications/notification_logger_service.dart';
import 'package:tax_hrm/services/notifications/notification_storage_service.dart';


class ReminderNotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    NotificationLoggerService.permission('Initializing ReminderNotificationService & Timezones...');
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        try {
          FcmTokenService.instance.handleNotificationPayload(response.payload);
        } catch (e) {
          // ignore
        }
      },
    );
    WidgetsBinding.instance.addObserver(_LifecycleObserver());
  }

  static Future<void> cancelAll() async {
    try {
      await notificationsPlugin.cancelAll();
      await NotificationStorageService.invalidateSchedule();
      NotificationLoggerService.scheduling('Cancelled all notifications and invalidated schedule.');
    } catch (e) {
      NotificationLoggerService.error('Error in cancelAll: $e');
    }
  }

  static Future<void> updateHolidaysAndLeaves() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = curentUser?['Id'];
    if (userId == null) return;

    // Fetch holidays
    try {
      final holidays = await HolidayAPIS().getHolidays();
      if (holidays is List && holidays.isNotEmpty) {
        final jsonStr = jsonEncode(holidays.map((h) => h.toJson()).toList());
        await prefs.setString('local_holidays_json_$userId', jsonStr);
      }
    } catch (e) { /* ignored */ }

    // Fetch leaves
    try {
      final leaves = await LeaveApiService().userLeaveList();
      if (leaves is List && leaves.isNotEmpty) {
        final jsonStr = jsonEncode(leaves.map((l) => l.toJson()).toList());
        await prefs.setString('local_leaves_json_$userId', jsonStr);
      }
    } catch (e) { /* ignored */ }
  }

  /// Overarching intelligent 7-day notification scheduler.
  /// Checks local cache; if expired, user changed, or company changed, fetches fresh API data and reschedules.
  static Future<void> scheduleAllNotifications({bool forceRefresh = false}) async {
    NotificationLoggerService.scheduling('--- SCHEDULE ALL NOTIFICATIONS START (forceRefresh: $forceRefresh) ---');
    
    final userId = curentUser?['Id'];
    final companyId = selectedcurentcompany?.companyId;

    if (userId == null || companyId == null) {
      NotificationLoggerService.scheduling('Skipping scheduleAllNotifications: No logged-in user ($userId) or company selected ($companyId).');
      return;
    }

    final bool isValid = await NotificationStorageService.isScheduleValid(companyId, userId);
    if (!forceRefresh && isValid) {
      NotificationLoggerService.duplicatePrevention('Valid 7-day schedule exists for C$companyId/U$userId. Skipping API calls & duplicate notifications.');
      // Still refresh local shift reminders as punch status/begin times may have changed locally
      await scheduleReminders();
      NotificationLoggerService.scheduling('--- SCHEDULE ALL NOTIFICATIONS COMPLETE (Cached) ---');
      return;
    }

    NotificationLoggerService.apiFetch('Schedule invalid, expired, or forceRefresh requested. Fetching fresh data from APIs...');

    // 1. Cancel previously scheduled event notifications from last cycle
    final oldIds = await NotificationStorageService.getScheduledNotificationIds();
    for (final id in oldIds) {
      try {
        await notificationsPlugin.cancel(id: id);
      } catch (e) { /* ignored */ }
    }

    // 2. Fetch Employees and Holidays
    List<Employeelists> employees = [];
    try {
      NotificationLoggerService.apiFetch('Calling GetEmpList API...');
      final res = await Employeeclass().emppppapi();
      if (res is List<Employeelists>) {
        employees = res;
        NotificationLoggerService.apiFetch('Fetched ${employees.length} employees.');
      } else if (res is List) {
        employees = res.map((e) => Employeelists.fromJson(Map<String, dynamic>.from(e))).toList();
        NotificationLoggerService.apiFetch('Fetched & parsed ${employees.length} employees.');
      }
    } catch (e) {
      NotificationLoggerService.error('Error fetching Employee list: $e');
    }

    List<GetHolidayViews> holidays = [];
    try {
      NotificationLoggerService.apiFetch('Calling GetHolidayList API...');
      final res = await HolidayAPIS().getHolidays();
      if (res is List<GetHolidayViews>) {
        holidays = res;
        NotificationLoggerService.apiFetch('Fetched ${holidays.length} holidays.');
      } else if (res is List) {
        holidays = res.map((e) => GetHolidayViews.fromJson(Map<String, dynamic>.from(e))).toList();
        NotificationLoggerService.apiFetch('Fetched & parsed ${holidays.length} holidays.');
      }
    } catch (e) {
      NotificationLoggerService.error('Error fetching Holiday list: $e');
    }

    // Also update local storage for shift reminders
    await updateHolidaysAndLeaves();

    // 3. Generate and schedule notifications
    final now = DateTime.now();
    final items = NotificationGeneratorService.generateAll(
      employees: employees,
      holidays: holidays,
      currentUserId: userId,
      now: now,
    );

    final scheduledIds = await NotificationGeneratorService.scheduleItems(items);
    await NotificationStorageService.saveScheduleMetadata(
      companyId: companyId,
      userId: userId,
      scheduledIds: scheduledIds,
    );

    // 4. Run shift reminders
    await scheduleReminders();

    NotificationLoggerService.scheduling('--- SCHEDULE ALL NOTIFICATIONS COMPLETE (Refreshed: ${scheduledIds.length} events scheduled) ---');
  }

  static Future<String> scheduleReminders() async {
    // Notification permission is now handled exclusively by PermissionFlowService.

    // Note: iOS notification permissions are already requested in ReminderNotificationService.initialize()

    // Safely cancel only previous shift reminder IDs (1..13 and 1000..1006) to avoid cancelling birthdays/holidays
    for (int i = 0; i < 7; i++) {
      try {
        await notificationsPlugin.cancel(id: 1000 + i);
        await notificationsPlugin.cancel(id: i * 2 + 1);
      } catch (e) { /* ignored */ }
    }

    StringBuffer logStr = StringBuffer();
    void addLog(String msg) {
      logStr.writeln(msg);
    }



    final now = DateTime.now();

    final userId = curentUser?['Id'];
    if (userId == null) {
      addLog('No logged in user. Skipping reminder scheduling.');
      return logStr.toString();
    }

    final role = curentUser?['Role']?.toString();
    if (role == 'Admin' || role == 'Owner' || role == 'Sub-Admin') {
      addLog('User role is $role. Skipping reminder scheduling for admin/owner.');
      return logStr.toString();
    }

    final prefs = await SharedPreferences.getInstance();

    String? positionName = prefs.getString('user_position_name_$userId');
    if (positionName == null || positionName.isEmpty) {
      addLog('No position name found for reminder scheduling.');
      return logStr.toString();
    }

    String? beginTimeStr = prefs.getString('user_begin_time_${userId}_$positionName');
    String? endTimeStr = prefs.getString('user_end_time_${userId}_$positionName');

    addLog('--- REMINDER SCHEDULING START ---');
    addLog('User ID: $userId | Position: $positionName');
    addLog('Raw Shift Times -> Begin: $beginTimeStr | End: $endTimeStr');

    if (beginTimeStr == null || beginTimeStr.isEmpty || endTimeStr == null || endTimeStr.isEmpty) {
      addLog('BeginTime or EndTime not found in local storage.');
      return logStr.toString();
    }

    final TimeOfDay? beginTime = _parseTimeString(beginTimeStr);
    final TimeOfDay? endTime = _parseTimeString(endTimeStr);

    if (beginTime == null || endTime == null) {
      addLog('Failed to parse BeginTime ($beginTimeStr) or EndTime ($endTimeStr).');
      return logStr.toString();
    }

    addLog('Parsed Times -> BeginTime: ${beginTime.hour}:${beginTime.minute} | EndTime: ${endTime.hour}:${endTime.minute}');

    List<GetHolidayViews> holidays = [];
    final holidaysJson = prefs.getString('local_holidays_json_$userId');
    if (holidaysJson != null && holidaysJson.isNotEmpty) {
      try {
        holidays = getHolidayViewsFromJson(holidaysJson);
      } catch (e) {
        addLog('Error parsing stored holidays: $e');
      }
    }

    List<LeaveListData> leaves = [];
    final leavesJson = prefs.getString('local_leaves_json_$userId');
    if (leavesJson != null && leavesJson.isNotEmpty) {
      try {
        leaves = leaveListDataFromJson(leavesJson);
      } catch (e) {
        addLog('Error parsing stored leaves: $e');
      }
    }

    for (int i = 0; i < 7; i++) {
      final targetDate = now.add(Duration(days: i));
      final dateKey = _formatDateKey(targetDate);
      addLog('>> Processing Date: $dateKey');

      if (targetDate.weekday == DateTime.sunday) {
        addLog('Skipping reminders for $dateKey: Sunday');
        continue;
      }

      bool isHoliday = false;
      for (final holiday in holidays) {
        if (holiday.holidayDate != null) {
          final hDate = DateTime.tryParse(holiday.holidayDate!);
          if (hDate != null && _isSameDay(hDate, targetDate)) {
            isHoliday = true;
            break;
          }
        }
      }
      if (isHoliday) {
        addLog('Skipping reminders for $dateKey: Holiday');
        continue;
      }

      LeaveListData? approvedLeave;
      for (final leave in leaves) {
        if (leave.empId == userId && leave.approveStatus == 'A' && leave.fromDate != null && leave.toDate != null) {
          final fDate = DateTime.tryParse(leave.fromDate!);
          final tDate = DateTime.tryParse(leave.toDate!);
          if (fDate != null && tDate != null) {
            if (_isDateWithinRange(targetDate, fDate, tDate)) {
              approvedLeave = leave;
              break;
            }
          }
        }
      }

      bool isFullDayLeave = false;
      bool isHalfDayLeave = false;

      if (approvedLeave != null) {
        final duration = approvedLeave.leaveDuration?.toString().trim() ?? '';
        final dayType = approvedLeave.dayType?.toString().trim().toLowerCase() ?? '';
        
        if (duration == '0.5' || dayType.contains('half')) {
          isHalfDayLeave = true;
        } else {
          isFullDayLeave = true;
        }
      }

      if (isFullDayLeave) {
        addLog('Skipping reminders for $dateKey: Approved Full-Day Leave');
        continue;
      }

      final bool hasPunchedIn = prefs.getBool('punched_in_$dateKey') ?? false;
      final bool hasPunchedOut = prefs.getBool('punched_out_$dateKey') ?? false;

      String formatTime(TimeOfDay time) {
        final int h = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
        final String m = time.minute.toString().padLeft(2, '0');
        final String p = time.hour >= 12 ? 'PM' : 'AM';
        return '$h:$m $p';
      }

      final String prettyBeginTime = formatTime(beginTime);
      final String prettyEndTime = formatTime(endTime);

      final punchInReminderTime = DateTime(targetDate.year, targetDate.month, targetDate.day, beginTime.hour, beginTime.minute)
          .add(const Duration(minutes: 1));

      if (punchInReminderTime.isAfter(now)) {
        if (hasPunchedIn) {
          addLog('   ❌ Skipped Punch-IN: User has already punched IN today.');
        } else {
          addLog('   ✅ Scheduled Punch-IN for: $punchInReminderTime');
          String body = 'Your shift has already started at $prettyBeginTime! Please punch in if you haven\'t already.';
          if (isHalfDayLeave) {
            body += ' (Note: You have a Half Day leave today)';
          }
          await _scheduleNotification(
            id: 1000 + i,
            title: 'Shift Punch-In Reminder',
            body: body,
            scheduledTime: punchInReminderTime,
          );
        }
      } else {
        addLog('   ❌ Skipped Punch-IN: The time $punchInReminderTime has already passed today.');
      }

      final punchOutReminderTime = DateTime(targetDate.year, targetDate.month, targetDate.day, endTime.hour, endTime.minute)
          .add(const Duration(minutes: 1));

      if (punchOutReminderTime.isAfter(now)) {
        if (hasPunchedOut) {
          addLog('   ❌ Skipped Punch-OUT: User has already punched OUT today.');
        } else {
          addLog('   ✅ Scheduled Punch-OUT for: $punchOutReminderTime');
          String body = 'Your shift has already ended at $prettyEndTime! Please punch out if you haven\'t already.';
          if (isHalfDayLeave) {
            body = 'Your Half Day leave shift has already ended! Please punch out if you haven\'t already.';
          }
          await _scheduleNotification(
            id: i * 2 + 1,
            title: 'Upcoming Punch-Out',
            body: body,
            scheduledTime: punchOutReminderTime,
          );
        }
      } else {
        addLog('   ❌ Skipped Punch-OUT: The time $punchOutReminderTime has already passed today.');
      }
    }
    addLog('--- REMINDER SCHEDULING COMPLETE ---');
    return logStr.toString();
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      try {
        final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
        await notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzTime,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'punch_reminders_channel',
              'Shift Reminders',
              channelDescription: 'Notifications for shift punch-in and punch-out reminders',
              importance: Importance.max,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound('soft_notify_sound'),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'soft_notify_sound.mp3',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        try {
          final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
          await notificationsPlugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tzTime,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'punch_reminders_channel',
                'Shift Reminders',
                channelDescription: 'Notifications for shift punch-in and punch-out reminders',
                importance: Importance.max,
                priority: Priority.high,
                sound: RawResourceAndroidNotificationSound('soft_notify_sound'),
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                sound: 'soft_notify_sound.mp3',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (e2) { /* ignored */ }
      }
    } catch (e3) { /* ignored */ }
  }

  static TimeOfDay? _parseTimeString(String timeStr) {
    try {
      // First try to parse it as a full DateTime (e.g., 2026-01-28T10:00:00)
      final parsedDate = DateTime.tryParse(timeStr);
      if (parsedDate != null) {
        int hour = parsedDate.hour;
        // PATCH: If the backend incorrectly sends 00:xx (Midnight) instead of 12:xx (Noon)
        if (hour == 0) {
          hour = 12;
        }
        return TimeOfDay(hour: hour, minute: parsedDate.minute);
      }

      // Fallback: parse standard "HH:mm" or "hh:mm am/pm"
      final parts = timeStr.trim().split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        String minuteStr = parts[1];
        
        bool isPm = false;
        bool isAm = false;
        if (minuteStr.toLowerCase().contains('pm')) {
          isPm = true;
          minuteStr = minuteStr.toLowerCase().replaceAll('pm', '').trim();
        } else if (minuteStr.toLowerCase().contains('am')) {
          isAm = true;
          minuteStr = minuteStr.toLowerCase().replaceAll('am', '').trim();
        }
        
        // Remove seconds if they were attached (e.g. "00 00" -> "00")
        int minute = int.parse(minuteStr.split(' ')[0]);
        if (isPm && hour < 12) {
          hour += 12;
        } else if (isAm && hour == 12) {
          hour = 0;
        } else if (!isPm && !isAm && hour >= 1 && hour <= 7) {
          // SMART FALLBACK: If backend sends "06:12" without AM/PM, it's very likely they meant 6:12 PM (18:12) 
          // because shifts rarely start or end between 1 AM and 7 AM.
          hour += 12;
        }
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) { /* ignored */ }
    return null;
  }

  static String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool _isDateWithinRange(DateTime target, DateTime start, DateTime end) {
    final t = DateTime(target.year, target.month, target.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !t.isBefore(s) && !t.isAfter(e);
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationLoggerService.scheduling('App resumed to foreground. Checking 7-day schedule...');
      ReminderNotificationService.scheduleAllNotifications();
    }
  }
}

