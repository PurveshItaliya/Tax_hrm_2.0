// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  final Set<String> _customSubscribedTopics = {};
  Future<void>? _pendingSubscriptionOp;

  /// Initialize FCM listeners and retrieve token if user is logged in
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Reset badge count on startup
    resetBadgeCount();

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

    // Listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('[FCM] Token refreshed: $newToken');
      await _saveTokenLocally(newToken);
      await uploadTokenToServer(newToken);
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
      return;
    }
    try {
      final empId = curentUser['Id'];
      print('[FCM] Uploading token to server for EmpId $empId...');
      await AttendanceApis().notificationTokens(token, empId);
      print('[FCM] Token uploaded successfully.');
      await subscribeToCompanyTopic();
    } catch (e) {
      print('[FCM] Error uploading token: $e');
    }
  }

  Future<bool> _waitForApnsTokenIfNeeded() async {
    if (!Platform.isIOS) return true;
    try {
      String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      int retries = 0;
      while (apnsToken == null && retries < 5) {
        print('[FCM] APNs token not available for topic operation. Retrying in 2 seconds (attempt ${retries + 1}/5)...');
        await Future.delayed(const Duration(seconds: 2));
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        retries++;
      }
      return apnsToken != null;
    } catch (e) {
      print('[FCM] Error checking APNs token: $e');
      return false;
    }
  }

  Future<void> _queueOperation(Future<void> Function() operation) async {
    final completer = Completer<void>();
    final previousOp = _pendingSubscriptionOp;
    _pendingSubscriptionOp = completer.future;

    if (previousOp != null) {
      try {
        await previousOp;
      } catch (_) {}
    }

    try {
      await operation();
    } finally {
      completer.complete();
    }
  }

  /// Subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    await _queueOperation(() async {
      if (Platform.isIOS) {
        final hasApns = await _waitForApnsTokenIfNeeded();
        if (!hasApns) {
          print('[FCM] Aborting subscribeToTopic: APNs token is not set on iOS.');
          return;
        }
      }
      final sanitized = sanitizeTopic(topic);
      if (_customSubscribedTopics.contains(sanitized)) {
        print('[FCM] Already subscribed to custom topic: $sanitized. Skipping duplicate entry.');
        return;
      }
      try {
        print('[FCM] Subscribing to topic: $sanitized...');
        await FirebaseMessaging.instance.subscribeToTopic(sanitized);
        _customSubscribedTopics.add(sanitized);
        print('[FCM] Successfully subscribed to topic: $sanitized');
      } catch (e) {
        print('[FCM] Error subscribing to topic $sanitized: $e');
      }
    });
  }

  /// Unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _queueOperation(() async {
      if (Platform.isIOS) {
        final hasApns = await _waitForApnsTokenIfNeeded();
        if (!hasApns) {
          print('[FCM] Aborting unsubscribeFromTopic: APNs token is not set on iOS.');
          return;
        }
      }
      final sanitized = sanitizeTopic(topic);
      try {
        print('[FCM] Unsubscribing from topic: $sanitized...');
        await FirebaseMessaging.instance.unsubscribeFromTopic(sanitized);
        _customSubscribedTopics.remove(sanitized);
        print('[FCM] Successfully unsubscribed from topic: $sanitized');
      } catch (e) {
        print('[FCM] Error unsubscribing from topic $sanitized: $e');
      }
    });
  }

  /// Sanitize topic names to match FCM constraints ([a-zA-Z0-9-_.~%]+)
  String sanitizeTopic(String topic) {
    return topic.replaceAll(RegExp(r'[^a-zA-Z0-9\-_.~%]'), '_');
  }

  /// Update topic subscriptions dynamically based on user and company details
  Future<void> updateTopicSubscriptions() async {
    await _queueOperation(() async {
      if (curentUser == null || curentUser['Id'] == null) {
        print('[FCM] User is not logged in. Skipping topic subscriptions update.');
        return;
      }

      if (Platform.isIOS) {
        final hasApns = await _waitForApnsTokenIfNeeded();
        if (!hasApns) {
          print('[FCM] Aborting updateTopicSubscriptions: APNs token is not set on iOS.');
          return;
        }
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final List<String> oldTopics = prefs.getStringList('fcm_subscribed_topics') ?? [];
        final List<String> newTopics = [];

        // 1. 'all'
        newTopics.add('all');

        // 2. Role-based topic
        final role = curentUser['Role']?.toString() ?? '';
        if (role == 'Admin') {
          newTopics.add('all_admin');
        } else if (role == 'Sub-Admin') {
          newTopics.add('all_subadmin');
        } else {
          newTopics.add('all_user');
        }

        // 3. Company-based topic
        final companyId = selectedcurentcompany?.companyId ?? curentUser?['CompanyId'];
        if (companyId != null) {
          newTopics.add(sanitizeTopic('company_$companyId'));
        }

        // 4. Branch-based topic (optional)
        final branchId = curentUser?['BranchId'] ?? curentUser?['branchId'];
        if (branchId != null) {
          newTopics.add(sanitizeTopic('branch_$branchId'));
        }

        // 5. Individual user topic
        final userId = curentUser?['Id'];
        final userName = curentUser?['UserName'] ?? curentUser?['Username'];
        if (userId != null && userName != null) {
          newTopics.add(sanitizeTopic('user_${userId}_$userName'));
        }

        print('[FCM] Updating subscriptions. Old: $oldTopics, New: $newTopics');

        // Unsubscribe from old topics that are not in new list
        for (final topic in oldTopics) {
          if (!newTopics.contains(topic)) {
            try {
              await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
              print('[FCM] Successfully unsubscribed from old topic: $topic');
            } catch (e) {
              print('[FCM] Error unsubscribing from old topic $topic: $e');
            }
          }
        }

        // Subscribe to new topics that are not in old list
        for (final topic in newTopics) {
          if (!oldTopics.contains(topic)) {
            try {
              await FirebaseMessaging.instance.subscribeToTopic(topic);
              print('[FCM] Successfully subscribed to new topic: $topic');
            } catch (e) {
              print('[FCM] Error subscribing to new topic $topic: $e');
            }
          }
        }

        await prefs.setStringList('fcm_subscribed_topics', newTopics);
      } catch (e) {
        print('[FCM] Error updating topic subscriptions: $e');
      }
    });
  }

  /// Unsubscribe from all currently subscribed topics
  Future<void> unsubscribeFromAllTopics() async {
    await _queueOperation(() async {
      if (Platform.isIOS) {
        final hasApns = await _waitForApnsTokenIfNeeded();
        if (!hasApns) {
          print('[FCM] Aborting unsubscribeFromAllTopics: APNs token is not set on iOS.');
          return;
        }
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final List<String> subscribedTopics = prefs.getStringList('fcm_subscribed_topics') ?? [];
        for (final topic in subscribedTopics) {
          try {
            await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
            print('[FCM] Successfully unsubscribed from topic: $topic');
          } catch (e) {
            print('[FCM] Error unsubscribing from topic $topic: $e');
          }
        }
        await prefs.remove('fcm_subscribed_topics');
      } catch (e) {
        print('[FCM] Error unsubscribing from all topics: $e');
      }
    });
  }

  /// Subscribe to company topic (remapped to sync all topics)
  Future<void> subscribeToCompanyTopic() async {
    await updateTopicSubscriptions();
  }

  /// Unsubscribe from the current company topic (remapped to unsubscribe from all)
  Future<void> unsubscribeFromCompanyTopic() async {
    await unsubscribeFromAllTopics();
  }

  /// Delete/Deactivate token on logout
  Future<void> handleLogout() async {
    try {
      await unsubscribeFromAllTopics();
      // Clear token on server first
      if (curentUser != null && curentUser['Id'] != null) {
        final empId = curentUser['Id'];
        print('[FCM] Clearing token on server for EmpId $empId...');
        await AttendanceApis().notificationTokens('', empId);
      }
      // Delete local token reference from FCM
      await FirebaseMessaging.instance.deleteToken();
      await _clearLocalToken();
      print('[FCM] Token deleted successfully.');
    } catch (e) {
      print('[FCM] Error during logout token deletion: $e');
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
