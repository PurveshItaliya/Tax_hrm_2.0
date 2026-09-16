// ignore_for_file: avoid_print, empty_catches
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/services/location_batch_service.dart';
import 'package:tax_hrm/services/offline_punch_sync_service.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:workmanager/workmanager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ⚙️ TESTING FLAG
// true  = fires every 1 minute using chained one-off tasks (works when app closed)
// false = fires every 15 minutes using periodic task (production)
// ─────────────────────────────────────────────────────────────────────────────
const bool kTestMode = false; // ← CHANGE TO false BEFORE RELEASE

const String kApiBaseUrl             = 'https://taxcrmtesting.taxfile.co.in/';
const String kLocationTaskName       = 'LocationTimeLines';
const String kLocationTaskUniqueName = 'hrmLocationTaskUnique';
const String kLocationTestTaskName   = 'hrmLocationTestTask';
const String kPrefTestMode           = 'wm_test_mode';
const String kNotifChannelId         = 'location_tracking_channel';
const String kNotifChannelName       = 'Location Tracking';
const double kMovementThresholdMeters = 5.0;
const String kPrefLocationNotifShown = 'location_tracking_notif_shown';
const int    kLocationTrackingNotifId = 887;

// ── Dedicated offline punch sync task ─────────────────────────────────────────
// Completely independent of location tracking.
// Registered every time an offline punch is saved; fires when network returns.
const String kOfflineSyncTaskName       = 'OfflinePunchSync';
const String kOfflineSyncTaskUniqueName = 'hrmOfflineSyncTaskUnique';

