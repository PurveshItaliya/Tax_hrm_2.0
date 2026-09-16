// ignore_for_file: strict_top_level_inference, override_on_non_overriding_member,
// unnecessary_cast, avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/services/location_batch_service.dart';
import 'package:tax_hrm/services/offline_punch_sync_service.dart';

class InternetConnectionProvider with ChangeNotifier {
  var connectionType = 1;
  final Connectivity connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _streamSubscription;

  /// True when [connectionType] == 0 (no network).
  bool get isOffline => connectionType == 0;

  Future<void> getAllConnectionData() async {
    await getConnectivityType();
  }

  bool _hasInitialCheckRun = false;

  Future<void> getConnectivityType() async {
    try {
      List<ConnectivityResult> connectivityResult =
          await connectivity.checkConnectivity();
      _updateState(connectivityResult);

      if (!_hasInitialCheckRun && connectionType != 0) {
        _hasInitialCheckRun = true;
        _onConnectivityRestored();
      }

      _streamSubscription?.cancel();
      _streamSubscription =
          connectivity.onConnectivityChanged.listen((event) {
        _updateState(event);
      });
    } catch (e) {
      // ignore
    }
  }

  void _updateState(List<ConnectivityResult> result) {
    final bool wasOfflineBefore = connectionType == 0;

    if (result.contains(ConnectivityResult.none) || result.isEmpty) {
      if (!result.any((element) => element != ConnectivityResult.none)) {
        connectionType = 0;
      } else {
        connectionType = 1;
      }
    } else if (result.contains(ConnectivityResult.wifi)) {
      connectionType = 1;
    } else if (result.contains(ConnectivityResult.mobile)) {
      connectionType = 2;
    } else {
      connectionType = 1;
    }

    // ── Connectivity restored — trigger offline sync if needed ────────────
    if (wasOfflineBefore && connectionType != 0) {
      _onConnectivityRestored();
    }

    notifyListeners();
  }

  /// Called automatically when connectivity state changes from offline → online.
  ///
  /// Performs a lightweight real-internet check first (HTTP 204), then:
  ///   1. Uploads any pending location GPS batch immediately (no waiting for
  ///      the next 5/10-min timer cycle).
  ///   2. Triggers [OfflinePunchSyncService.syncAllPending] if there are
  ///      pending offline punch records.
  void _onConnectivityRestored() {
    // Run asynchronously — must not block the connectivity stream callback.
    Future<void> syncRun() async {
      // Step 1: Real internet check.
      final bool realInternet = await _verifyRealInternet();
      if (!realInternet) return;

      // Step 2: Load user data from SharedPreferences (needed for both syncs).
      final prefs = await SharedPreferences.getInstance();
      final String userStr = prefs.getString('data') ?? '';
      if (userStr.isEmpty) return;

      Map<String, dynamic>? userData;
      try {
        userData = jsonDecode(userStr) as Map<String, dynamic>;
      } catch (_) {
        return;
      }

      // Step 3: Flush pending location batch immediately (bypass TTL guard by
      // clearing the last API time so uploadPendingBatch runs right now).
      try {
        // Reset the TTL timestamp so the upload is not throttled
        await prefs.remove('last_api_call_time');
        final int locationCount = await LocationBatchStorage.getPendingCount();
        if (locationCount > 0) {
          await LocationBatchStorage.uploadPendingBatch(
            userData: userData,
            isMapScreen: prefs.getBool('MapActive') ?? false,
            isAppForeground: true,
          );
        }
      } catch (_) {
        // Location upload failure is non-fatal — WorkManager will retry
      }

      // Step 4: Sync offline punches.
      final int pendingPunches =
          await OfflinePunchSyncService.instance.pendingCount();
      if (pendingPunches == 0) return;

      final String companyStr = prefs.getString('companysave') ?? '';
      Map<String, dynamic>? companyData;
      if (companyStr.isNotEmpty) {
        try {
          companyData = jsonDecode(companyStr) as Map<String, dynamic>;
        } catch (_) {}
      }

      await OfflinePunchSyncService.instance.syncAllPending(
        userData: userData,
        companyData: companyData,
      );
    }

    syncRun().catchError((_) {});
  }

  /// Pings Google's generate_204 endpoint to confirm real internet access
  /// (not just router connectivity).  Returns true if status == 204.
  static Future<bool> _verifyRealInternet() async {
    try {
      final response = await http
          .head(Uri.parse('https://clients3.google.com/generate_204'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
