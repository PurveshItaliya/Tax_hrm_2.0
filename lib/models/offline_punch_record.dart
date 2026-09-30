// ignore_for_file: prefer_collection_literals

import 'dart:convert';

/// Status of an offline punch record in the local sync queue.
enum OfflineSyncStatus {
  /// Saved locally, not yet attempted to sync.
  pending,

  /// Currently being synced (ephemeral – only in memory).
  syncing,

  /// API call succeeded and server confirmed.
  synced,

  /// Server already had this punch (web/other source) — API was intentionally skipped.
  duplicateDetected,

  /// Last sync attempt failed; will retry with backoff.
  retryPending,

  /// Requires manual attention (e.g. selfie file permanently missing,
  /// exceeded safe retry window). Record is preserved but not retried automatically.
  needsAttention,
}

/// Extension for JSON serialisation of the enum.
extension OfflineSyncStatusX on OfflineSyncStatus {
  String get name {
    switch (this) {
      case OfflineSyncStatus.pending:
        return 'pending';
      case OfflineSyncStatus.syncing:
        return 'syncing';
      case OfflineSyncStatus.synced:
        return 'synced';
      case OfflineSyncStatus.duplicateDetected:
        return 'duplicateDetected';
      case OfflineSyncStatus.retryPending:
        return 'retryPending';
      case OfflineSyncStatus.needsAttention:
        return 'needsAttention';
    }
  }

  static OfflineSyncStatus fromString(String? s) {
    switch (s) {
      case 'synced':
        return OfflineSyncStatus.synced;
      case 'duplicateDetected':
        return OfflineSyncStatus.duplicateDetected;
      case 'retryPending':
        return OfflineSyncStatus.retryPending;
      case 'needsAttention':
        return OfflineSyncStatus.needsAttention;
      case 'syncing':
        return OfflineSyncStatus.syncing;
      default:
        return OfflineSyncStatus.pending;
    }
  }
}

/// A single offline punch that is queued for sync to the server.
///
/// All timestamps are stored as ISO-8601 strings for safe JSON round-trip
/// across isolates (WorkManager) and app restarts (SharedPreferences).
class OfflinePunchRecord {
  // ── Immutable identity ───────────────────────────────────────────────────────

  /// Unique ID generated locally (UUID). Used as the idempotency guard so that
  /// the same queue entry is never submitted more than once.
  final String localId;

  /// The Cguid sent to the Punch API. Matches [localId] on first write so that
  /// the server also has an idempotency handle.
  final String cguid;

  // ── Employee / company context ───────────────────────────────────────────────
  final int empId;
  final int companyId;

  /// CustId of the company (e.g. "TAX541").
  final String custId;

  // ── Punch details (preserved exactly as they were at offline punch time) ──────

  /// "IN" or "OUT"
  final String punchStatus;

  /// ISO date of the *working day* (e.g. "2026-09-07T00:00:00.000").
  /// Used for fetching server history.
  final String attendenceDate;

  /// ISO timestamp when the employee actually tapped Punch offline.
  /// NEVER replaced with the sync time.
  final String punchTimestamp;

  final String? latitude;
  final String? longitude;
  final String? location;
  final String? postalCode;
  final String? remarks;
  final bool weekOff;

  /// Persistent local path to the selfie image.
  /// Copied into [getApplicationDocumentsDirectory] immediately after capture.
  /// Null if the punch type does not require a selfie (future-proof).
  final String? persistentImagePath;

  // ── Sync state (mutable) ─────────────────────────────────────────────────────
  OfflineSyncStatus syncStatus;

  /// Human-readable outcome message stored with the record.
  String? syncResultMessage;

  /// ISO timestamp of when the sync was completed (success/duplicate/attention).
  String? syncedAt;

  /// Whether the user has seen this record in the Punch Sync Summary dialog.
  bool resultViewed;

  // ── Retry tracking ───────────────────────────────────────────────────────────

  /// How many times a sync attempt has been made for this record.
  int retryCount;

