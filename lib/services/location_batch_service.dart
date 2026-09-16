import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class LocationBatchStorage {
  static const String _kPendingLocationsKey = 'pending_locations_batch';
  static const String _kUploadLockKey = 'batch_upload_lock';
  static const String _kLastApiTimeKey = 'last_api_call_time';
  static const String _kApiBaseUrl = 'https://taxcrmtesting.taxfile.co.in/';

  /// Appends a newly captured location to the pending list locally
  static Future<void> appendLocation({
    required double latitude,
    required double longitude,
    required DateTime entryTime,
    double? accuracy,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Isolate sync

      // Calculate API Timing Logs
      final lastApiTimeStr = prefs.getString(_kLastApiTimeKey);
      String lastApiTimeFormatted = 'N/A';
      String nextApiTimeFormatted = 'N/A';

      if (lastApiTimeStr != null) {
        DateTime? lastApiTime = DateTime.tryParse(lastApiTimeStr);
        if (lastApiTime != null) {
          lastApiTimeFormatted = DateFormat('HH:mm:ss').format(lastApiTime);
          bool isMapScreen = prefs.getBool('MapActive') ?? false;
          int targetMinutes = isMapScreen ? 5 : 10;
          DateTime nextApiTime = lastApiTime.add(
            Duration(minutes: targetMinutes),
          );

          final now = DateTime.now();
          final diff = nextApiTime.difference(now);
          final minutes = diff.inMinutes;
          final seconds = diff.inSeconds % 60;
          final remainingStr = diff.isNegative
              ? 'Overdue by ${-minutes}m ${-seconds}s'
              : '${minutes}m ${seconds}s';

          nextApiTimeFormatted =
              '${DateFormat('HH:mm:ss').format(nextApiTime)} (in $remainingStr)';
        }
      }

      print(
        '[LOCATION_RECEIVED] lat=$latitude lng=$longitude accuracy=${accuracy?.toStringAsFixed(1) ?? 'N/A'}m',
      );
      print(
        '   -> \x1B[36m[API TIMING] Last=$lastApiTimeFormatted | Next=$nextApiTimeFormatted\x1B[0m',
      );

      // 1. Validate Accuracy
      if (accuracy != null && accuracy > 100) {
        print(
          '[LOCATION_REJECTED_ACCURACY] lat=$latitude lng=$longitude accuracy=${accuracy.toStringAsFixed(1)}m (Poor GPS)',
        );
        return;
      }

      // 2. Movement Validation
      final lastLat = prefs.getDouble('lastAcceptedLat');
      final lastLng = prefs.getDouble('lastAcceptedLng');
      double distance = 0.0;

      final String timeStr = DateFormat('HH:mm:ss').format(DateTime.now());

      if (lastLat != null && lastLng != null) {
        distance = Geolocator.distanceBetween(
          lastLat,
          lastLng,
          latitude,
          longitude,
        );
        // Default threshold 15 meters
        if (distance < 15.0) {
          print(
            '\x1B[32m[$timeStr] 📍 SAME_DIST (${distance.toStringAsFixed(1)}m) | Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}\x1B[0m',
          );
          return;
        } else {
          print(
            '\x1B[33m[$timeStr] 📍 MOVED_FAR (${distance.toStringAsFixed(1)}m) | Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)} >= 15m\x1B[0m',
          );
          print('\x1B[35m[$timeStr] 🚀 Queuing Location Locally...\x1B[0m');
        }
      } else {
        print(
          '\x1B[36m[$timeStr] 📍 INITIAL_LOCATION_SUBMIT | Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}\x1B[0m',
        );
        print('\x1B[35m[$timeStr] 🚀 Queuing Initial Location Fix...\x1B[0m');
      }

      List<Map<String, dynamic>> pending = await getPendingLocations();

      final newItem = {
        'id': DateTime.now().millisecondsSinceEpoch
            .toString(), // unique id to safely remove later
        'Latitude': latitude.toString(),
        'Logitude': longitude
            .toString(), // Matching backend spelling "Logitude"
        'EntryTime': _toIso8601WithOffset(
          entryTime,
        ), // e.g. 2026-09-09T15:00:53+05:30
      };

      pending.add(newItem);
      await prefs.setString(_kPendingLocationsKey, jsonEncode(pending));
      await prefs.setDouble('lastAcceptedLat', latitude);
      await prefs.setDouble('lastAcceptedLng', longitude);

      print(
        '\x1B[34m[LOCATION_ADDED_LOCAL] lat=$latitude lng=$longitude distance=${distance.toStringAsFixed(1)}m entryTime=${newItem['EntryTime']} pendingCount=${pending.length}\x1B[0m',
      );
    } catch (e, stacktrace) {
      print(
        '[LOCATION_BATCH_STORAGE] ERROR appending location: $e\n$stacktrace',
      );
    }
  }

  /// Formats a DateTime to ISO 8601 with local timezone offset, e.g. 2026-09-09T15:00:53+05:30
  /// This is safer than intl's XXX formatter which can output literal 'XXX' on some devices.
  static String _toIso8601WithOffset(DateTime dt) {
    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hh = offset.inHours.abs().toString().padLeft(2, '0');
    final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final yyyy = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$yyyy-$mo-${dd}T$h:$mi:$ss$sign$hh:$mm';
  }

  /// Retrieves the list of pending locations
  static Future<List<Map<String, dynamic>>> getPendingLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Isolate sync
      final str = prefs.getString(_kPendingLocationsKey);
      if (str != null && str.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(str);
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      print(
        '\x1B[31m[LocationBatchStorage] ERROR getting locations: $e\x1B[0m',
      );
    }
    return [];
  }

  static Future<int> getPendingCount() async {
    final list = await getPendingLocations();
    return list.length;
  }

  /// Removes specifically provided uploaded locations by their unique 'id'
  static Future<void> removeUploadedLocations(List<String> uploadedIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Isolate sync
      List<Map<String, dynamic>> pending = await getPendingLocations();

      pending.removeWhere((item) => uploadedIds.contains(item['id']));

      await prefs.setString(_kPendingLocationsKey, jsonEncode(pending));
    } catch (e) {
      print(
        '\x1B[31m[LocationBatchStorage] ERROR removing locations: $e\x1B[0m',
      );
    }
  }

  /// Uploads all pending locations in a single batch
  static Future<void> uploadPendingBatch({
    required dynamic userData,
    bool isMapScreen = false,
    bool isAppForeground = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Isolate sync

    // 1. Sync Lock / Mutex Check
    final isUploading = prefs.getBool(_kUploadLockKey) ?? false;
    if (isUploading) {
      // Log prevents simultaneous requests
      return;
    }

    final now = DateTime.now();
    final lastApiTimeStr = prefs.getString(_kLastApiTimeKey);

    if (lastApiTimeStr != null) {
      DateTime? lastApiTime = DateTime.tryParse(lastApiTimeStr);
      if (lastApiTime != null) {
        int targetMinutes = isMapScreen ? 5 : 10;
        if (now.difference(lastApiTime).inMinutes < targetMinutes) {
          // Not enough time has passed, skip upload
          return;
        }
      }
    }

    // Set the last api call time to now
    await prefs.setString(_kLastApiTimeKey, now.toIso8601String());

    List<Map<String, dynamic>> pending = await getPendingLocations();
    if (pending.isEmpty) {
      // Rule 13: Never call the Timeline API if the pending list is empty
      return;
    }

    print('[PENDING_LOCATION_COUNT] count=${pending.length}');

    if (isMapScreen) {
      print('[MAP_SCREEN_ACTIVE] mapActive=true triggering 5min sync logic');
    } else if (isAppForeground) {
      print('[APP_STATE_FOREGROUND] triggering 10min sync logic');
    } else {
      print('[APP_STATE_BACKGROUND] triggering 10min sync logic');
    }

    try {
      // Acquire lock
      await prefs.setBool(_kUploadLockKey, true);

      // Rule 15: Maintain location order by EntryTime from oldest to newest
      pending.sort(
        (a, b) =>
            (a['EntryTime'] as String).compareTo(b['EntryTime'] as String),
      );

      String oldestTime = pending.first['EntryTime'].toString().split('T')[1];
      String newestTime = pending.last['EntryTime'].toString().split('T')[1];
      String stateStr = isMapScreen
          ? 'MAP'
          : (isAppForeground ? 'FOREGROUND' : 'BACKGROUND');

      print(
        '[TIMELINE_BATCH_PREPARED] count=${pending.length} oldest=$oldestTime newest=$newestTime state=$stateStr',
      );

      // Strip 'id' from the list sent to API
      List<Map<String, dynamic>> apiLocations = pending.map((e) {
        return {
          'Latitude': e['Latitude'],
          'Logitude': e['Logitude'],
          'EntryTime': e['EntryTime'],
        };
      }).toList();

      final String deviceName = Platform.isAndroid ? 'Android' : 'iOS';

      final Map<String, dynamic> body = {
        'EmpId': userData['Id'],
        'CompanyId': userData['CompanyId'],
        'DeviceType': deviceName,
        'DeviceName': '', // must be empty to match server contract
        'Locations': apiLocations,
      };

      final encoder = JsonEncoder.withIndent('  ');
      String prettyBody = encoder.convert(body);
      String userName = userData['FirstName'] ?? 'User';

      print(
        '\n\x1B[35m========================================================================\x1B[0m',
      );
      print(
        '\x1B[35m[TIMELINE_API_STARTED] 🚀 Syncing Timeline for: $userName (EmpID: ${userData['Id']})\x1B[0m',
      );
      print(
        '\x1B[35mURL: ${_kApiBaseUrl}api/Transation/NewCreateTimeline\x1B[0m',
      );
      print('\x1B[36m[TIMELINE_API_REQUEST_PAYLOAD]\n$prettyBody\x1B[0m');

      final String token = userData['token'] ?? '';
      final stopwatch = Stopwatch()..start();

      final response = await http
          .post(
            Uri.parse('${_kApiBaseUrl}api/Transation/NewCreateTimeline'),
            body: jsonEncode(body),
            headers: {
              'Content-Type': 'application/json',
              'Accept': '*/*',
              'Authorization': 'bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode == 200) {
        String prettyResponse = response.body;
        try {
          prettyResponse = encoder.convert(jsonDecode(response.body));
        } catch (_) {}

        print(
          '\x1B[32m[TIMELINE_API_SUCCESS] 200 OK | Time: ${stopwatch.elapsedMilliseconds}ms | Uploaded ${pending.length} locations.\x1B[0m',
        );
        print('\x1B[36m[TIMELINE_API_RESPONSE]\n$prettyResponse\x1B[0m');
        print(
          '\x1B[35m========================================================================\n\x1B[0m',
        );

        // Remove the exactly uploaded items by their IDs, avoiding removal of newly added points during upload
        List<String> uploadedIds = pending
            .map((e) => e['id'].toString())
            .toList();
        await removeUploadedLocations(uploadedIds);
        print('[UPLOADED_RECORDS_REMOVED] count=${uploadedIds.length}');
      } else {
        print('[TIMELINE_API_FAILED] Status Code: ${response.statusCode}');
        print(
          '[PENDING_DATA_RETAINED] Data kept locally for retry due to API failure.',
        );
      }
    } on SocketException catch (_) {
      print('[NO_INTERNET] Cannot reach API.');
      print('[PENDING_DATA_RETAINED] Data kept locally for retry when online.');
    } catch (e, stacktrace) {
      print('[TIMELINE_API_FAILED] Exception: $e');
      print('[PENDING_DATA_RETAINED] Data kept locally for retry.');
    } finally {
      // Release lock
      await prefs.setBool(_kUploadLockKey, false);
    }
  }
}
