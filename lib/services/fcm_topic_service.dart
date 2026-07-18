// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/services/notifications/notification_logger_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FcmTopicService — Production-ready FCM topic subscription manager
///
/// Responsibilities:
///  • Subscribe every logged-in user to `all_users` and `all_users_{companyId}`
///  • Diff stored vs desired topics to prevent duplicate FCM calls
///  • Retry failed subscribe/unsubscribe up to 3 times with exponential backoff
///  • Verify and self-heal subscriptions on app resume or token refresh
///  • Unsubscribe and wipe topic cache on logout
///  • Emit detailed structured logs for every operation
///
/// Architecture contract:
///  • Caller (FcmTokenService) provides companyId as a string — this service
///    is intentionally stateless regarding user/company data.
///  • All topic names go through [_sanitize] to satisfy FCM naming rules.
///  • iOS APNs guard [_waitForApnsToken] is applied before every FCM call.
/// ═══════════════════════════════════════════════════════════════════════════
class FcmTopicService {
  FcmTopicService._internal();
  static final FcmTopicService instance = FcmTopicService._internal();

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String _kMandatoryTopicsKey = 'fcm_mandatory_topics_v2';

  // ── Topic name constants ───────────────────────────────────────────────────
  static const String _topicAllUsers = 'all_users';

  // ── Serial operation gate ─────────────────────────────────────────────────
  // Prevents concurrent subscribe/unsubscribe calls from racing on iOS where
  // each call must wait for the APNs token to be available.
  Future<void>? _pendingOp;

  // ══════════════════════════════════════════════════════════════════════════
  // Public API
  // ══════════════════════════════════════════════════════════════════════════

