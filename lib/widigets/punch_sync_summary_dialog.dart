// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/models/attendance/attendanceBlog.dart' as blog;
import 'package:tax_hrm/models/offline_punch_record.dart';
import 'package:tax_hrm/services/offline_punch_sync_service.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

/// Handles offline punch confirmation and duplicate punch user validation.
class PunchSyncSummaryDialog extends StatefulWidget {
  final List<OfflinePunchRecord> offlineRecords;
  final List<blog.AttendenceLog> serverLogs;

  const PunchSyncSummaryDialog({
    super.key,
    required this.offlineRecords,
    this.serverLogs = const [],
  });

  /// Check for unviewed results and show appropriate confirmation dialog.
  ///
  /// - Non-duplicate punches: Added directly -> shows simple clean success dialog.
  /// - Duplicate punches: API NOT called -> shows confirmation dialog with "Add Punch" / "Discard" buttons.
  static Future<void> showIfNeeded(
    BuildContext context, {
    List<blog.AttendenceLog> serverLogs = const [],
  }) async {
    final unviewed =
        await OfflinePunchSyncService.instance.getUnviewedResults();
    if (unviewed.isEmpty) return;
    if (!context.mounted) return;

    final duplicates = unviewed
        .where((r) =>
            r.syncStatus == OfflineSyncStatus.duplicateDetected ||
            r.syncStatus == OfflineSyncStatus.needsAttention)
        .toList();

    if (duplicates.isEmpty) {
      // ── Scenario A: No duplicates — Punch was added directly! Show simple dialog.
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: ColorConst.themeColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Punch Added Successfully',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your offline punch has been directly added to your attendance record.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorConst.textgrey,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConst.themeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // ── Scenario B: Duplicate detected — API NOT called yet. Show user confirmation dialog.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PunchSyncSummaryDialog(
          offlineRecords: unviewed,
          serverLogs: serverLogs,
        ),
      );
    }

    // Mark results as viewed after dialog is dismissed.
    await OfflinePunchSyncService.instance.markResultsViewed(
      unviewed.map((r) => r.localId).toList(),
    );
  }

  @override
  State<PunchSyncSummaryDialog> createState() =>
      _PunchSyncSummaryDialogState();
}

class _PunchSyncSummaryDialogState extends State<PunchSyncSummaryDialog> {
  late List<OfflinePunchRecord> _records;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _companyData;
  final Map<String, bool> _loadingMap = {};