// ─────────────────────────────────────────────────────────────────────────────
// WorkManager callbackDispatcher
// Runs in a FRESH isolate even after force-kill.
//
// TEST MODE (kTestMode = true):
//   • Shows a "BG Task Fired" notification immediately when it runs.
//   • After running, re-schedules ITSELF as a one-off task 1 minute later.
//   • This is the ONLY reliable way to get sub-15-min tasks — WorkManager's
//     minimum periodic frequency is 15 min on Android.
//
// PRODUCTION (kTestMode = false):
//   • No self-rescheduling. Uses 15-min periodic task from registerLocationWorkManager().
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {

    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();

      // ── Route by task name ────────────────────────────────────────────────
      if (task == kOfflineSyncTaskName) {
        // ── DEDICATED OFFLINE PUNCH SYNC TASK ────────────────────────────
        // Runs independently of location tracking — works for ALL users
        // regardless of IsFetchLocation flag or punch status.
        // NOTE: Does NOT chain a location task — completely independent.
        try {
          final bgPrefs = await SharedPreferences.getInstance();
          final String userStr = bgPrefs.getString('data') ?? '';
          if (userStr.isNotEmpty) {
            final Map<String, dynamic> userData =
                jsonDecode(userStr) as Map<String, dynamic>;
            await OfflinePunchSyncService.syncInBackground(userData: userData);
          }
        } catch (_) {}
        return true; // ← Early return: NO chained location task for sync tasks
      }

      // ── LOCATION TRACKING TASK (existing flow) ────────────────────────
      final notifPlugin = FlutterLocalNotificationsPlugin();
      await notifPlugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      // Immediately show "task started" notification for testing
      if (kTestMode) {
        await notifPlugin.show(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: '🔄 BG Service Running',
          body: 'Time: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              kNotifChannelId, kNotifChannelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }

      await _onBackground(notifPlugin);

      // ── Chained 1-minute re-schedule ─────────────────────────────────────
      // Only for location task — runs INSIDE the try block after _onBackground.
      // Fires 1 minute after this task completes, keeping tracking alive when
      // the app is force-killed. The uploadPendingBatch TTL guard (10 min) inside
      // _onBackground ensures the actual API is NOT called on every chain fire.
      try {
        await Workmanager().registerOneOffTask(
          'hrmChained_${DateTime.now().millisecondsSinceEpoch}',
          kLocationTaskName,
          initialDelay: const Duration(minutes: 1),
          constraints: Constraints(networkType: NetworkType.connected),
        );
      } catch (e) { /* ignored */ }

    } catch (e) { /* ignored */ }

    return true;
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Core background logic — location fetch + API submit
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _onBackground(FlutterLocalNotificationsPlugin notifPlugin) async {
  Future<void> showDebug(String title, String body) async {
    if (kTestMode) {
      try {
        await notifPlugin.show(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              kNotifChannelId, kNotifChannelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      } catch (_) { /* ignored */ }
    }
  }

  await showDebug('📍 WorkManager Triggered', 'Checking user data...');

  final String userDataStr = await SaveUser().getUserDatas();
  if (userDataStr.isEmpty) {
    await showDebug('❌ BG Failed', 'No user data found in SharedPreferences');
    return;
  }

  final dynamic userData = jsonDecode(userDataStr);
  if (userData['Role'] == 'Admin') {
    // Admin does not need location tracking
    return;
  }
  
  // ── Step 0: Always attempt to upload any pending batch locally ─────────────
  await LocationBatchStorage.uploadPendingBatch(userData: userData);

  final String token     = userData['token'] ?? '';
  final dynamic empId    = userData['Id'];
  final dynamic companyId = userData['CompanyId'];

  if (token.isEmpty) {
    await showDebug('❌ BG Failed', 'No auth token');
    return;
  }

  final bool isFetchLocation = userData['IsFetchLocation'] == null ||
      userData['IsFetchLocation'] == true ||
      userData['IsFetchLocation']?.toString().toLowerCase() == 'true';

  if (!isFetchLocation) {
    await showDebug('⏭ BG Skipped', 'IsFetchLocation=false for this user');
    return;
  }

  final DateTime today    = DateTime.now();
  final DateTime dateOnly = DateTime(today.year, today.month, today.day);

  // ── Step 1: Check attendance (only track if punched IN) ──────────────────
  try {
    final String dateStr = dateOnly.toIso8601String();
    final attendanceUrl = Uri.parse(
      '${kApiBaseUrl}api/HRM/GetAttendenceListById?CompanyID=$companyId&EmpId=$empId&AttendenceDate=$dateStr',
    );
    final attendanceResponse = await http.get(
      attendanceUrl,
      headers: {'Authorization': 'bearer $token'},
    ).timeout(const Duration(seconds: 15));

    if (attendanceResponse.statusCode != 200) {
      await showDebug('❌ BG Failed', 'Attendance API: ${attendanceResponse.statusCode}');
      return;
    }

    final dynamic attendanceData = jsonDecode(attendanceResponse.body);
    final List? logs = attendanceData?['AttendenceLog'];

    if (logs == null || logs.isEmpty) {
      await showDebug('❌ BG Failed', 'No attendance logs today (not punched in)');
      return;
    }

    final String lastStatus = logs.last['Status']?.toString() ?? '';
    if (lastStatus != 'IN') {
      await showDebug('❌ BG Failed', 'Last punch = $lastStatus (not IN)');
      return;
    }
  } catch (e) {
    await showDebug('❌ BG Failed', 'Attendance check error: $e');
    return;
  }

  await showDebug('✅ Punched IN', 'Getting GPS position...');

  // ── Step 2: Get GPS position ──────────────────────────────────────────────
  Position? position;
  try {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showDebug('❌ BG Failed', 'GPS disabled on device');
      return;
    }
    final LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      await showDebug('❌ BG Failed', 'Location permission: $perm');
      return;
    }
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true, // Forces fresh live hardware GPS reading
          timeLimit: const Duration(seconds: 12),
        ),
      );
    } catch (_) {
      position = await Geolocator.getLastKnownPosition();
      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (_) {
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.lowest,
              timeLimit: const Duration(seconds: 5),
            );
          } catch (_) {
            // Fallback (simulator / dead zone)
            position = Position(
              latitude: 21.209324791829328,
              longitude: 72.83361489980567,
              timestamp: DateTime.now(),
              accuracy: 50.0,
              altitude: 0.0,
              altitudeAccuracy: 0.0,
              heading: 0.0,
              headingAccuracy: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
            );
          }
        }
      }
    }
  } catch (e) {
    await showDebug('❌ BG Failed', 'GPS error: $e');
    return;
  }

  await showDebug('📡 Got GPS', 'Appending to local batch queue...');

  await LocationBatchStorage.appendLocation(
    latitude: position.latitude,
    longitude: position.longitude,
    entryTime: DateTime.now(),
    accuracy: position.accuracy,
  );

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  bool isMapScreen = prefs.getBool('MapActive') ?? false;
  bool isAppForeground = prefs.getBool('AppForeground') ?? false;

  await LocationBatchStorage.uploadPendingBatch(
    userData: userData, 
    isMapScreen: isMapScreen, 
    isAppForeground: isAppForeground
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Initialize WorkManager + FlutterBackgroundService
// Called once from main()
// ─────────────────────────────────────────────────────────────────────────────
Future<void> initializeBackgroundService() async {
  // 1. WorkManager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: kTestMode,
  );

  // 2. Notification channel
  final notifPlugin = FlutterLocalNotificationsPlugin();
  await notifPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await notifPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          kNotifChannelId,
          kNotifChannelName,
          description: 'Background location tracking for HRM attendance.',
          importance: Importance.high,
        ),
      );

  // 3. FlutterBackgroundService
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true, // MUST BE true to stay alive when app is closed
      notificationChannelId: kNotifChannelId,
      initialNotificationTitle: 'Location Tracking Active',
      initialNotificationContent: 'Tracking is active until you Punch Out.',
      foregroundServiceNotificationId: kLocationTrackingNotifId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Register WorkManager task — called after Punch In
