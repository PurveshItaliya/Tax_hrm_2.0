import 'package:flutter/foundation.dart';

enum NotificationLogCategory {
  permission,
  apiFetch,
  scheduling,
  duplicatePrevention,
  delivery,
  error,
  fcmTopic,
}

class NotificationLoggerService {
  static final List<String> _logHistory = [];
  static const int _maxHistorySize = 500;

  static void log(NotificationLogCategory category, String message) {
    final timestamp = DateTime.now().toIso8601String().split('.').first;
    final categoryName = category.name.toUpperCase();
    final logMessage = '[$timestamp] [NOTIF_$categoryName] $message';

    _logHistory.add(logMessage);
    if (_logHistory.length > _maxHistorySize) {
      _logHistory.removeAt(0);
    }

    if (kDebugMode) {
      print(logMessage);
    }
  }

  static void permission(String message) => log(NotificationLogCategory.permission, message);
  static void apiFetch(String message) => log(NotificationLogCategory.apiFetch, message);
  static void scheduling(String message) => log(NotificationLogCategory.scheduling, message);
  static void duplicatePrevention(String message) => log(NotificationLogCategory.duplicatePrevention, message);
  static void delivery(String message) => log(NotificationLogCategory.delivery, message);
  static void error(String message) => log(NotificationLogCategory.error, message);
  static void fcmTopic(String message) => log(NotificationLogCategory.fcmTopic, message);

  static List<String> getHistory() => List.unmodifiable(_logHistory);

  static void clearHistory() => _logHistory.clear();
}