  @override
  void initState() {
    super.initState();
    _records = List.from(widget.offlineRecords);
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('curentUser') ?? '';
      final compStr = prefs.getString('companysave') ?? '';
      if (userStr.isNotEmpty) {
        _userData = jsonDecode(userStr) as Map<String, dynamic>;
      }
      if (compStr.isNotEmpty) {
        _companyData = jsonDecode(compStr) as Map<String, dynamic>;
      }
    } catch (_) {}
  }

  Future<void> _handleForceAdd(OfflinePunchRecord record) async {
    setState(() => _loadingMap[record.localId] = true);
    try {
      final userData = _userData ?? {};
      final success = await OfflinePunchSyncService.instance.forceAddPunch(
        record: record,
        userData: userData,
        companyData: _companyData,
      );
      if (success) {
        setState(() {
          final idx = _records.indexWhere((r) => r.localId == record.localId);
          if (idx >= 0) {
            _records[idx] = record.copyWith(
              syncStatus: OfflineSyncStatus.synced,
              syncResultMessage: 'Added to attendance history via API',
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Offline punch added to server successfully!'),
            backgroundColor: ColorConst.themeColor,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add punch. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _loadingMap[record.localId] = false);
    }
  }

  Future<void> _handleDiscard(OfflinePunchRecord record) async {
    setState(() => _loadingMap[record.localId] = true);
    try {
      await OfflinePunchSyncService.instance.removeRecord(record.localId);
      setState(() {
        _records.removeWhere((r) => r.localId == record.localId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duplicate offline punch discarded.'),
          duration: Duration(seconds: 2),
        ),
      );
      if (_records.isEmpty && mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      setState(() => _loadingMap[record.localId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final List<_SummaryEntry> entries = _buildTimeline();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      backgroundColor: ColorConst.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.06,
        vertical: size.height * 0.06,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Simple Professional Header ───────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: ColorConst.themeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duplicate Punch Warning',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Punch recorded within 5 minutes or already in history',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Scrollable Punch List ────────────────────────────────
            Flexible(
              child: entries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(28),
                      child: Text(
                        'All duplicate punches resolved.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final entry = entries[i];
                        final isOffline = entry.source == _EntrySource.offline;
                        final isDuplicate = entry.syncStatus ==
                            OfflineSyncStatus.duplicateDetected;
                        final isLoading =
                            _loadingMap[entry.record?.localId] ?? false;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOffline
                                ? ColorConst.themeColor.withOpacity(0.04)
                                : ColorConst.scaffoldColor,
                            borderRadius: BorderRadius.circular(14),
                            // Unique distinctive border for offline punches!
                            border: isOffline
                                ? Border.all(
                                    color: ColorConst.themeColor,
                                    width: 1.8,
                                  )
                                : Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                    width: 1,
                                  ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Time, Status, Source Tag
                              Row(
                                children: [
                                  Text(
                                    entry.displayTime,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: ColorConst.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ColorConst.themeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      entry.statusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: ColorConst.themeColor,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isOffline)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: ColorConst.themeColor,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        '📱 Offline Punch',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        '🌐 Server History',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              if (entry.location != null &&
                                  entry.location!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        entry.location!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              if (isOffline && entry.message != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: ColorConst.themeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 13, color: ColorConst.themeColor),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          entry.message!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: ColorConst.themeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Action prompt & buttons for duplicate offline punch (API not called yet)
                              if (isOffline &&
                                  entry.record != null &&
                                  entry.syncStatus ==
                                      OfflineSyncStatus.duplicateDetected) ...[
                                const Divider(height: 16),
                                const Text(
                                  'Add this offline punch to history?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                isLoading
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: ColorConst.themeColor,
                                                side: BorderSide(
                                                    color: ColorConst.themeColor),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                              ),
                                              onPressed: () =>
                                                  _handleDiscard(entry.record!),
                                              child: const Text('Discard',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    ColorConst.themeColor,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8),
                                              ),
                                              onPressed: () =>
                                                  _handleForceAdd(entry.record!),
                                              child: const Text('Add Punch',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ),
                                          ),
                                        ],
                                      ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // ── Footer Close Button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConst.themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SummaryEntry> _buildTimeline() {
    final List<_SummaryEntry> entries = [];
    for (final log in widget.serverLogs) {
      final bool isFromOffline = _records.any(
        (r) =>
            r.cguid.isNotEmpty &&
            (log.cguid ?? '').isNotEmpty &&
            log.cguid == r.cguid,
      );
      if (!isFromOffline && log.time != null) {
        entries.add(_SummaryEntry.fromServerLog(log));
      }
    }
    for (final r in _records) {
      entries.add(_SummaryEntry.fromOfflineRecord(r));
    }
    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return entries;
  }
}

enum _EntrySource { offline, web }

class _SummaryEntry {
  final String timestamp;
  final String displayTime;
  final String statusLabel;
  final String statusType;
  final _EntrySource source;
  final OfflineSyncStatus? syncStatus;
  final String? message;
  final String? location;
  final OfflinePunchRecord? record;

  const _SummaryEntry({
    required this.timestamp,
    required this.displayTime,
    required this.statusLabel,
    required this.statusType,
    required this.source,
    this.syncStatus,
    this.message,
    this.location,
    this.record,
  });

  factory _SummaryEntry.fromServerLog(blog.AttendenceLog log) {
    final raw = (log.time ?? '').toString();
    final status = (log.status ?? '').toString().toUpperCase();
    String loc = (log.location ?? '').toString().trim();
    if (loc.isEmpty && (log.latitude ?? '').toString().isNotEmpty) {
      loc = '${log.latitude}, ${log.longitude}';
    }
    return _SummaryEntry(
      timestamp: raw,
      displayTime: OfflinePunchSyncService.formatDisplayTime(raw),
      statusLabel: _statusLabel(status),
      statusType: status,
      source: _EntrySource.web,
      location: loc.isNotEmpty ? loc : null,
    );
  }

  factory _SummaryEntry.fromOfflineRecord(OfflinePunchRecord r) {
    final status = r.punchStatus.toUpperCase();
    String loc = (r.location ?? '').trim();
    if (loc.isEmpty && (r.latitude ?? '').isNotEmpty) {
      loc = '${r.latitude}, ${r.longitude}';
    }
    return _SummaryEntry(
      timestamp: r.punchTimestamp,
      displayTime: OfflinePunchSyncService.formatDisplayTime(r.punchTimestamp),
      statusLabel: _statusLabel(status),
      statusType: status,
      source: _EntrySource.offline,
      syncStatus: r.syncStatus,
      message: r.syncResultMessage ?? r.lastError,
      location: loc.isNotEmpty ? loc : null,
      record: r,
    );
  }

  static String _statusLabel(String s) {
    switch (s.toUpperCase()) {
      case 'IN':
        return 'Punch In';
      case 'OUT':
        return 'Punch Out';
      default:
        return s;
    }
  }
}