//
// TEST MODE:  Registers a ONE-OFF task with 10s delay.
//             After it runs, it self-reschedules every 1 min (chaining above).
//
// PRODUCTION: Registers a PERIODIC task every 15 min.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> registerLocationWorkManager() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kPrefTestMode, kTestMode);

  // Cancel any stale task
  await Workmanager().cancelByUniqueName(kLocationTaskUniqueName);

  // Seed the first one-off — it will chain itself every 1 min
  await Workmanager().registerOneOffTask(
    kLocationTaskUniqueName,
    kLocationTaskName,
    initialDelay: const Duration(seconds: 10),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Register DEDICATED offline punch sync WorkManager task
//
// Called every time an offline punch is saved.
// Completely independent of location tracking — works for ALL users:
//   • Users with IsFetchLocation = false
//   • Admins
//   • Users who never punched in online (location tracking never started)
//
// Fires immediately when internet connectivity is restored.
// ExistingWorkPolicy.replace ensures only ONE sync task queued at a time.
// ─────────────────────────────────────────────────────────────────────────────
Future<void> registerOfflineSyncWorkManager() async {
  try {
    await Workmanager().registerOneOffTask(
      kOfflineSyncTaskUniqueName,
      kOfflineSyncTaskName,
      // Very short delay — OS will hold it until network is available
      initialDelay: const Duration(seconds: 5),
      constraints: Constraints(
        networkType: NetworkType.connected, // Wait for internet
        requiresBatteryNotLow: false,       // Sync even on low battery
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace, // Deduplicate
    );
  } catch (_) {
    // WorkManager not yet initialized — safe to ignore here;
    // the foreground connectivity-restored path (InternetConnectionProvider)
    // will handle it when the app is open.
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cancel WorkManager — called after Punch Out
// ─────────────────────────────────────────────────────────────────────────────
Future<void> cancelLocationWorkManager() async {
  await Workmanager().cancelByUniqueName(kLocationTaskUniqueName);
  await Workmanager().cancelByUniqueName(kLocationTestTaskName);
  // Also cancel any chained tasks (cancel all is safest for test mode)
  await Workmanager().cancelAll();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(kPrefTestMode);
}

// ─────────────────────────────────────────────────────────────────────────────
// FlutterBackgroundService — runs while app is open or minimised
// Provides 1-min timer when app is NOT force-killed
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Foreground Location Logger — captures GPS every 30 seconds while the
// flutter_background_service isolate is alive (app open or minimised).
//
// 30 seconds is the minimum meaningful interval: finer would drain battery
// without adding real movement resolution, since the 15-meter distance filter
// in appendLocation() already deduplicates stationary readings.
//
// The actual Timeline API upload is governed separately by the 10-minute TTL
// inside uploadPendingBatch — this loop only collects GPS points locally.
// ─────────────────────────────────────────────────────────────────────────────
bool _isFetchingLocation = false;

void startLocationLogger(FlutterLocalNotificationsPlugin notifPlugin) {
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (_isFetchingLocation) return;
    _isFetchingLocation = true;
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      final LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true,
          timeLimit: const Duration(seconds: 12),
        ),
      );

      await LocationBatchStorage.appendLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        entryTime: DateTime.now(),
        accuracy: position.accuracy,
      );
    } catch (_) {
      // ignore — GPS unavailable or permission revoked mid-session
    } finally {
      _isFetchingLocation = false;
    }
  });
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  /* log('========== BACKGROUND ISOLATE LOGS =========='); */
  /* log('1. onStart() called in isolate'); */
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    /* log('2. Registering Android service listeners'); */
    service.on('setAsForeground').listen((_) {
      /* log('--> setAsForeground listener triggered'); */
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      /* log('--> setAsBackground listener triggered'); */
      service.setAsBackgroundService();
    });
    
    // Force foreground mode so the persistent notification is shown
    /* log('3. Calling setAsForegroundService() to show notification'); */
    service.setAsForegroundService();
  }

  service.on('stopService').listen((_) {
    /* log('--> stopService listener triggered. Stopping self.'); */
    service.stopSelf();
  });

  final notifPlugin = FlutterLocalNotificationsPlugin();
  await notifPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  startLocationLogger(notifPlugin);

  // Run immediately on start
  await _onBackground(notifPlugin);

  // Dynamic timer to support map active = 5 mins, background = 10 mins
  int tick = 0;
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    tick++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    bool isMapScreen = prefs.getBool('MapActive') ?? false;
    
    int target = isMapScreen ? 5 : 10;
    
    if (tick >= target) {
      tick = 0;
      await _onBackground(notifPlugin);
    }
  });
}
