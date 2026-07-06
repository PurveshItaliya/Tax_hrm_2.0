// ignore_for_file: avoid_print, empty_catches
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
const double kMovementThresholdMeters = 50.0;
const String kPrefLocationNotifShown = 'location_tracking_notif_shown';
const int    kLocationTrackingNotifId = 887;

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

    } catch (e) { /* ignored */ }

    // ── Chained 1-minute re-schedule (test mode only) ─────────────────────
    // WorkManager periodic minimum = 15 min. To test every 1 min when the
    // app is fully closed, each task re-schedules the next one-off task.
    if (kTestMode) {
      try {
        await Workmanager().registerOneOffTask(
          'hrmChained_${DateTime.now().millisecondsSinceEpoch}',
          kLocationTestTaskName,
          initialDelay: const Duration(minutes: 1),
          constraints: Constraints(networkType: NetworkType.connected),
        );
      } catch (e) { /* ignored */ }
    }

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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
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

  await showDebug('📡 Got GPS', 'Checking distance from last timeline...');

  // ── Step 3: Distance check (skip if < 50m, unless test mode) ─────────────
  try {
    final String formattedDate   = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String companyDataStr  = await SaveUser().getselectedcompany();
    dynamic companyData;
    if (companyDataStr.isNotEmpty) {
      companyData = jsonDecode(companyDataStr);
    }
    final dynamic companyIdForTimeline = companyData?['CompanyId'] ?? companyId;

    final timelineUrl = Uri.parse(
      '${kApiBaseUrl}api/Transation/GetTimelineList?CompanyID=$companyIdForTimeline&EmpId=$empId&Date=$formattedDate',
    );
    final timelineResponse = await http.get(
      timelineUrl,
      headers: {'Authorization': 'bearer $token'},
    ).timeout(const Duration(seconds: 15));

    bool shouldSubmit = true;

    if (timelineResponse.statusCode == 200) {
      final dynamic timelineData = jsonDecode(timelineResponse.body);
      List timelineList = [];
      if (timelineData is List) {
        timelineList = timelineData;
      } else if (timelineData is Map && timelineData['data'] is List) {
        timelineList = timelineData['data'];
      }

      if (timelineList.isNotEmpty) {
        final dynamic lastEntry = timelineList.last;
        final double? prevLat = double.tryParse(lastEntry['Latitude']?.toString() ?? '');
        final double? prevLng = double.tryParse(lastEntry['Logitude']?.toString() ?? '');

        if (prevLat != null && prevLng != null) {
          final double distance = Geolocator.distanceBetween(
            prevLat, prevLng,
            position.latitude, position.longitude,
          );
          shouldSubmit = kTestMode || distance > kMovementThresholdMeters;
          if (!shouldSubmit) {
            await showDebug('⏭ BG Skipped', 'Moved only ${distance.toStringAsFixed(1)}m (need ${kMovementThresholdMeters}m)');
          } else if (kTestMode) {
            await showDebug('🚀 BG Submitting', 'Test mode — submitting always.');
          }
        }
      }
    }
    if (!shouldSubmit && !kTestMode) return;
  } catch (e) {
    await showDebug('⚠️ Timeline Warning', 'Timeline check failed: $e — submitting anyway');
  }

  // ── Step 4: Submit to API ─────────────────────────────────────────────────
  await _callApiFunction(
    position: position,
    userData: userData,
    notifPlugin: notifPlugin,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HTTP POST to CreateTimeline API
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _callApiFunction({
  required Position position,
  required dynamic userData,
  required FlutterLocalNotificationsPlugin notifPlugin,
}) async {
  String address    = '';
  String postalCode = '';

  try {
    final List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude, position.longitude,
    );
    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      postalCode = place.postalCode ?? '';
      address    = '${place.subThoroughfare ?? ''} ${place.thoroughfare ?? ''}, '
          '${place.subLocality ?? ''}, ${place.locality ?? ''}, '
          '${place.subAdministrativeArea ?? ''}, '
          '${place.administrativeArea ?? ''} ${place.postalCode ?? ''}, '
          '${place.country ?? ''}';
    }
  } catch (e) { /* ignored */ }

  try {
    final Map<String, dynamic> body = {
      'EmpId':      userData['Id'],
      'CompanyId':  userData['CompanyId'],
      'Latitude':   position.latitude.toString(),
      'Logitude':   position.longitude.toString(),
      'Pincode':    postalCode,
      'DeviceType': Platform.isAndroid ? 'Android' : 'iOS',
      'DeviceName': 'Background',
      'Address':    address,
    };

    final String token = userData['token'] ?? '';
    await http.post(
      Uri.parse('${kApiBaseUrl}api/Transation/CreateTimeline'),
      body: jsonEncode(body),
      headers: {
        'Content-Type': 'application/json',
        'Accept':        '*/*',
        'Authorization': 'bearer $token',
      },
    ).timeout(const Duration(seconds: 15));


    if (kTestMode) {
      await notifPlugin.show(
        id: 890,
        title: '✅ Location Sent!',
        body: '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}'
            ' | ${DateFormat('HH:mm:ss').format(DateTime.now())}',
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
  } catch (e) { /* ignored */ }
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
      isForegroundMode: false, // Wait until startLocationTracking to upgrade to foreground
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

  if (kTestMode) {
    // Cancel any stale periodic task
    await Workmanager().cancelByUniqueName(kLocationTaskUniqueName);

    // Seed the first one-off — it will chain itself every 1 min
    await Workmanager().registerOneOffTask(
      kLocationTestTaskName,     // unique name (stable so duplicates are skipped)
      kLocationTestTaskName,
      initialDelay: const Duration(seconds: 10),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } else {
    // Production: 15-min periodic task
    await Workmanager().registerPeriodicTask(
      kLocationTaskUniqueName,
      kLocationTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
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

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print('========== BACKGROUND ISOLATE LOGS ==========');
  print('1. onStart() called in isolate');
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    print('2. Registering Android service listeners');
    service.on('setAsForeground').listen((_) {
      print('--> setAsForeground listener triggered');
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      print('--> setAsBackground listener triggered');
      service.setAsBackgroundService();
    });
    
    // Force foreground mode so the persistent notification is shown
    print('3. Calling setAsForegroundService() to show notification');
    service.setAsForegroundService();
  }

  service.on('stopService').listen((_) {
    print('--> stopService listener triggered. Stopping self.');
    service.stopSelf();
  });

  final notifPlugin = FlutterLocalNotificationsPlugin();
  await notifPlugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );


  // Run immediately on start
  await _onBackground(notifPlugin);

  // Then repeat every 1 min (test) or 5 min (production)
  final timerDuration = kTestMode
      ? const Duration(minutes: 1)
      : const Duration(minutes: 5);

  Timer.periodic(timerDuration, (timer) async {
    await _onBackground(notifPlugin);
  });
}
