// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/services/notifications/notification_logger_service.dart';
import 'package:tax_hrm/services/fcm_topic_service.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:tax_hrm/provider/home_provider.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/reminder_service.dart';
import 'package:tax_hrm/page/personal_info/profilepage.dart';
import 'package:tax_hrm/page/salaryslip/salary_payslip_screen.dart';
import 'package:tax_hrm/page/holidays/show_holidays.dart';
import 'package:tax_hrm/page/notes/notespage.dart';
import 'package:tax_hrm/page/document/showdocument_screen.dart';

class FcmTokenService {
  static final FcmTokenService instance = FcmTokenService._internal();
  FcmTokenService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Map<String, dynamic>? _pendingPayload;
  bool _isInitialized = false;

  // Set to true to disable ALL FCM topic subscriptions during local testing.
  // ⚠️  Keep false in production — mandatory topics (all_users, all_users_{companyId})
  //     must reach every user regardless of build mode.
  static const bool disableTopicsForTesting = false;

  // ── Topic strategy ─────────────────────────────────────────────────────────
  // Serial gate: prevents concurrent subscribe/unsubscribe calls from racing
  // on iOS where each call must wait for the APNs token.
  Future<void>? _pendingTopicOp;

  // SharedPreferences key that stores the currently active login-scoped topics
  // (everything except 'ALL') so we can diff on company/role change.
  static const String _kLoginTopicsKey = 'fcm_login_topics';
  // SharedPreferences key that tracks if the device is subscribed to the global 'ALL' topic
  static const String _kSubscribedAllKey = 'fcm_subscribed_all';

  /// Initialize FCM listeners and retrieve token if user is logged in
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Reset badge count on startup
    resetBadgeCount();

    // ── iOS: Request FCM-level notification permission ──────────────────────
    // This is REQUIRED on iOS. Without it, the system will not deliver
    // push notifications and getAPNSToken() will return null, causing all
    // topic subscriptions to silently fail.
    if (Platform.isIOS) {
      try {
        final NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
        print('[FCM] iOS permission status: ${settings.authorizationStatus}');
      } catch (e) {
        print('[FCM] Error requesting iOS FCM permission: $e');
      }
    }