  /// Subscribe to mandatory topics for a logged-in user.
  ///
  /// Topics subscribed:
  ///   - `all_users`               — global broadcast for all employees
  ///   - `all_users_{companyId}`   — company-scoped broadcast
  ///
  /// Safe to call multiple times — diffs against stored subscriptions and
  /// only issues FCM calls for new/changed topics.
  Future<void> subscribeToMandatoryTopics({required String companyId}) async {
    final sw = Stopwatch()..start();
    _log('subscribeToMandatoryTopics called | companyId=$companyId');

    if (companyId.isEmpty) {
      _log('⚠️  companyId is empty — skipping mandatory topic subscription');
      return;
    }

    await _runOp(() async {
      final desired = _buildMandatoryTopics(companyId);
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_kMandatoryTopicsKey) ?? [];

      _log('Desired mandatory topics: $desired');
      _log('Current mandatory topics stored: $current');

      // Unsubscribe topics no longer needed (e.g. company changed)
      for (final topic in current) {
        if (!desired.contains(topic)) {
          _log('Company changed — unsubscribing stale topic: $topic');
          await _doUnsubscribe(topic);
        }
      }

      // Subscribe new topics
      int newCount = 0;
      for (final topic in desired) {
        if (!current.contains(topic)) {
          await _doSubscribe(topic);
          newCount++;
        } else {
          _log('Topic already subscribed (skipping): $topic');
          NotificationLoggerService.duplicatePrevention(
              'Duplicate subscription prevented for: $topic');
        }
      }

      // Persist updated list
      await prefs.setStringList(_kMandatoryTopicsKey, desired);

      sw.stop();
      _log('subscribeToMandatoryTopics complete | '
          'new=$newCount skipped=${desired.length - newCount} '
          'elapsed=${sw.elapsedMilliseconds}ms');
    });
  }

  /// Unsubscribe from all mandatory topics (call on logout).
  ///
  /// Also clears the stored topic list so the next login starts fresh.
  Future<void> unsubscribeFromMandatoryTopics() async {
    final sw = Stopwatch()..start();
    _log('unsubscribeFromMandatoryTopics called');

    await _runOp(() async {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_kMandatoryTopicsKey) ?? [];

      if (current.isEmpty) {
        _log('No mandatory topics stored — nothing to unsubscribe');
        return;
      }

      _log('Unsubscribing mandatory topics: $current');
      for (final topic in current) {
        await _doUnsubscribe(topic);
      }

      await prefs.remove(_kMandatoryTopicsKey);

      sw.stop();
      _log('unsubscribeFromMandatoryTopics complete | '
          'unsubscribed=${current.length} elapsed=${sw.elapsedMilliseconds}ms');
    });
  }

  /// Verify subscriptions are intact and self-heal any missing ones.
  ///
  /// Call this on:
  ///   - App resume (AppLifecycleState.resumed)
  ///   - FCM token refresh
  ///   - Company change
  ///
  /// [companyId] must be the currently active company for the logged-in user.
  /// Pass an empty string to skip (user not logged in).
  Future<void> verifyAndRepairSubscriptions({required String companyId}) async {
    _log('verifyAndRepairSubscriptions called | companyId=$companyId');

    if (companyId.isEmpty) {
      _log('No companyId — skipping subscription verification');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_kMandatoryTopicsKey) ?? [];
    final desired = _buildMandatoryTopics(companyId);

    final missing = desired.where((t) => !stored.contains(t)).toList();
    final stale = stored.where((t) => !desired.contains(t)).toList();

    if (missing.isEmpty && stale.isEmpty) {
      _log('✅ All mandatory topics verified — no repair needed');
      return;
    }

    _log('⚠️  Subscription drift detected | '
        'missing=$missing stale=$stale — triggering repair');
    await subscribeToMandatoryTopics(companyId: companyId);
  }

  /// Clear all topic-related cache (call on logout before token deletion).
  Future<void> clearAllTopicCache() async {
    final prefs = await SharedPreferences.getInstance();
    final removed = prefs.getStringList(_kMandatoryTopicsKey) ?? [];
    await prefs.remove(_kMandatoryTopicsKey);
    _log('clearAllTopicCache | removed cached topics: $removed');
    NotificationLoggerService.fcmTopic(
        'All mandatory topic cache cleared on logout');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Topic Construction
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns the two mandatory topic names for a given company.
  List<String> _buildMandatoryTopics(String companyId) {
    final sanitizedCompanyId = _sanitize(companyId);
    return [
      _topicAllUsers,                           // all_users
      '${_topicAllUsers}_$sanitizedCompanyId',  // all_users_101
    ];
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FCM Subscribe / Unsubscribe with Retry
  // ══════════════════════════════════════════════════════════════════════════

  /// Subscribe to a topic with APNs guard and 3-attempt exponential retry.
  Future<void> _doSubscribe(String topic) async {
    _log('Subscribing to topic: $topic');
    NotificationLoggerService.fcmTopic('Attempting subscribe: $topic');

    if (!await _waitForApnsToken()) {
      _log('⚠️  APNs unavailable — skipping subscribe for: $topic');
      NotificationLoggerService.error(
          'APNs unavailable, cannot subscribe: $topic');
      return;
    }

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final sw = Stopwatch()..start();
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        sw.stop();
        _log('✅ Subscribed: $topic | attempt=$attempt '
            'elapsed=${sw.elapsedMilliseconds}ms');
        NotificationLoggerService.fcmTopic(
            'Subscribed: $topic | attempt=$attempt elapsed=${sw.elapsedMilliseconds}ms');
        return;
      } catch (e) {
        _log('❌ Subscribe attempt $attempt/${ 3} failed for "$topic": $e');
        NotificationLoggerService.error(
            'Subscribe attempt $attempt/3 failed for "$topic": $e');
        if (attempt < 3) {
          final delay = attempt * 2;
          _log('Retrying in ${delay}s...');
          await Future.delayed(Duration(seconds: delay));
        }
      }
    }
    _log('❌ All 3 retry attempts exhausted for subscribe("$topic")');
    NotificationLoggerService.error(
        'All retries exhausted for subscribe("$topic")');
  }

  /// Unsubscribe from a topic with APNs guard and 3-attempt exponential retry.
  Future<void> _doUnsubscribe(String topic) async {
    _log('Unsubscribing from topic: $topic');
    NotificationLoggerService.fcmTopic('Attempting unsubscribe: $topic');

    if (!await _waitForApnsToken()) {
      _log('⚠️  APNs unavailable — skipping unsubscribe for: $topic');
      NotificationLoggerService.error(
          'APNs unavailable, cannot unsubscribe: $topic');
      return;
    }

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final sw = Stopwatch()..start();
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        sw.stop();
        _log('✅ Unsubscribed: $topic | attempt=$attempt '
            'elapsed=${sw.elapsedMilliseconds}ms');
        NotificationLoggerService.fcmTopic(
            'Unsubscribed: $topic | attempt=$attempt elapsed=${sw.elapsedMilliseconds}ms');
        return;
      } catch (e) {
        _log('❌ Unsubscribe attempt $attempt/3 failed for "$topic": $e');
        NotificationLoggerService.error(
            'Unsubscribe attempt $attempt/3 failed for "$topic": $e');
        if (attempt < 3) {
          final delay = attempt * 2;
          _log('Retrying in ${delay}s...');
          await Future.delayed(Duration(seconds: delay));
        }
      }
    }
    _log('❌ All 3 retry attempts exhausted for unsubscribe("$topic")');
    NotificationLoggerService.error(
        'All retries exhausted for unsubscribe("$topic")');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // iOS APNs Guard
  // ══════════════════════════════════════════════════════════════════════════

  bool? _isSimulator;

  Future<bool> _checkIfSimulator() async {
    if (_isSimulator != null) return _isSimulator!;
    if (!Platform.isIOS) {
      _isSimulator = false;
      return false;
    }
    try {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      _isSimulator = !iosInfo.isPhysicalDevice;
    } catch (e) {
      _isSimulator = false;
    }
    return _isSimulator!;
  }

  /// Returns true immediately on Android (APNs not required).
  /// On iOS, polls for the APNs token up to 5 times (10 s total).
  Future<bool> _waitForApnsToken() async {
    if (!Platform.isIOS) return true;

    if (await _checkIfSimulator()) {
      _log('[iOS] Running on Simulator — skipping APNs token wait');
      return false;
    }

    // Check if user has denied notifications — APNs token will never arrive
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log('[iOS] Notifications denied — APNs token unavailable');
        return false;
      }
    } catch (_) {}

    String? apns = await FirebaseMessaging.instance.getAPNSToken();
    for (int i = 0; apns == null && i < 5; i++) {
      _log('[iOS] APNs token null — retry ${i + 1}/5 in 2s…');
      await Future.delayed(const Duration(seconds: 2));
      apns = await FirebaseMessaging.instance.getAPNSToken();
    }

    if (apns == null) {
      _log('[iOS] APNs token unavailable after 5 retries');
      return false;
    }
    _log('[iOS] APNs token ready');
    return true;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// Serial async gate — ensures topic operations never run concurrently.
  /// This is critical on iOS where APNs token availability is not re-entrant.
  Future<void> _runOp(Future<void> Function() op) async {
    final prev = _pendingOp;
    final completer = Completer<void>();
    _pendingOp = completer.future;
    if (prev != null) {
      try {
        await prev;
      } catch (_) {}
    }
    try {
      await op();
    } finally {
      completer.complete();
    }
  }

  /// Sanitise a topic name to satisfy FCM naming rules: [a-zA-Z0-9-_.~%]+
  String _sanitize(String input) =>
      input.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');

  /// Structured log helper — prefixed for easy filtering in device logs.
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().split('.').first;
    final entry = '[$timestamp] [FCM_TOPIC] $message';
    if (kDebugMode) log(entry);
    NotificationLoggerService.fcmTopic(message);
  }
}