  /// ISO timestamp of the last sync attempt (for exponential backoff).
  String? lastRetryAt;

  /// Short description of the last error, shown in the dialog if status is
  /// [OfflineSyncStatus.retryPending] or [OfflineSyncStatus.needsAttention].
  String? lastError;

  OfflinePunchRecord({
    required this.localId,
    required this.cguid,
    required this.empId,
    required this.companyId,
    required this.custId,
    required this.punchStatus,
    required this.attendenceDate,
    required this.punchTimestamp,
    this.latitude,
    this.longitude,
    this.location,
    this.postalCode,
    this.remarks,
    this.weekOff = false,
    this.persistentImagePath,
    this.syncStatus = OfflineSyncStatus.pending,
    this.syncResultMessage,
    this.syncedAt,
    this.resultViewed = false,
    this.retryCount = 0,
    this.lastRetryAt,
    this.lastError,
  });

  // ── Serialisation ─────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'cguid': cguid,
        'empId': empId,
        'companyId': companyId,
        'custId': custId,
        'punchStatus': punchStatus,
        'attendenceDate': attendenceDate,
        'punchTimestamp': punchTimestamp,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'postalCode': postalCode,
        'remarks': remarks,
        'weekOff': weekOff,
        'persistentImagePath': persistentImagePath,
        'syncStatus': syncStatus.name,
        'syncResultMessage': syncResultMessage,
        'syncedAt': syncedAt,
        'resultViewed': resultViewed,
        'retryCount': retryCount,
        'lastRetryAt': lastRetryAt,
        'lastError': lastError,
      };

  factory OfflinePunchRecord.fromJson(Map<String, dynamic> json) {
    return OfflinePunchRecord(
      localId: json['localId'] as String,
      cguid: json['cguid'] as String,
      empId: (json['empId'] as num).toInt(),
      companyId: (json['companyId'] as num).toInt(),
      custId: json['custId'] as String? ?? '',
      punchStatus: json['punchStatus'] as String,
      attendenceDate: json['attendenceDate'] as String,
      punchTimestamp: json['punchTimestamp'] as String,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      location: json['location'] as String?,
      postalCode: json['postalCode'] as String?,
      remarks: json['remarks'] as String?,
      weekOff: json['weekOff'] as bool? ?? false,
      persistentImagePath: json['persistentImagePath'] as String?,
      syncStatus: OfflineSyncStatusX.fromString(json['syncStatus'] as String?),
      syncResultMessage: json['syncResultMessage'] as String?,
      syncedAt: json['syncedAt'] as String?,
      resultViewed: json['resultViewed'] as bool? ?? false,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastRetryAt: json['lastRetryAt'] as String?,
      lastError: json['lastError'] as String?,
    );
  }

  /// Returns a copy with updated mutable fields.
  OfflinePunchRecord copyWith({
    OfflineSyncStatus? syncStatus,
    String? syncResultMessage,
    String? syncedAt,
    bool? resultViewed,
    int? retryCount,
    String? lastRetryAt,
    String? lastError,
  }) {
    return OfflinePunchRecord(
      localId: localId,
      cguid: cguid,
      empId: empId,
      companyId: companyId,
      custId: custId,
      punchStatus: punchStatus,
      attendenceDate: attendenceDate,
      punchTimestamp: punchTimestamp,
      latitude: latitude,
      longitude: longitude,
      location: location,
      postalCode: postalCode,
      remarks: remarks,
      weekOff: weekOff,
      persistentImagePath: persistentImagePath,
      syncStatus: syncStatus ?? this.syncStatus,
      syncResultMessage: syncResultMessage ?? this.syncResultMessage,
      syncedAt: syncedAt ?? this.syncedAt,
      resultViewed: resultViewed ?? this.resultViewed,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Encode the full queue (list of records) to a JSON string.
  static String encodeList(List<OfflinePunchRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());

  /// Decode a JSON string back into a list of records.
  static List<OfflinePunchRecord> decodeList(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => OfflinePunchRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
