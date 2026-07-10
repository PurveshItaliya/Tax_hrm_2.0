import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:tax_hrm/models/Holidays/getholiday.dart';
import 'package:tax_hrm/models/employes/getemployes.dart';
import 'package:tax_hrm/services/notifications/notification_logger_service.dart';
import 'package:tax_hrm/utils/reminder_service.dart';

class NotificationScheduleItem {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String type; // 'birthday', 'anniversary', 'holiday', 'shift_in', 'shift_out'

  NotificationScheduleItem({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.type,
  });
}

class NotificationGeneratorService {
  /// Generates a deterministic 32-bit integer ID that is invariant across app restarts and updates.
  /// typePrefix: 1=Birthday, 2=Anniversary, 3=Holiday, 4=PunchIn, 5=PunchOut
  static int generateDeterministicId(int typePrefix, int entityId, DateTime date) {
    final int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final int safeEntityId = (entityId.abs()) % 100000;
    return (typePrefix * 100000000) + (safeEntityId * 1000) + (dayOfYear % 1000);
  }

  static bool _isLeapYear(int year) {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }

  static String getOrdinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }


  /// Generates notification schedule items for Birthdays, Work Anniversaries, and Holidays
  /// occurring within the upcoming 7 days from [now].
  static List<NotificationScheduleItem> generateAll({
    required List<Employeelists> employees,
    required List<GetHolidayViews> holidays,
    required int currentUserId,
    required DateTime now,
  }) {
    final List<NotificationScheduleItem> items = [];
    final DateTime windowEnd = now.add(const Duration(days: 7, hours: 23, minutes: 59));

    NotificationLoggerService.scheduling('Generating notifications for window: ${now.toString()} to ${windowEnd.toString()}');

    // 1. Process Employee Birthdays and Anniversaries
    for (final emp in employees) {
      if (emp.isActive == false) {
        continue;
      }

      final String empName = '${emp.firstName ?? ''} ${emp.lastName ?? ''}'.trim();
      final String displayName = empName.isEmpty ? 'Employee' : empName;
      final int empId = emp.id ?? 0;
      final bool isCurrentUser = (empId != 0 && empId == currentUserId);

      // --- BIRTHDAY CHECK ---
      if (emp.dOB != null && emp.dOB.toString().trim().isNotEmpty) {
        final DateTime? dob = DateTime.tryParse(emp.dOB.toString().trim());
        if (dob != null) {
          for (int d = 0; d < 7; d++) {
            final targetDate = now.add(Duration(days: d));
            
            bool isBirthdayToday = false;
            if (targetDate.month == dob.month && targetDate.day == dob.day) {
              isBirthdayToday = true;
            } else if (dob.month == 2 && dob.day == 29 && !_isLeapYear(targetDate.year)) {
              // Leap year baby celebrating on non-leap year -> celebrate Feb 28
              if (targetDate.month == 2 && targetDate.day == 28) {
                isBirthdayToday = true;
              }
            }

            if (isBirthdayToday) {
              final scheduledTime = DateTime(targetDate.year, targetDate.month, targetDate.day, 10, 30);
              if (scheduledTime.isAfter(now)) {
                final int notifId = generateDeterministicId(1, empId, targetDate);
                final String title = isCurrentUser ? '🎉 Happy Birthday!' : '🎂 Employee Birthday';
                final String body = isCurrentUser
                    ? '🎉 Happy Birthday, $displayName! Have an amazing day and a wonderful year ahead!'
                    : '🎂 It\'s $displayName\'s birthday today. Don\'t forget to send your best wishes!';

                items.add(NotificationScheduleItem(
                  id: notifId,
                  title: title,
                  body: body,
                  scheduledTime: scheduledTime,
                  type: 'birthday',
                ));
                NotificationLoggerService.scheduling('   🎂 Birthday scheduled for $displayName on ${scheduledTime.toString()} (ID: $notifId)');
              } else {
                NotificationLoggerService.scheduling('   ❌ Skipped Birthday for $displayName: Time ${scheduledTime.toString()} has already passed.');
              }
              break;
            }
          }
        }


      }

      // --- WORK ANNIVERSARY CHECK ---
      if (emp.dOJ != null && emp.dOJ.toString().trim().isNotEmpty) {
        final DateTime? doj = DateTime.tryParse(emp.dOJ.toString().trim());
        if (doj != null) {
          for (int d = 0; d < 7; d++) {
            final targetDate = now.add(Duration(days: d));
            
            // Only celebrate if at least 1 year has passed since joining
            if (targetDate.year > doj.year && targetDate.month == doj.month && targetDate.day == doj.day) {
              final int completedYears = targetDate.year - doj.year;
              final scheduledTime = DateTime(targetDate.year, targetDate.month, targetDate.day, 10, 30);
              if (scheduledTime.isAfter(now)) {
                final int notifId = generateDeterministicId(2, empId, targetDate);
                final String title = isCurrentUser ? '🎊 Happy Work Anniversary!' : '🎊 Work Anniversary';
                final String body = isCurrentUser
                  ? '🎉 Happy $completedYears${getOrdinalSuffix(completedYears)} Work Anniversary, $displayName! Congratulations on completing $completedYears wonderful year${completedYears > 1 ? 's' : ''} with us. Wishing you continued success and many more milestones ahead!'
                  : '🎊 Today is $displayName\'s $completedYears${getOrdinalSuffix(completedYears)} Work Anniversary! Congratulations on completing $completedYears year${completedYears > 1 ? 's' : ''} with us. Wishing you continued success and happiness!';

                items.add(NotificationScheduleItem(
                  id: notifId,
                  title: title,
                  body: body,
                  scheduledTime: scheduledTime,
                  type: 'anniversary',
                ));
                NotificationLoggerService.scheduling('   🎊 Anniversary scheduled for $displayName on ${scheduledTime.toString()} (ID: $notifId)');
              } else {
                NotificationLoggerService.scheduling('   ❌ Skipped Anniversary for $displayName: Time ${scheduledTime.toString()} has already passed.');
              }
              break;
            }
          }
        }
      }
    }

    

    // 2. Process Company Holidays
    final Set<String> scheduledHolidayDates = {};
    for (final holiday in holidays) {
      if (holiday.holidayDate == null || holiday.holidayDate!.trim().isEmpty) {
        continue;
      }

      final DateTime? hDate = DateTime.tryParse(holiday.holidayDate!.trim());
      if (hDate == null) continue;

      final String dateKey = '${hDate.year}-${hDate.month}-${hDate.day}';
      if (scheduledHolidayDates.contains(dateKey)) {
        NotificationLoggerService.duplicatePrevention('Skipped duplicate holiday on $dateKey (${holiday.holidayName})');
        continue;
      }

      // Reminder is scheduled 1 day before the holiday at 4:00 PM (16:00)
      final DateTime reminderDate = hDate.subtract(const Duration(days: 1));
      final DateTime scheduledTime = DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 16, 00);

      // Check if scheduledTime falls within our upcoming 7-day window
      if (scheduledTime.isAfter(now) && !scheduledTime.isAfter(windowEnd)) {
        scheduledHolidayDates.add(dateKey);
        final int holidayId = holiday.holidayId ?? holiday.masterCguid?.hashCode.abs() ?? hDate.day;
        final int notifId = generateDeterministicId(3, holidayId, scheduledTime);
        final String holidayName = holiday.holidayName?.trim().isNotEmpty == true ? holiday.holidayName!.trim() : 'Holiday';

        items.add(NotificationScheduleItem(
          id: notifId,
          title: '📅 Upcoming Holiday Tomorrow',
          body: 'Tomorrow is $holidayName. Plan your work accordingly and enjoy your holiday.',
          scheduledTime: scheduledTime,
          type: 'holiday',
        ));
        NotificationLoggerService.scheduling('   📅 Holiday reminder scheduled for "$holidayName" on ${scheduledTime.toString()} (ID: $notifId)');
      } else if (scheduledTime.isBefore(now)) {
        NotificationLoggerService.scheduling('   ❌ Skipped Holiday reminder for "${holiday.holidayName}": Time ${scheduledTime.toString()} has already passed.');
      }
    }

    return items;
  }

  /// Schedules all generated items using timezone-aware notifications in flutter_local_notifications.
  static Future<List<int>> scheduleItems(List<NotificationScheduleItem> items) async {
    final List<int> scheduledIds = [];

    for (final item in items) {
      try {
        final tzTime = tz.TZDateTime.from(item.scheduledTime, tz.local);
        
        const androidDetails = AndroidNotificationDetails(
          'events_reminders_channel',
          'Events & Holidays',
          channelDescription: 'Notifications for employee birthdays, work anniversaries, and company holidays',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('soft_notify_sound'),
        );
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'soft_notify_sound.mp3',
        );
        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        try {
          await ReminderNotificationService.notificationsPlugin.zonedSchedule(
            id: item.id,
            title: item.title,
            body: item.body,
            scheduledDate: tzTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          scheduledIds.add(item.id);
          NotificationLoggerService.delivery('Scheduled [${item.type}] "${item.title}" at ${tzTime.toString()} (ID: ${item.id})');
        } catch (e) {
          // Fallback to inexact if exact alarm permission is missing
          await ReminderNotificationService.notificationsPlugin.zonedSchedule(
            id: item.id,
            title: item.title,
            body: item.body,
            scheduledDate: tzTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          scheduledIds.add(item.id);
          NotificationLoggerService.delivery('Scheduled [${item.type}] (inexact) "${item.title}" at ${tzTime.toString()} (ID: ${item.id})');
        }
      } catch (e) {
        NotificationLoggerService.error('Failed to schedule notification ID ${item.id}: $e');
      }
    }

    return scheduledIds;
  }
}
