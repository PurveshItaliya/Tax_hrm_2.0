// ignore_for_file: avoid_print, empty_catches

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/models/attendance/attendanceBlog.dart'
    as blog;
import 'package:tax_hrm/models/offline_punch_record.dart';
import 'package:tax_hrm/utils/basicdata.dart';

/// ---------------------------------------------------------------------------
/// OfflinePunchSyncService
/// ---------------------------------------------------------------------------
///
/// Single source of truth for the offline punch queue.  All writes and reads
/// go through this singleton so WorkManager isolates and the UI share the
/// same SharedPreferences key.
///
/// SAFETY RULES:
///   • A mutex (_isSyncing) prevents concurrent syncs from connectivity
///     callbacks, app resume, WorkManager, and manual triggers.
///   • Before syncing any record we ALWAYS fetch fresh server history.
///   • Records are processed in ascending punchTimestamp order.
///   • Duplicate detection uses: same empId + same Status + same working date
///     + |serverLogTime – offlineTime| ≤ [kDuplicateToleranceMinutes].
/// ---------------------------------------------------------------------------
class OfflinePunchSyncService {
  OfflinePunchSyncService._internal();
  static final OfflinePunchSyncService instance =
      OfflinePunchSyncService._internal();

  // ── Constants ─────────────────────────────────────────────────────────────

  /// SharedPreferences key that stores the JSON-encoded queue.
  static const String kQueueKey = 'offline_punch_queue';

  /// Configurable duplicate detection window (minutes).
  static const int kDuplicateToleranceMinutes = 5;

  /// Sub-directory inside app documents for persisted selfie images.
  static const String kSelfieDir = 'offline_punch_selfies';

  /// Maximum minutes between retries — avoids hammering the server.
  static const List<int> kRetryBackoffMinutes = [5, 15, 60, 240, 720];

  // ── Mutex ─────────────────────────────────────────────────────────────────
  bool _isSyncing = false;

  // ── Logging helper ────────────────────────────────────────────────────────
  static void _log(String message) {
    // In release builds this prints nothing (dart tree-shaking removes it).
    assert(() {
      print('[OfflineSync] $message');
      return true;
    }());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUEUE CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save a newly created offline punch to the local queue.
  Future<void> savePendingPunch(OfflinePunchRecord record) async {
    _log('📦 Offline record created: localId=${record.localId}, '
        'status=${record.punchStatus}, time=${record.punchTimestamp}');
    final list = await _readQueue();
    list.add(record);
    await _writeQueue(list);
  }

  /// Return all records sorted by punchTimestamp ascending (oldest first).
  Future<List<OfflinePunchRecord>> getAllRecords() async {
    final list = await _readQueue();
    list.sort((a, b) => a.punchTimestamp.compareTo(b.punchTimestamp));
    return list;
  }

  /// Records that have not yet been seen by the user in the summary dialog
  /// AND have a terminal status (synced / duplicate / attention / retryPending).
  Future<List<OfflinePunchRecord>> getUnviewedResults() async {
    final all = await getAllRecords();
    return all.where((r) {
      if (r.resultViewed) return false;
      return r.syncStatus == OfflineSyncStatus.synced ||
          r.syncStatus == OfflineSyncStatus.duplicateDetected ||
          r.syncStatus == OfflineSyncStatus.needsAttention ||
          r.syncStatus == OfflineSyncStatus.retryPending;
    }).toList();
  }

  /// Mark a list of records (by localId) as seen by the user.
  Future<void> markResultsViewed(List<String> localIds) async {
    final list = await _readQueue();
    for (int i = 0; i < list.length; i++) {
      if (localIds.contains(list[i].localId)) {
        list[i] = list[i].copyWith(resultViewed: true);
      }
    }
    await _writeQueue(list);
  }

  /// Delete a record from local queue (e.g. user discards duplicate offline punch).
  Future<void> removeRecord(String localId) async {
    final list = await _readQueue();
    final idx = list.indexWhere((r) => r.localId == localId);
    if (idx >= 0) {
      final rec = list.removeAt(idx);
      await deleteSelfieImage(rec.persistentImagePath);
      await _writeQueue(list);
      _log('🗑 Record removed from queue: $localId');
    }
  }

  /// Force submission of a duplicate or pending punch directly to server.
  Future<bool> forceAddPunch({
    required OfflinePunchRecord record,
    required Map<String, dynamic> userData,
    required Map<String, dynamic>? companyData,
  }) async {
    final token = userData['token'] as String? ?? '';
    if (token.isEmpty) return false;
    final success = await _callPunchApi(
      record: record,
      token: token,
      userData: userData,
      companyData: companyData,
    );
    if (success) {
      final updated = record.copyWith(
        syncStatus: OfflineSyncStatus.synced,
        syncResultMessage: 'Force-submitted successfully',
        syncedAt: DateTime.now().toIso8601String(),
        resultViewed: true,
      );
      await _updateRecord(updated);
    }
    return success;
  }

  /// Update a single record in the queue (matched by localId).
  Future<void> _updateRecord(OfflinePunchRecord updated) async {
    final list = await _readQueue();
    final idx = list.indexWhere((r) => r.localId == updated.localId);
    if (idx >= 0) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    await _writeQueue(list);
  }


  // ═══════════════════════════════════════════════════════════════════════════
  // SELFIE PERSISTENCE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Copy a camera-captured selfie into the app's persistent documents
  /// directory.  Returns the new permanent path, or null on failure.
  ///
  /// Call this IMMEDIATELY after [takePicture()] before the temp file is
  /// cleaned up by the OS or camera plugin.
  static Future<String?> persistSelfieImage(String tempPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final selfieDir =
          Directory('${appDir.path}${Platform.pathSeparator}$kSelfieDir');
      if (!selfieDir.existsSync()) {
        selfieDir.createSync(recursive: true);
      }
      final fileName =
          'punch_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final dest =
          '${selfieDir.path}${Platform.pathSeparator}$fileName';
      await File(tempPath).copy(dest);
      _log('🖼 Selfie persisted to: $dest');
      return dest;
    } catch (e) {
      _log('⚠️ Failed to persist selfie: $e');
      return null;
    }
  }

