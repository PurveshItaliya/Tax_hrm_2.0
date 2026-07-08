import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tax_hrm/services/notifications/notification_logger_service.dart';
import 'package:tax_hrm/services/permission_flow_service.dart';
import 'package:tax_hrm/utils/reminder_service.dart';
import 'package:tax_hrm/widigets/permission_dialog_widget.dart';

class NotificationPermissionService {
  /// Requests notification permissions on Android (Android 13+ POST_NOTIFICATIONS) and iOS (Alert, Sound, Badge).
  /// If permission is denied or permanently denied, handles it gracefully and allows the user to enable it from Settings.
  static Future<bool> requestNotificationPermission(BuildContext? context) async {
    NotificationLoggerService.permission('Checking notification permission status...');
    
    try {
      PermissionStatus status = await Permission.notification.status;
      
      if (status.isGranted) {
        if (Platform.isIOS) {
          await _requestIosPermissions();
        }
        NotificationLoggerService.permission('Notification permission is already granted.');
        return true;
      }

      if (status.isPermanentlyDenied) {
        NotificationLoggerService.permission('Notification permission is permanently denied.');
        if (context != null && context.mounted) {
          final openSettings = await PermissionDialogWidget.showPermanentlyDeniedDialog(
            context,
            PermissionType.notification,
          );
          if (openSettings) {
            NotificationLoggerService.permission('User chose to open App Settings for notification permission.');
            await openAppSettings();
          }
        }
        return false;
      }

      NotificationLoggerService.permission('Requesting notification permission from user...');
      
      if (Platform.isIOS) {
        final iosGranted = await _requestIosPermissions();
        status = await Permission.notification.status;
        if (iosGranted == true || status.isGranted) {
          NotificationLoggerService.permission('iOS Notification permissions granted (Alert, Sound, Badge).');
          return true;
        }
      } else {
        status = await Permission.notification.request();
      }

      if (status.isGranted) {
        NotificationLoggerService.permission('Notification permission granted.');
        return true;
      } else if (status.isPermanentlyDenied) {
        NotificationLoggerService.permission('Notification permission denied permanently after prompt.');
        if (context != null && context.mounted) {
          final openSettings = await PermissionDialogWidget.showPermanentlyDeniedDialog(
            context,
            PermissionType.notification,
          );
          if (openSettings) {
            await openAppSettings();
          }
        }
        return false;
      } else {
        NotificationLoggerService.permission('Notification permission denied gracefully.');
        return false;
      }
    } catch (e) {
      NotificationLoggerService.error('Error while requesting notification permission: $e');
      return false;
    }
  }

  static Future<bool?> _requestIosPermissions() async {
    try {
      final iosImplementation = ReminderNotificationService.notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        return await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      NotificationLoggerService.error('Error requesting iOS specific permissions: $e');
    }
    return null;
  }
}
