// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// ANALYTICS SERVICE — Ultra Simple & Clean Architecture
//
// No deep subcollections. Everything about the device and its users is in 
// ONE document. Events are grouped by day in a single subcollection.
//
// Firestore structure:
//
//   analytics_devices / {deviceId}
//     ├── device: { model, os, appVersion ... }
//     ├── accountsUsed: [ "CompanyA", "CompanyB" ]  ← ALL accounts ever opened here
//     ├── currentUserId: "User123"
//     ├── currentAccountId: "CompanyA"
//     └── users: {
//           "User123": {
//               "name": "John",
//               "role": "Admin",
//               "screens": {
//                   "Dashboard": { "c": 5, "t": 15000 }  // count and time
//               }
//           },
//           "User456": { ... }
//         }
//     
//     // Subcollection for daily logs
//     └── events / {YYYY-MM-DD}
//           └── logs: [ { e: "login", uid: "User123", acc: "CompanyB", t: ... } ]
//
// =============================================================================
class AnalyticsService extends GetxService with WidgetsBindingObserver {
  static AnalyticsService get to => Get.find<AnalyticsService>();

  bool isAnalyticsEnabled = true;

  // ── State ──────────────────────────────────────────────────────────────────
  String? _deviceId;
  String? _userId;
  String? _accountId; // tracks current company/account
  String? _currentSessionId;
  String? _currentScreen;
  DateTime? _screenOpenedAt;
  String? _lastLifecycleState;

  Map<String, dynamic> _deviceInfo = {};