    // Create high importance notification channel on Android
    if (Platform.isAndroid) {
      try {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            ReminderNotificationService.notificationsPlugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          description: 'This channel is used for high priority push notifications.', // description
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('soft_notify_sound'),
          enableVibration: true,
        );

        await androidImplementation?.createNotificationChannel(channel);
        print('[FCM] Android high importance channel created.');
      } catch (e) {
        print('[FCM] Error creating Android notification channel: $e');
      }
    }

    // Listen to token refresh — re-subscribe mandatory topics because the
    // old FCM token is now invalid and topic bindings live per-token.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('[FCM] Token refreshed: $newToken');
      NotificationLoggerService.fcmTopic('FCM token refreshed — re-syncing mandatory topics');
      await _saveTokenLocally(newToken);
      await uploadTokenToServer(newToken);
      // Force re-subscription because the new token starts with no topics
      await _resubscribeMandatoryTopicsAfterTokenRefresh();
    });

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('[FCM] Foreground message received: ${message.notification?.title}');
      await _showLocalNotification(message);
    });

    // Handle background click (app was running in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('[FCM] App opened from background state via notification: ${message.messageId}');
      handleNotificationPayload(jsonEncode(message.data));
    });

    // Handle terminated state click
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('[FCM] App opened from terminated state via notification: ${message.messageId}');
        _pendingPayload = message.data;
      }
    });

    // Handle token at startup (if logged in)
    await handleTokenSync();

    // ── Subscribe ALL topic on every app start ─────────────────────────────
    // 'ALL' is the global broadcast topic. All installed devices must be
    // subscribed regardless of login state so general announcements reach them.
    unawaited(_runTopicOp(() async {
      final prefs = await SharedPreferences.getInstance();
      final hasCleanedLegacyAll = prefs.getBool('fcm_cleaned_legacy_all') ?? false;
      if (!hasCleanedLegacyAll) {
        await _doUnsubscribe('all');
        await prefs.setBool('fcm_cleaned_legacy_all', true);
      }
      await _subscribeToGlobalAll();
    }));
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (SDK 33)
      var status = await Permission.notification.status;
      if (!status.isGranted) {
        status = await Permission.notification.request();
      }
      if (status.isGranted) {
        await handleTokenSync();
        return true;
      }
      return false;
    } else if (Platform.isIOS) {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      bool granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                     settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) {
        await handleTokenSync();
        return true;
      }
      return false;
    }
    return false;
  }

  /// Sync token: fetch from FCM and upload if logged in
  Future<void> handleTokenSync() async {
    try {
      if (Platform.isIOS) {
        if (await _shouldSkipApnsWait()) {
          print('[FCM] Skipping APNs token wait.');
          return;
        }
        String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        int retries = 0;
        while (apnsToken == null && retries < 5) {
          print('[FCM] APNs token is null. Retrying in 2 seconds (attempt ${retries + 1}/5)...');
          await Future.delayed(const Duration(seconds: 2));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          retries++;
        }
        if (apnsToken == null) {
          print('[FCM] APNs token could not be retrieved after retries. Skip fetching FCM token.');
          return;
        }
        print('[FCM] APNs Token retrieved: $apnsToken');
      }

      // Requesting token
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('[FCM] Retrieved token: $token');
        await _saveTokenLocally(token);
        await uploadTokenToServer(token);
      }
    } catch (e) {
      print('[FCM] Error fetching token: $e');
    }
  }

  /// Upload token to the backend
  Future<void> uploadTokenToServer(String token) async {
    if (curentUser == null || curentUser['Id'] == null || selectedcurentcompany == null) {
      print('[FCM] Skipping upload: User is not logged in or company is not selected.');
      NotificationLoggerService.fcmTopic('Token upload skipped — user not logged in or no company selected');
      return;
    }
    try {
      final empId = curentUser['Id'];
      final companyId = selectedcurentcompany?.companyId?.toString() ?? curentUser['CompanyId']?.toString() ?? '';
      final role = curentUser['Role']?.toString() ?? 'Unknown';
      print('[FCM] Uploading token to server | EmpId=$empId CompanyId=$companyId Role=$role');
      NotificationLoggerService.fcmTopic(
          'Uploading FCM token | EmpId=$empId CompanyId=$companyId Role=$role Token=${token.length > 20 ? '${token.substring(0, 20)}...' : token}');
      await AttendanceApis().notificationTokens(token, empId);
      print('[FCM] Token uploaded successfully.');
      NotificationLoggerService.fcmTopic('Token upload successful for EmpId=$empId');
      // After successful token upload, sync all login-scoped AND mandatory topic subscriptions.
      unawaited(subscribeLoginTopics());
    } catch (e) {
      print('[FCM] Error uploading token: $e');
      NotificationLoggerService.error('Token upload failed: $e');
    }
  }

  /// Delete/Deactivate token on logout.
  /// Unsubscribes from all login-scoped topics AND the mandatory topics
  /// (`all_users`, `all_users_{companyId}`). Clears all topic caches so the
  /// previous account's notifications cannot reach this device.
  Future<void> handleLogout() async {
    try {
      final empId = curentUser?['Id'];
      final companyId = selectedcurentcompany?.companyId?.toString() ??
          curentUser?['CompanyId']?.toString() ?? '';
      print('[FCM] handleLogout | EmpId=$empId CompanyId=$companyId');
      NotificationLoggerService.fcmTopic(
          'Logout initiated | EmpId=$empId CompanyId=$companyId — unsubscribing all topics');

      // 1. Unsubscribe from mandatory topics (all_users, all_users_{companyId})
      unawaited(FcmTopicService.instance.unsubscribeFromMandatoryTopics());

      // 2. Unsubscribe from all other login-scoped topics
      unawaited(unsubscribeLoginTopics());

      // 3. Clear all mandatory topic cache immediately so next user starts clean
      await FcmTopicService.instance.clearAllTopicCache();

      // 4. Clear token on server (2-second timeout to prevent blocking if offline)
      if (empId != null) {
        print('[FCM] Clearing token on server for EmpId $empId...');
        try {
          await AttendanceApis()
              .notificationTokens('', empId)
              .timeout(const Duration(seconds: 2));
          NotificationLoggerService.fcmTopic('Server token cleared for EmpId=$empId');
        } catch (e) {
          print('[FCM] Timeout or error clearing token on server: $e');
          NotificationLoggerService.error('Server token clear failed: $e');
        }
      }

      // 5. Fire-and-forget FCM token deletion so next login gets a fresh token
      unawaited(() async {
        try {
          await FirebaseMessaging.instance.deleteToken();
          await _clearLocalToken();
          print('[FCM] Token deleted successfully.');
          NotificationLoggerService.fcmTopic('FCM token deleted on logout');

          // Reset all local topic caches — token changed so old subscriptions
          // are now invalid.
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_kSubscribedAllKey);
          await prefs.remove(_kLoginTopicsKey);

          // Re-subscribe to global 'ALL' broadcast topic for the new (anonymous) token
          await _subscribeToGlobalAll();
        } catch (e) {
          print('[FCM] Error during logout token deletion: $e');
          NotificationLoggerService.error('Logout token deletion failed: $e');
        }
      }());
    } catch (e) {
      print('[FCM] Error during logout: $e');
      NotificationLoggerService.error('handleLogout unexpected error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Topic Strategy – Public API
  // ══════════════════════════════════════════════════════════════════════════

  /// Call after login / company selection.
  ///
  /// Subscribes to:
  ///   • Mandatory:  `all_users`, `all_users_{companyId}` (via FcmTopicService)
  ///   • Role-based: `ALL_ADMIN_{companyId}` or `ALL_USER_{companyId}`
  ///   • Company:    `COMPANY_{companyId}`
  ///
  /// Diffs against previously stored topics to avoid duplicate FCM calls.
  Future<void> subscribeLoginTopics() async {
    final empId = curentUser?['Id'];
    final companyId = selectedcurentcompany?.companyId?.toString() ??
        curentUser?['CompanyId']?.toString() ?? '';
    final role = curentUser?['Role']?.toString() ?? 'Unknown';

    print('[FCM] subscribeLoginTopics | EmpId=$empId CompanyId=$companyId Role=$role');
    NotificationLoggerService.fcmTopic(
        'subscribeLoginTopics called | EmpId=$empId CompanyId=$companyId Role=$role');

    await _runTopicOp(() async {
      if (curentUser == null || curentUser['Id'] == null) {
        print('[FCM Topic] No logged-in user. Ensuring all login-scoped topics are unsubscribed.');
        NotificationLoggerService.fcmTopic('No logged-in user — clearing all login-scoped topics');
        final prefs = await SharedPreferences.getInstance();
        final List<String> current = prefs.getStringList(_kLoginTopicsKey) ?? [];
        if (current.isNotEmpty) {
          for (final t in current) {
            if (t != 'ALL') {
              await _doUnsubscribe(t);
            }
          }
          await prefs.remove(_kLoginTopicsKey);
        }
        return;
      }

      // Check if user is active/blocked/deleted on backend
      final bool isActive = await _checkIfUserActive();
      if (!isActive) {
        print('[FCM Topic] User is inactive, blocked, or deleted. Unsubscribing login-scoped topics.');
        NotificationLoggerService.fcmTopic(
            'User EmpId=$empId is inactive/deleted — removing login-scoped topics');
        final prefs = await SharedPreferences.getInstance();
        final List<String> current = prefs.getStringList(_kLoginTopicsKey) ?? [];
        for (final t in current) {
          if (t != 'ALL') {
            await _doUnsubscribe(t);
          }
        }
        await prefs.remove(_kLoginTopicsKey);
        return;
      }

      final List<String> desired = _buildLoginTopics();
      final prefs = await SharedPreferences.getInstance();
      final List<String> current = prefs.getStringList(_kLoginTopicsKey) ?? [];

      print('[FCM Topic] Login topics | Current: $current → Desired: $desired');
      NotificationLoggerService.fcmTopic(
          'Login topics | Current: $current → Desired: $desired');

      // Unsubscribe topics no longer needed
      for (final t in current) {
        if (!desired.contains(t)) {
          if (t != 'ALL') {
            await _doUnsubscribe(t);
          }
        }
      }
      // Subscribe new topics
      for (final t in desired) {
        if (!current.contains(t)) {
          await _doSubscribe(t);
        }
      }
      await prefs.setStringList(_kLoginTopicsKey, desired);
    });

    // ── Always sync mandatory topics (all_users, all_users_{companyId}) ────
    // This runs OUTSIDE the serial gate to avoid blocking the existing
    // login-scoped subscriptions above.
    if (companyId.isNotEmpty) {
      unawaited(subscribeMandatoryTopics());
    } else {
      NotificationLoggerService.fcmTopic(
          'Mandatory topic subscription skipped — companyId not available yet');
    }
  }

  /// Call on logout.
  /// Removes all login-scoped topics; keeps 'all' intact.
  Future<void> unsubscribeLoginTopics() async {
    await _runTopicOp(() async {
      final prefs = await SharedPreferences.getInstance();
      final List<String> current = prefs.getStringList(_kLoginTopicsKey) ?? [];
      print('[FCM Topic] Unsubscribing login topics: $current');
      NotificationLoggerService.fcmTopic('Unsubscribing login topics: $current');
      for (final t in current) {
        if (t != 'ALL') {
          await _doUnsubscribe(t);
        }
      }
      await prefs.remove(_kLoginTopicsKey);
    });
  }

  /// Call when the user switches company or role.
  /// Re-syncs both login-scoped topics AND mandatory topics.
  Future<void> updateTopicSubscriptions() async {
    final companyId = selectedcurentcompany?.companyId?.toString() ??
        curentUser?['CompanyId']?.toString() ?? '';
    print('[FCM] updateTopicSubscriptions | CompanyId=$companyId');
    NotificationLoggerService.fcmTopic(
        'updateTopicSubscriptions | CompanyId=$companyId');
    await subscribeLoginTopics();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Mandatory Topic Public API — delegates to FcmTopicService
  // ══════════════════════════════════════════════════════════════════════════

  /// Subscribe to `all_users` and `all_users_{companyId}`.
  ///
  /// Call after login, on app resume, or after a company change.
  /// Safe to call multiple times — deduplication is handled internally.
  Future<void> subscribeMandatoryTopics() async {
    final companyId = selectedcurentcompany?.companyId?.toString() ??
        curentUser?['CompanyId']?.toString() ?? '';
    final empId = curentUser?['Id'];
    final role = curentUser?['Role']?.toString() ?? 'Unknown';

    print('[FCM] subscribeMandatoryTopics | EmpId=$empId CompanyId=$companyId Role=$role');
    NotificationLoggerService.fcmTopic(
        'subscribeMandatoryTopics | EmpId=$empId CompanyId=$companyId Role=$role');

    if (companyId.isEmpty) {
      print('[FCM] subscribeMandatoryTopics: companyId empty — skipping');
      return;
    }
    await FcmTopicService.instance
        .subscribeToMandatoryTopics(companyId: companyId);
  }

  /// Unsubscribe from `all_users` and `all_users_{companyId}`.
  ///
  /// Call on logout. Also invoked by [handleLogout].
  Future<void> unsubscribeMandatoryTopics() async {
    final companyId = selectedcurentcompany?.companyId?.toString() ??
        curentUser?['CompanyId']?.toString() ?? '';
    print('[FCM] unsubscribeMandatoryTopics | CompanyId=$companyId');
    NotificationLoggerService.fcmTopic(
        'unsubscribeMandatoryTopics | CompanyId=$companyId');
    await FcmTopicService.instance.unsubscribeFromMandatoryTopics();
  }

  /// Verify mandatory topics are intact and repair any missing subscriptions.
  ///
  /// Call on app resume (AppLifecycleState.resumed) or token refresh.
  Future<void> verifyMandatoryTopics() async {
    final companyId = selectedcurentcompany?.companyId?.toString() ??
        curentUser?['CompanyId']?.toString() ?? '';
    if (curentUser == null || companyId.isEmpty) return;
    print('[FCM] verifyMandatoryTopics | CompanyId=$companyId');
    await FcmTopicService.instance
        .verifyAndRepairSubscriptions(companyId: companyId);
  }

  /// Internal: called after an FCM token refresh to force re-subscription
  /// on the new token (which starts with zero topic bindings).
  Future<void> _resubscribeMandatoryTopicsAfterTokenRefresh() async {
    final companyId = selectedcurentcompany?.companyId?.toString() ??
        curentUser?['CompanyId']?.toString() ?? '';
    if (companyId.isEmpty) return;
    // Clear stored topics so they are re-subscribed unconditionally
    await FcmTopicService.instance.clearAllTopicCache();
    await FcmTopicService.instance
        .subscribeToMandatoryTopics(companyId: companyId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Topic Strategy – Private Helpers
  // ══════════════════════════════════════════════════════════════════════════

  /// Builds the desired login-scoped topic list from current user/company state.
  List<String> _buildLoginTopics() {
    final List<String> topics = [];
    topics.add('ALL');

    final companyId = selectedcurentcompany?.companyId ?? curentUser?['CompanyId'];

    // Role-based topic
    final role = curentUser?['Role']?.toString() ?? '';
    if (companyId != null) {
      if (role == 'Admin' || role == 'Owner') {
        topics.add(_sanitize('ALL_ADMIN_$companyId'));
      } else {
        topics.add(_sanitize('ALL_USER_$companyId'));
      }
    }

    // Company-based topic
    if (companyId != null) {
      topics.add(_sanitize('COMPANY_$companyId'));
    }

    // Individual user topic
    // final userId = curentUser?['Id'];
    // final userName = (curentUser?['UserName'] ?? curentUser?['Username'])?.toString();
    // if (userId != null && userName != null && userName.isNotEmpty) {
    //   topics.add(_sanitize('USER_${userId}_$userName'));
    // }

    return topics;
  }

// 
  /// Query the backend to check if the currently logged-in user is active, blocked, or deleted.
  Future<bool> _checkIfUserActive() async {
    if (curentUser == null || curentUser['Id'] == null) {
      return false;
    }
    try {
      final role = curentUser['Role']?.toString() ?? '';
      final originalRole = curentUser['OriginalRole'];
      final id = curentUser['Id'];
      final token = curentUser['token'] ?? curentUser['Token'] ?? '';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'bearer $token',
      };

      http.Response response;
      if (role == 'Admin' && originalRole == null) {
        final url = Uri.parse('${apibaseurl}api/Master/UsermstLsitById?Id=$id');
        response = await http.get(url, headers: headers);
      } else {
        final url = Uri.parse('${apibaseurl}api/Master/GetEmpListById?Id=$id');
        response = await http.get(url, headers: headers);
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final bool isActive = _parseIsActive(data['IsActive'] ?? data['isActive']);
        return isActive;
      } else if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 404) {
        print('[FCM] User status check returned statusCode: ${response.statusCode}. Treating as inactive/deleted.');
        return false;
      }
      return true; // Keep active on transient HTTP errors (e.g. 500)
    } catch (e) {
      print('[FCM] Error checking user active status: $e. Defaulting to active to prevent false unsubscriptions.');
      return true; // Keep active on network timeouts or failures
    }
  }

  bool _parseIsActive(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val == 1;
    final s = val.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  /// Sanitise a topic name to meet FCM constraints: [a-zA-Z0-9-_.~%]+
  String _sanitize(String topic) =>
      topic.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');

  /// Subscribe to a single topic with iOS APNs guard + 3-attempt retry.
  Future<void> _doSubscribe(String topic) async {
    if (kDebugMode && disableTopicsForTesting) {
      print('[FCM Topic] _doSubscribe: Skipped for testing purpose: $topic');
      return;
    }
    if (!await _waitForApnsToken()) {
      print('[FCM Topic] _doSubscribe: APNs unavailable, skipping: $topic');
      return;
    }
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
        print('[FCM Topic] ✅ Subscribed: $topic');
        NotificationLoggerService.fcmTopic('Subscribed: $topic');
        return;
      } catch (e) {
        print('[FCM Topic] Attempt $attempt failed for subscribe($topic): $e');
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    print('[FCM Topic] ❌ All retries failed for subscribe($topic)');
    NotificationLoggerService.error('All retries failed for subscribe($topic)');
  }

  /// Unsubscribe from a single topic with iOS APNs guard + 3-attempt retry.
  Future<void> _doUnsubscribe(String topic) async {
    if (kDebugMode && disableTopicsForTesting) {
      print('[FCM Topic] _doUnsubscribe: Skipped for testing purpose: $topic');
      return;
    }
    if (!await _waitForApnsToken()) {
      print('[FCM Topic] _doUnsubscribe: APNs unavailable, skipping: $topic');
      return;
    }
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
        print('[FCM Topic] ✅ Unsubscribed: $topic');
        NotificationLoggerService.fcmTopic('Unsubscribed: $topic');
        return;
      } catch (e) {
        print('[FCM Topic] Attempt $attempt failed for unsubscribe($topic): $e');
        if (attempt < 3) await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    print('[FCM Topic] ❌ All retries failed for unsubscribe($topic)');
    NotificationLoggerService.error('All retries failed for unsubscribe($topic)');
  }

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

  Future<bool> _shouldSkipApnsWait() async {
    if (!Platform.isIOS) return true;
    if (await _checkIfSimulator()) {
      return true;
    }
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('[FCM] Notification permissions denied. APNs token will not be available, skipping wait.');
        return true;
      }
    } catch (e) {
      // ignore
    }
    return false;
  }

  /// Subscribe to the global broadcast topic 'ALL' only if not already subscribed.
  Future<void> _subscribeToGlobalAll() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool(_kSubscribedAllKey) ?? false;
    if (!isSubscribed) {
      print('[FCM Topic] Subscribing to global ALL topic...');
      await _doSubscribe('ALL');
      await prefs.setBool(_kSubscribedAllKey, true);
    } else {
      print('[FCM Topic] Already subscribed to global ALL topic. Skipping subscription.');
    }
  }

  /// Waits up to ~10 s for the APNs token on iOS.
  /// Returns true immediately on Android (APNs not required).
  Future<bool> _waitForApnsToken() async {
    if (!Platform.isIOS) return true;
    if (await _shouldSkipApnsWait()) {
      print('[FCM Topic] APNs token unavailable or skipped, skipping wait.');
      return false;
    }
    String? apns = await FirebaseMessaging.instance.getAPNSToken();
    for (int i = 0; apns == null && i < 5; i++) {
      print('[FCM Topic] APNs token null, retrying in 2 s (${i + 1}/5)…');
      await Future.delayed(const Duration(seconds: 2));
      apns = await FirebaseMessaging.instance.getAPNSToken();
    }
    if (apns == null) {
      print('[FCM Topic] APNs token unavailable after retries.');
      return false;
    }
    return true;
  }

  /// Serial async gate — ensures topic operations never run concurrently.
  Future<void> _runTopicOp(Future<void> Function() op) async {
    final prev = _pendingTopicOp;
    final completer = _AsyncCompleter();
    _pendingTopicOp = completer.future;
    if (prev != null) {
      try { await prev; } catch (_) {}
    }
    try {
      await op();
    } finally {
      completer.complete();
    }
  }

  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_device_token', token);
  }

  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_device_token');
  }

  Future<void> _clearLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_device_token');
  }

  /// Reset iOS app icon badge count
  void resetBadgeCount() {
    // Badges are automatically cleared natively on iOS when the app becomes active.
  }

  /// Download dynamic image from FCM payload url
  Future<String?> _downloadAndSaveFile(String url, String fileName) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$fileName';
      final http.Response response = await http.get(Uri.parse(url));
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      print('[FCM] Error downloading file: $e');
      return null;
    }
  }

  /// Display foreground FCM notification using local notifications
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title'] ?? 'Notification';
      final body = notification?.body ?? message.data['body'] ?? '';
      
      final imageUrl = notification?.android?.imageUrl ??
                       notification?.apple?.imageUrl ??
                       message.data['image'] ??
                       message.data['imageUrl'];

      String? largeIconPath;
      String? bigPicturePath;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        largeIconPath = await _downloadAndSaveFile(imageUrl, 'largeIcon');
        bigPicturePath = await _downloadAndSaveFile(imageUrl, 'bigPicture');
      }

      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for high priority push notifications.',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('soft_notify_sound'),
        icon: '@mipmap/ic_launcher',
        largeIcon: largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
        styleInformation: bigPicturePath != null
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(bigPicturePath),
                largeIcon: largeIconPath != null ? FilePathAndroidBitmap(largeIconPath) : null,
                contentTitle: title,
                summaryText: body,
              )
            : null,
      );

      final List<DarwinNotificationAttachment>? attachments = bigPicturePath != null
          ? [DarwinNotificationAttachment(bigPicturePath)]
          : null;

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'soft_notify_sound.mp3',
        attachments: attachments,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await ReminderNotificationService.notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      print('[FCM] Error displaying local notification: $e');
    }
  }

  /// Handle notification payload processing
  void handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateToScreen(data);
    } catch (e) {
      print('[FCM] Error parsing notification payload: $e');
    }
  }

  /// Route user context to target screen based on payload
  void _navigateToScreen(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print('[FCM] Navigator context is null. Saving pending redirection.');
      _pendingPayload = data;
      return;
    }

    final screen = data['screen']?.toString();
    if (screen == null) return;

    if (curentUser == null || curentUser['Id'] == null) {
      print('[FCM] User is not logged in. Cannot redirect to $screen.');
      return;
    }

    try {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      if (screen == 'attendance') {
        homeProvider.changeSelectBottomBar(1);
      } else if (screen == 'leave') {
        homeProvider.changeSelectBottomBar(2);
      } else if (screen == 'home') {
        homeProvider.changeSelectBottomBar(0);
      } else if (screen == 'setting') {
        homeProvider.changeSelectBottomBar(3);
      } else if (screen == 'profile') {
        nextScreen(context, ProfileViewPage(isEdit: false));
      } else if (screen == 'salary_payslip') {
        nextScreen(context, const SalaryPayslipScreen());
      } else if (screen == 'holidays') {
        nextScreen(context, const ShowHolidayViews());
      } else if (screen == 'notes') {
        nextScreen(context, const NotesViewPage());
      } else if (screen == 'document') {
        nextScreen(context, const ShowDocumentScreen());
      }
    } catch (e) {
      print('[FCM] Navigation error: $e');
    }
  }

  /// Check and process any pending notification tap action
  void checkPendingNotification() {
    if (_pendingPayload != null) {
      print('[FCM] Resolving pending notification payload: $_pendingPayload');
      final data = _pendingPayload!;
      _pendingPayload = null;
      _navigateToScreen(data);
    }
    resetBadgeCount();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Minimal completer used by _runTopicOp to build a serial async gate without
// exposing a raw Completer<void> in the public API.
// ─────────────────────────────────────────────────────────────────────────────
class _AsyncCompleter {
  final _completer = Completer<void>();
  Future<void> get future => _completer.future;
  void complete() => _completer.complete();
}

// ignore: prefer_void_to_null
/// Fire-and-forget helper — silences the unawaited-future lint.
void unawaited(Future<void> future) {}