  /// Delete a persisted selfie after successful sync.
  static Future<void> deleteSelfieImage(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (f.existsSync()) {
        f.deleteSync();
        _log('🗑 Selfie deleted: $path');
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN SYNC ORCHESTRATION (foreground — has BuildContext if needed)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Entry point called when:
  ///   • Internet connectivity is restored (InternetConnectionProvider)
  ///   • App resumes (AppLifecycleState.resumed in main.dart)
  ///   • User manually retries from the dialog
  ///
  /// Requires [userData] (decoded curentUser map) and [companyData] (decoded
  /// selectedcurentcompany map) — passed from foreground context to avoid
  /// touching global state from outside the main isolate.
  Future<void> syncAllPending({
    required Map<String, dynamic> userData,
    required Map<String, dynamic>? companyData,
  }) async {
    if (_isSyncing) {
      _log('⏭ Sync already in progress — skipped.');
      return;
    }

    final pending = await _pendingOrRetryRecords();
    if (pending.isEmpty) {
      _log('✅ No pending offline punches to sync.');
      return;
    }

    _isSyncing = true;
    _log('🚀 Sync started. Pending count: ${pending.length}');

    try {
      final token = userData['token'] as String? ?? '';
      if (token.isEmpty) {
        _log('❌ Sync aborted — no auth token.');
        return;
      }

      // Sort ascending (oldest punch first) to preserve IN → OUT ordering.
      pending.sort((a, b) => a.punchTimestamp.compareTo(b.punchTimestamp));

      for (final record in pending) {
        await _processOneRecord(
          record: record,
          token: token,
          userData: userData,
          companyData: companyData,
        );
      }
    } catch (e) {
      _log('❌ Sync loop error: $e');
    } finally {
      _isSyncing = false;
      _log('🔒 Sync mutex released.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC BACKGROUND SYNC (WorkManager isolate — NO BuildContext)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Called from [callbackDispatcher] in background_location_service.dart.
  ///
  /// Reads user + company data directly from SharedPreferences (no globals)
  /// and processes the pending queue using raw HTTP calls — identical logic
  /// to [syncAllPending] but self-contained for the isolate environment.
  static Future<void> syncInBackground({
    required Map<String, dynamic> userData,
  }) async {
    // Background sync uses a separate SharedPreferences flag as a mutex
    // because _isSyncing is instance-level and not shared across isolates.
    final prefs = await SharedPreferences.getInstance();
    final bool bgSyncing = prefs.getBool('_bg_punch_sync_running') ?? false;
    if (bgSyncing) {
      _log('⏭ [BG] Sync already running in another isolate.');
      return;
    }

    final String queueJson = prefs.getString(kQueueKey) ?? '[]';
    final List<OfflinePunchRecord> all =
        OfflinePunchRecord.decodeList(queueJson);

    final pending = all
        .where((r) =>
            r.syncStatus == OfflineSyncStatus.pending ||
            _isRetryDue(r))
        .toList();

    if (pending.isEmpty) {
      _log('[BG] No pending punches.');
      return;
    }

    await prefs.setBool('_bg_punch_sync_running', true);
    _log('[BG] 🚀 Background sync started. Pending: ${pending.length}');

    try {
      final token = userData['token'] as String? ?? '';
      if (token.isEmpty) return;

      pending.sort((a, b) => a.punchTimestamp.compareTo(b.punchTimestamp));

      final String companyDataStr = prefs.getString('companysave') ?? '';
      Map<String, dynamic>? companyData;
      if (companyDataStr.isNotEmpty) {
        try {
          companyData = jsonDecode(companyDataStr) as Map<String, dynamic>;
        } catch (_) {}
      }

      for (final record in pending) {
        // Re-read queue before each record to get the most current state.
        final fresh = OfflinePunchRecord.decodeList(
            prefs.getString(kQueueKey) ?? '[]');
        final current = fresh.firstWhere(
          (r) => r.localId == record.localId,
          orElse: () => record,
        );

        final updated = await _bgProcessOneRecord(
          record: current,
          token: token,
          userData: userData,
          companyData: companyData,
          prefs: prefs,
        );

        // Persist the updated record back to the queue.
        final updatedAll = OfflinePunchRecord.decodeList(
            prefs.getString(kQueueKey) ?? '[]');
        final idx =
            updatedAll.indexWhere((r) => r.localId == updated.localId);
        if (idx >= 0) {
          updatedAll[idx] = updated;
        }
        await prefs.setString(
            kQueueKey, OfflinePunchRecord.encodeList(updatedAll));
      }
    } catch (e) {
      _log('[BG] ❌ Error: $e');
    } finally {
      await prefs.setBool('_bg_punch_sync_running', false);
      _log('[BG] 🔒 Background sync mutex released.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL — foreground record processor
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _processOneRecord({
    required OfflinePunchRecord record,
    required String token,
    required Map<String, dynamic> userData,
    required Map<String, dynamic>? companyData,
  }) async {
    _log('🔍 Processing localId=${record.localId} '
        '(${record.punchStatus} @ ${record.punchTimestamp})');

    // Mark as syncing (in-memory only, not persisted to avoid flicker).
    OfflinePunchRecord current = record.copyWith(
      syncStatus: OfflineSyncStatus.syncing,
    );

    // ── Step 1: Fetch fresh server punch history ───────────────────────────
    List<blog.AttendenceLog>? serverLogs;
    try {
      serverLogs = await _fetchServerHistory(
        attendenceDate: record.attendenceDate,
        empId: record.empId,
        companyId: record.companyId,
        token: token,
      );
      _log('✅ History fetched. Server logs: ${serverLogs.length}');
    } catch (e) {
      _log('❌ History fetch failed: $e — keeping record retryPending');
      current = current.copyWith(
        syncStatus: OfflineSyncStatus.retryPending,
        retryCount: record.retryCount + 1,
        lastRetryAt: DateTime.now().toIso8601String(),
        lastError: 'Could not fetch server punch history: $e',
      );
      await _updateRecord(current);
      return;
    }

    // ── Step 2: Duplicate detection ────────────────────────────────────────
    final duplicateLog = _findDuplicate(record, serverLogs);
    if (duplicateLog != null) {
      _log('⚠️ Duplicate found: server LogId=${duplicateLog.logId}, '
          'Status=${duplicateLog.status}, Time=${duplicateLog.time}');
      current = current.copyWith(
        syncStatus: OfflineSyncStatus.duplicateDetected,
        syncResultMessage:
            'This offline punch already exists in your server punch history, '
            'so it was not submitted again.',
        syncedAt: DateTime.now().toIso8601String(),
        resultViewed: false,
      );
      await _updateRecord(current);
      _log('⏭ API skipped for localId=${record.localId} — duplicateDetected');
      return;
    }

    // ── Step 3: Sequence validation ────────────────────────────────────────
    final sequenceError = _checkSequence(record, serverLogs);
    if (sequenceError != null) {
      _log('⚠️ Sequence error: $sequenceError');
      current = current.copyWith(
        syncStatus: OfflineSyncStatus.duplicateDetected,
        syncResultMessage: sequenceError,
        syncedAt: DateTime.now().toIso8601String(),
        resultViewed: false,
      );
      await _updateRecord(current);
      return;
    }

    // ── Step 4: Selfie check ───────────────────────────────────────────────
    // The online flow always sends a selfie.  For offline punches we require
    // the image unless it was never stored (persistentImagePath == null).
    if (record.persistentImagePath != null) {
      final imgFile = File(record.persistentImagePath!);
      if (!imgFile.existsSync()) {
        _log('⚠️ Selfie file missing: ${record.persistentImagePath}');
        current = current.copyWith(
          syncStatus: OfflineSyncStatus.needsAttention,
          syncResultMessage: 'Offline punch selfie is no longer available. '
              'Please contact your admin or re-punch.',
          lastError: 'Selfie file deleted from device storage.',
          resultViewed: false,
        );
        await _updateRecord(current);
        return;
      }
    }

    // ── Step 5: Call existing Punch API ───────────────────────────────────
    _log('📡 Calling Punch API for localId=${record.localId} '
        '(${record.punchStatus} @ ${record.punchTimestamp})');
    try {
      final success = await _callPunchApi(
        record: record,
        token: token,
        userData: userData,
        companyData: companyData,
      );

      if (success) {
        _log('✅ API synced for localId=${record.localId}');
        current = current.copyWith(
          syncStatus: OfflineSyncStatus.synced,
          syncResultMessage: 'Your offline punch was synced successfully.',
          syncedAt: DateTime.now().toIso8601String(),
          resultViewed: false,
        );
        await _updateRecord(current);
        // Clean up the selfie once we have server confirmation.
        await deleteSelfieImage(record.persistentImagePath);
      } else {
        _log('❌ API returned failure for localId=${record.localId}');
        current = _incrementRetry(current, 'Server returned failure response.');
        await _updateRecord(current);
      }
    } catch (e) {
      _log('❌ API call threw: $e');
      current = _incrementRetry(current, e.toString());
      await _updateRecord(current);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL — background (static) record processor
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<OfflinePunchRecord> _bgProcessOneRecord({
    required OfflinePunchRecord record,
    required String token,
    required Map<String, dynamic> userData,
    required Map<String, dynamic>? companyData,
    required SharedPreferences prefs,
  }) async {
    _log('[BG] Processing localId=${record.localId}');

    // Step 1: Fresh server history.
    List<blog.AttendenceLog>? serverLogs;
    try {
      serverLogs = await _bgFetchServerHistory(
        attendenceDate: record.attendenceDate,
        empId: record.empId,
        companyId: record.companyId,
        token: token,
      );
    } catch (e) {
      return record.copyWith(
        syncStatus: OfflineSyncStatus.retryPending,
        retryCount: record.retryCount + 1,
        lastRetryAt: DateTime.now().toIso8601String(),
        lastError: 'History fetch failed in background: $e',
      );
    }

    // Step 2: Duplicate detection.
    final dup = _findDuplicate(record, serverLogs);
    if (dup != null) {
      return record.copyWith(
        syncStatus: OfflineSyncStatus.duplicateDetected,
        syncResultMessage:
            'This offline punch already exists in your server punch history, '
            'so it was not submitted again.',
        syncedAt: DateTime.now().toIso8601String(),
        resultViewed: false,
      );
    }

    // Step 3: Sequence validation.
    final seqErr = _checkSequence(record, serverLogs);
    if (seqErr != null) {
      return record.copyWith(
        syncStatus: OfflineSyncStatus.duplicateDetected,
        syncResultMessage: seqErr,
        syncedAt: DateTime.now().toIso8601String(),
        resultViewed: false,
      );
    }

    // Step 4: Selfie check.
    if (record.persistentImagePath != null) {
      final imgFile = File(record.persistentImagePath!);
      if (!imgFile.existsSync()) {
        return record.copyWith(
          syncStatus: OfflineSyncStatus.needsAttention,
          syncResultMessage: 'Offline punch selfie is no longer available.',
          lastError: 'Selfie file deleted from device storage.',
          resultViewed: false,
        );
      }
    }

    // Step 5: Call Punch API.
    try {
      final success = await _bgCallPunchApi(
        record: record,
        token: token,
        userData: userData,
        companyData: companyData,
      );

      if (success) {
        await deleteSelfieImage(record.persistentImagePath);
        return record.copyWith(
          syncStatus: OfflineSyncStatus.synced,
          syncResultMessage: 'Your offline punch was synced successfully.',
          syncedAt: DateTime.now().toIso8601String(),
          resultViewed: false,
        );
      } else {
        return _incrementRetry(record, 'Server returned failure response.');
      }
    } catch (e) {
      return _incrementRetry(record, e.toString());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DUPLICATE DETECTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns the first server log that matches [record] within the tolerance
  /// window, or null if no duplicate is found.
  ///
  /// Match criteria:
  ///   • Same EmpId
  ///   • Same Status (IN / OUT)
  ///   • |serverLogTime – offlineTime| ≤ [kDuplicateToleranceMinutes]
  static blog.AttendenceLog? _findDuplicate(
    OfflinePunchRecord record,
    List<blog.AttendenceLog> serverLogs,
  ) {
    final DateTime offlineTime = DateTime.parse(record.punchTimestamp);

    for (final log in serverLogs) {
      // Status must match exactly.
      if ((log.status ?? '').toUpperCase() !=
          record.punchStatus.toUpperCase()) {
        continue;
      }

      // EmpId must match.
      if (log.empId != null && log.empId != record.empId) continue;

      // Timestamp proximity check.
      if (log.time == null || (log.time as String).isEmpty) continue;
      try {
        final DateTime serverTime = DateTime.parse(log.time as String);
        final int diffMinutes =
            serverTime.difference(offlineTime).inMinutes.abs();
        if (diffMinutes <= kDuplicateToleranceMinutes) {
          return log; // Duplicate found.
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Validates sequence integrity.
  ///
  /// Returns a human-readable error string if the punch would create an invalid
  /// sequence, or null if the sequence is acceptable.
  static String? _checkSequence(
    OfflinePunchRecord record,
    List<blog.AttendenceLog> serverLogs,
  ) {
    if (serverLogs.isEmpty) return null;

    final String lastServerStatus =
        (serverLogs.last.status ?? '').toUpperCase();

    // If the server already has a Punch IN as its most recent log AND this
    // offline record is also a Punch IN → likely duplicate beyond time window.
    if (lastServerStatus == 'IN' &&
        record.punchStatus.toUpperCase() == 'IN') {
      return 'Server already recorded a Punch In. '
          'This offline Punch In was not submitted again to avoid duplication.';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // API CALLS (foreground — uses AttendanceApis-compatible HTTP)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calls the same API as [AttendanceApis.callPunch] and optionally
  /// [AttendanceApis.callWithImgPunch] for the selfie.
  ///
  /// Returns true if the server confirmed success.
  Future<bool> _callPunchApi({
    required OfflinePunchRecord record,
    required String token,
    required Map<String, dynamic> userData,
    required Map<String, dynamic>? companyData,
  }) async {
    final int companyId = record.companyId;
    final String empId = record.empId.toString();

    // Build the same body as AttendanceApis.callPunch.
    final body = jsonEncode({
      'Flag': 'A',
      'IsUser': true,
      'Attendence': {
        'AttendenceDate': DateTime.parse(record.punchTimestamp).toString(),
        'CompanyId': ' $companyId',
        'EmpId': empId,
        'Cguid': record.cguid,
        'Present': true,
        'Absent': false,
        'WeekOff': record.weekOff ? true : null,
      },
      'AttendenceLog': [
        {
          'EmpId': empId,
          'Cguid': record.cguid,
          'Remarks': record.remarks ?? '',
        }
      ],
    });

    final url = Uri.parse('${apibaseurl}api/HRM/NewNewCreateAttendence');
    final response = await http.post(
      url,
      body: body,
      headers: {
        'Authorization': 'bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    bool apiSuccess = false;
    try {
      final data = jsonDecode(response.body);
      apiSuccess = data != null && data['Success'] == true;
    } catch (_) {}

    if (!apiSuccess) return false;

    // Upload selfie if available — mirrors AttendanceApis.callWithImgPunch.
    if (record.persistentImagePath != null) {
      final imageFile = File(record.persistentImagePath!);
      if (imageFile.existsSync()) {
        try {
          final imgUrl =
              Uri.parse('${apibaseurl}api/HRM/AttendenmcelogUploads');
          final req = http.MultipartRequest('POST', imgUrl);
          req.headers.addAll({
            'Content-Type': 'application/json',
            'Accept': '*/*',
            'Authorization': 'bearer $token',
          });
          req.fields.addAll({
            'CompanyId': companyId.toString(),
            'EmpId': empId,
            'Cguid': record.cguid,
            'Longitude': record.longitude ?? '',
            'Latitude': record.latitude ?? '',
            'Location': record.location ?? '',
            'Device': 'mob',
          });
          req.files.add(
            await http.MultipartFile.fromPath('Filename', imageFile.path),
          );
          await req.send().timeout(const Duration(seconds: 20));
        } catch (_) {
          // Selfie upload failure is non-fatal (mirrors existing behaviour).
        }
      }
    }

    // Update SharedPreferences punch-status cache (mirrors AttendanceApis.callPunch).
    try {
      final prefs = await SharedPreferences.getInstance();
      final pDate = DateTime.parse(record.attendenceDate);
      final dateKey =
          '${pDate.year}-${pDate.month.toString().padLeft(2, '0')}-${pDate.day.toString().padLeft(2, '0')}';
      if (record.punchStatus.toUpperCase() == 'IN') {
        await prefs.setBool('punched_in_$dateKey', true);
      } else {
        await prefs.setBool('punched_out_$dateKey', true);
      }
    } catch (_) {}

    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC API CALLS (WorkManager isolate)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> _bgCallPunchApi({
    required OfflinePunchRecord record,
    required String token,
    required Map<String, dynamic> userData,
    required Map<String, dynamic>? companyData,
  }) async {
    final int companyId = record.companyId;
    final String empId = record.empId.toString();

    final body = jsonEncode({
      'Flag': 'A',
      'IsUser': true,
      'Attendence': {
        'AttendenceDate': DateTime.parse(record.punchTimestamp).toString(),
        'CompanyId': ' $companyId',
        'EmpId': empId,
        'Cguid': record.cguid,
        'Present': true,
        'Absent': false,
        'WeekOff': record.weekOff ? true : null,
      },
      'AttendenceLog': [
        {
          'EmpId': empId,
          'Cguid': record.cguid,
          'Remarks': record.remarks ?? '',
        }
      ],
    });

    final url = Uri.parse('${apibaseurl}api/HRM/NewNewCreateAttendence');
    final response = await http.post(
      url,
      body: body,
      headers: {
        'Authorization': 'bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    bool apiSuccess = false;
    try {
      final data = jsonDecode(response.body);
      apiSuccess = data != null && data['Success'] == true;
    } catch (_) {}

    if (!apiSuccess) return false;

    if (record.persistentImagePath != null) {
      final imageFile = File(record.persistentImagePath!);
      if (imageFile.existsSync()) {
        try {
          final imgUrl =
              Uri.parse('${apibaseurl}api/HRM/AttendenmcelogUploads');
          final req = http.MultipartRequest('POST', imgUrl);
          req.headers.addAll({
            'Content-Type': 'application/json',
            'Accept': '*/*',
            'Authorization': 'bearer $token',
          });
          req.fields.addAll({
            'CompanyId': companyId.toString(),
            'EmpId': empId,
            'Cguid': record.cguid,
            'Longitude': record.longitude ?? '',
            'Latitude': record.latitude ?? '',
            'Location': record.location ?? '',
            'Device': 'mob',
          });
          req.files.add(
            await http.MultipartFile.fromPath('Filename', imageFile.path),
          );
          await req.send().timeout(const Duration(seconds: 20));
        } catch (_) {}
      }
    }

    // Update SharedPreferences punch-status cache.
    try {
      final prefs = await SharedPreferences.getInstance();
      final pDate = DateTime.parse(record.attendenceDate);
      final dateKey =
          '${pDate.year}-${pDate.month.toString().padLeft(2, '0')}-${pDate.day.toString().padLeft(2, '0')}';
      if (record.punchStatus.toUpperCase() == 'IN') {
        await prefs.setBool('punched_in_$dateKey', true);
      } else {
        await prefs.setBool('punched_out_$dateKey', true);
      }
    } catch (_) {}

    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVER HISTORY FETCH
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<blog.AttendenceLog>> _fetchServerHistory({
    required String attendenceDate,
    required int empId,
    required int companyId,
    required String token,
  }) async {
    _log('🌐 Fetching server history for date=$attendenceDate, empId=$empId');
    return _bgFetchServerHistory(
      attendenceDate: attendenceDate,
      empId: empId,
      companyId: companyId,
      token: token,
    );
  }

  static Future<List<blog.AttendenceLog>> _bgFetchServerHistory({
    required String attendenceDate,
    required int empId,
    required int companyId,
    required String token,
  }) async {
    final url = Uri.parse(
      '${apibaseurl}api/HRM/GetAttendenceListById'
      '?CompanyID=$companyId&EmpId=$empId&AttendenceDate=$attendenceDate',
    );
    final response = await http.get(
      url,
      headers: {'Authorization': 'bearer $token'},
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'Server returned ${response.statusCode} for attendance history');
    }

    final data = jsonDecode(response.body);
    final rawLogs = data['AttendenceLog'] as List<dynamic>? ?? [];
    return rawLogs
        .map((e) => blog.AttendenceLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<OfflinePunchRecord>> _pendingOrRetryRecords() async {
    final all = await _readQueue();
    return all.where((r) {
      if (r.syncStatus == OfflineSyncStatus.pending) return true;
      if (r.syncStatus == OfflineSyncStatus.retryPending) {
        return _isRetryDue(r);
      }
      return false;
    }).toList();
  }

  static bool _isRetryDue(OfflinePunchRecord r) {
    if (r.syncStatus != OfflineSyncStatus.retryPending) return false;
    if (r.lastRetryAt == null) return true;

    final int idx = (r.retryCount - 1).clamp(0, kRetryBackoffMinutes.length - 1);
    final int backoffMinutes = kRetryBackoffMinutes[idx];

    final DateTime lastRetry = DateTime.parse(r.lastRetryAt!);
    final DateTime nextRetry =
        lastRetry.add(Duration(minutes: backoffMinutes));
    return DateTime.now().isAfter(nextRetry);
  }

  static OfflinePunchRecord _incrementRetry(
      OfflinePunchRecord record, String error) {
    final newCount = record.retryCount + 1;
    return record.copyWith(
      syncStatus: OfflineSyncStatus.retryPending,
      retryCount: newCount,
      lastRetryAt: DateTime.now().toIso8601String(),
      lastError: error,
    );
  }

  Future<List<OfflinePunchRecord>> _readQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(kQueueKey) ?? '[]';
    return OfflinePunchRecord.decodeList(json);
  }

  Future<void> _writeQueue(List<OfflinePunchRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        kQueueKey, OfflinePunchRecord.encodeList(records));
  }

  // ── Public helper to get pending count (for UI badge etc.) ────────────────
  Future<int> pendingCount() async {
    final all = await _readQueue();
    return all.where((r) =>
        r.syncStatus == OfflineSyncStatus.pending ||
        r.syncStatus == OfflineSyncStatus.retryPending).length;
  }

  /// Formats a punch timestamp for display in the sync summary dialog.
  static String formatDisplayTime(String isoTimestamp) {
    try {
      final dt = DateTime.parse(isoTimestamp).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return isoTimestamp;
    }
  }
}