  // ── Queues ─────────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _writeQueue = [];
  final List<Map<String, dynamic>> _eventQueue = [];
  Timer? _batchTimer;
  final int _batchSize = 5;
  final Duration _flushInterval = const Duration(seconds: 10);

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  DocumentReference? get _deviceDoc => _deviceId != null ? _db.collection('analytics_devices').doc(_deviceId) : null;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initDevice();
    _startBatchTimer();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _batchTimer?.cancel();
    _flushQueue();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isAnalyticsEnabled) return;
    final s = state.toString();
    if (_lastLifecycleState == s) return;
    _lastLifecycleState = s;

    if (state == AppLifecycleState.resumed) {
      logEvent('app_foreground');
      if (_currentScreen != null && _screenOpenedAt == null) _screenOpenedAt = DateTime.now();
    } else if (state == AppLifecycleState.paused) {
      logEvent('app_background');
      _finaliseCurrentScreen();
      _flushQueue();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 1. DEVICE INITIALISATION
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _initDevice() async {
    try {
      final devicePlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      String deviceId = 'unknown';
      String model = 'unknown';
      String osVersion = 'unknown';

      if (Platform.isAndroid) {
        final info = await devicePlugin.androidInfo;
        deviceId = info.id.isNotEmpty ? info.id : 'android_unknown';
        model = '${info.brand} ${info.model}'.trim();
        osVersion = 'Android ${info.version.release}';
      } else if (Platform.isIOS) {
        final info = await devicePlugin.iosInfo;
        deviceId = info.identifierForVendor ?? 'ios_unknown';
        model = info.model;
        osVersion = 'iOS ${info.systemVersion}';
      }

      _deviceId = deviceId;
      _deviceInfo = {
        'id': deviceId,
        'model': model,
        'os': osVersion,
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };

      _queueWrite(_deviceDoc!, {'device': _deviceInfo}, isSet: true);
      logEvent('app_opened');
    } catch (e) {
      debugPrint('[Analytics] ❌ _initDevice error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 2. USER IDENTIFICATION (Called when account/user changes)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> setUserId(
    String userId, {
    String? userName,
    String? fullName,
    String? role,
    String? companyId,
    String? companyName,
    String? email,
    String? phone,
  }) async {
    if (!isAnalyticsEnabled || userId.trim().isEmpty || _deviceDoc == null) return;
    
    _userId = userId.trim();
    if (companyId != null && companyId.isNotEmpty) {
      _accountId = companyId;
    }

    try {
      // 1. Track current state & known accounts at device level
      final deviceUpdate = <String, dynamic>{
        'currentUserId': _userId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (_accountId != null) {
        deviceUpdate['currentAccountId'] = _accountId;
        deviceUpdate['accountsUsed'] = FieldValue.arrayUnion([_accountId]);
      }

      // 2. Build the user's map entry
      final userMap = <String, dynamic>{
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
        if (userName != null) 'userName': userName,
        if (fullName != null) 'fullName': fullName,
        if (role != null) 'role': role,
        if (companyId != null) 'companyId': companyId,
        if (companyName != null) 'companyName': companyName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };

      deviceUpdate['users.$_userId.profile'] = userMap;

      _queueWrite(_deviceDoc!, deviceUpdate, isUpdate: true, isSet: true);
      debugPrint('[Analytics] 👤 User identified: $_userId | Account: $_accountId');
    } catch (e) {
      debugPrint('[Analytics] Error in setUserId: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 3. LOGIN / LOGOUT
  // ══════════════════════════════════════════════════════════════════════════
  void logLogin({required String accountId, String? method, String? role}) {
    if (!isAnalyticsEnabled || _deviceDoc == null) return;

    _accountId = accountId;
    _currentSessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';

    _queueWrite(_deviceDoc!, {
      'accountsUsed': FieldValue.arrayUnion([accountId]),
      'currentAccountId': accountId,
    }, isSet: true);

    logEvent('login', metadata: {'method': method, 'role': role});
  }

  void logLogout() {
    if (!isAnalyticsEnabled || _deviceDoc == null) return;

    _finaliseCurrentScreen();
    logEvent('logout');

    _queueWrite(_deviceDoc!, {
      'currentUserId': null,
      'currentAccountId': null,
    }, isSet: true);

    _userId = null;
    _accountId = null;
    _currentSessionId = null;
    _flushQueue();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 4. SCREEN TRACKING
  // ══════════════════════════════════════════════════════════════════════════
  void logScreen(String screenName) {
    if (!isAnalyticsEnabled) return;
    _finaliseCurrentScreen();
    _currentScreen = screenName;
    _screenOpenedAt = DateTime.now();
    logEvent('screen_open', metadata: {'s': screenName});
  }

  void _finaliseCurrentScreen() {
    if (_currentScreen == null || _screenOpenedAt == null) return;
    final durationMs = DateTime.now().difference(_screenOpenedAt!).inMilliseconds;
    final screen = _currentScreen!;
    _screenOpenedAt = null;

    if (durationMs < 1000) return;

    logEvent('screen_close', metadata: {'s': screen, 'dur': durationMs});

    if (_deviceDoc != null && _userId != null) {
      final safeScreen = screen.replaceAll(RegExp(r'[./\[\]]'), '_');
      // Store neatly inside the user's map in the device doc
      _queueWrite(_deviceDoc!, {
        'users.$_userId.screens.$safeScreen.c': FieldValue.increment(1),
        'users.$_userId.screens.$safeScreen.t': FieldValue.increment(durationMs),
      }, isSet: true);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 5. EVENT LOGGER
  // ══════════════════════════════════════════════════════════════════════════
  void logEvent(String eventName, {Map<String, dynamic>? metadata}) {
    if (!isAnalyticsEnabled) return;

    final event = <String, dynamic>{
      'e': eventName,
      't': DateTime.now().millisecondsSinceEpoch,
    };
    if (_userId != null) event['uid'] = _userId;
    if (_accountId != null) event['acc'] = _accountId;
    if (_currentSessionId != null) event['sid'] = _currentSessionId;
    if (metadata != null && metadata.isNotEmpty) event['m'] = metadata;

    _eventQueue.add(event);
    if (_eventQueue.length >= _batchSize) _flushQueue();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 6. BATCH WRITER
  // ══════════════════════════════════════════════════════════════════════════
  void _queueWrite(DocumentReference ref, Map<String, dynamic> data, {bool isSet = false, bool isUpdate = false}) {
    _writeQueue.add({'ref': ref, 'data': data, 'isSet': isSet, 'isUpdate': isUpdate});
    if (_writeQueue.length >= _batchSize) _flushQueue();
  }

  void _startBatchTimer() => _batchTimer = Timer.periodic(_flushInterval, (_) => _flushQueue());

  Future<void> _flushQueue() async {
    if (_writeQueue.isEmpty && _eventQueue.isEmpty) return;

    final writes = _writeQueue.take(300).toList();
    _writeQueue.removeRange(0, writes.length);

    final events = _eventQueue.take(150).toList();
    _eventQueue.removeRange(0, events.length);

    try {
      final batch = _db.batch();

      for (final op in writes) {
        final ref = op['ref'] as DocumentReference;
        final data = op['data'] as Map<String, dynamic>;
        if (op['isSet'] == true) batch.set(ref, data, SetOptions(merge: true));
        else if (op['isUpdate'] == true) batch.update(ref, data);
      }

      if (events.isNotEmpty && _deviceDoc != null) {
        final dateStr = DateTime.now().toIso8601String().substring(0, 10);
        batch.set(_deviceDoc!.collection('events').doc(dateStr), 
          {'logs': FieldValue.arrayUnion(events)}, 
          SetOptions(merge: true)
        );
      }

      await batch.commit();
      debugPrint('[Analytics] ✅ Flushed ${writes.length} writes, ${events.length} events.');
    } catch (e) {
      debugPrint('[Analytics] ❌ Flush failed: $e');
    }
  }
}

class AnalyticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> r, Route<dynamic>? pr) { super.didPush(r, pr); _log(r); }
  @override
  void didPop(Route<dynamic> r, Route<dynamic>? pr) { super.didPop(r, pr); if (pr != null) _log(pr); }
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _log(newRoute);
  }

  void _log(Route<dynamic> route) {
    if (route is! PageRoute) return;
    String name = route.settings.name ?? '';
    name = name.replaceAll(RegExp(r'[./\[\]]'), '_');
    if (name.startsWith('_')) name = name.substring(1);
    if (name.isNotEmpty) AnalyticsService.to.logScreen(name);
  }
}
