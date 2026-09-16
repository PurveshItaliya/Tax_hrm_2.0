// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:tax_hrm/api/attendanceapi.dart';
import 'package:tax_hrm/api/setTimeline.dart';
import 'package:tax_hrm/models/attendance/attendanceBlog.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/models/timeline_event.dart';
import 'package:tax_hrm/services/location_timeline_processor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: represents one punch session (one IN → OUT pair)
// ─────────────────────────────────────────────────────────────────────────────
class _PunchSession {
  final DateTime inTime;
  final DateTime? outTime; // null = currently working
  final double? inLat, inLng;
  final double? outLat, outLng;

  const _PunchSession({
    required this.inTime,
    this.outTime,
    this.inLat,
    this.inLng,
    this.outLat,
    this.outLng,
  });

  bool get isOpen => outTime == null; // no punch out yet

  @override
  String toString() => 'Session IN=$inTime OUT=$outTime isOpen=$isOpen';
}

/// ChangeNotifier provider for the Smart Timeline feature.
///
/// Supports MULTIPLE punch sessions per day (IN→OUT pairs).
/// Each session is processed independently and merged into one combined timeline.
///
/// Existing [TimeLineServices] is UNTOUCHED — this is a separate provider.
class SmartTimelineProvider with ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  bool isLoading = false;
  String? errorMessage;
  DateTime selectedDate = DateTime.now();

  ProcessedTimeline _timeline = ProcessedTimeline.empty();
  ProcessedTimeline get timeline => _timeline;

  List<TimelineEvent> get events => _timeline.events;
  List<List<LatLng>> get routeSegments => _timeline.routeSegments;
  double get totalDistanceKm => _timeline.totalDistanceKm;
  int get totalWorkingMinutes => _timeline.totalWorkingMinutes;
  int get stopsCount => _timeline.stopsCount;
  bool get isCurrentlyWorkedIn => _timeline.isCurrentlyWorkedIn;
  bool get hasData => events.isNotEmpty;

  // Punch sessions for the day (shown in logs)
  List<_PunchSession> _sessions = [];
  int get sessionCount => _sessions.length;

  // ── Human-readable labels ──────────────────────────────────────────────────
  String get workingDurationLabel {
    if (totalWorkingMinutes <= 0) return '—';
    final h = totalWorkingMinutes ~/ 60;
    final m = totalWorkingMinutes % 60;
    if (h == 0) return '$m min';
    return m > 0 ? '$h hr $m min' : '$h hr';
  }

  String get totalDistanceLabel {
    if (totalDistanceKm <= 0) return '0 km';
    if (totalDistanceKm < 1.0) {
      return '${(totalDistanceKm * 1000).toStringAsFixed(0)} m';
    }
    return '${totalDistanceKm.toStringAsFixed(1)} km';
  }

  // ── Main load method ───────────────────────────────────────────────────────
  /// Loads and processes the smart timeline for [empId] on [date].
  /// Handles multiple Punch IN/OUT pairs per day automatically.
  Future<void> load({required String empId, DateTime? date}) async {
    if (date != null) selectedDate = date;

    isLoading = true;
    errorMessage = null;
    _timeline = ProcessedTimeline.empty();
    _sessions = [];
    AddressResolver.clearCache();
    notifyListeners();

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final companyId = selectedcurentcompany!.companyId;

      print('[SMART_TIMELINE] ════════════════════════════════════════════');
      print(
        '[SMART_TIMELINE] Loading for EmpID=$empId | Date=$formattedDate | CompanyID=$companyId',
      );

      // ── Fetch both APIs in parallel ──────────────────────────────────────
      final results = await Future.wait([
        LocationTimeLineClass().getUserTimeLine(
          setUserId: empId,
          selectedDate: formattedDate,
        ),
        AttendanceApis().getDateBlogEmp(
          selectedDate,
          int.tryParse(empId) ?? 0,
          companyId,
        ),
      ]);

      final rawGpsPoints = results[0] as List;
      final attendance = results[1] as AttendanceDayBlog;
      final logs = attendance.attendenceLog ?? [];

      print('[SMART_TIMELINE] Raw GPS records: ${rawGpsPoints.length}');
      print('[SMART_TIMELINE] Punch log entries: ${logs.length}');

      // ── Step 1: Extract ALL IN/OUT pairs ──────────────────────────────────
      _sessions = _extractSessions(logs);

      print('[SMART_TIMELINE] Punch sessions found: ${_sessions.length}');
      for (int i = 0; i < _sessions.length; i++) {
        print('[SMART_TIMELINE]   Session ${i + 1}: ${_sessions[i]}');
      }

      if (_sessions.isEmpty) {
        errorMessage =
            'No Punch In found for ${DateFormat('dd MMM yyyy').format(selectedDate)}';
        isLoading = false;
        notifyListeners();
        return;
      }

      // ── Step 2: Process each session independently ────────────────────────
      final List<ProcessedTimeline> sessionTimelines = [];
      for (final session in _sessions) {
        final result = await LocationTimelineProcessor.process(
          rawGpsPoints: rawGpsPoints.cast(),
          punchInTime: session.inTime,
          punchOutTime: session.outTime,
          punchInLat: session.inLat,
          punchInLng: session.inLng,
          punchOutLat: session.outLat,
          punchOutLng: session.outLng,
        );
        sessionTimelines.add(result);
      }

      // ── Step 3: Merge all sessions into one combined timeline ─────────────
      _timeline = _mergeSessions(sessionTimelines);

      print(
        '[SMART_TIMELINE] ✅ Combined: ${_timeline.events.length} events | ${_timeline.stopsCount} stops | ${_timeline.totalDistanceKm.toStringAsFixed(2)} km | ${_timeline.totalWorkingMinutes} min worked',
      );
      print('[SMART_TIMELINE] ════════════════════════════════════════════');
    } catch (e, stack) {
      print('[SMART_TIMELINE] ❌ Error: $e\n$stack');
      errorMessage = 'Failed to load smart timeline. Please try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Session extraction ─────────────────────────────────────────────────────
  /// Parses all punch logs and returns ordered IN→OUT pairs.
  ///
  /// Algorithm:
  ///   - Walk logs in time order
  ///   - When we see an IN, start a new open session
  ///   - When we see an OUT, close the last open session
  ///   - An IN without OUT = currently working (open session)
  ///   - Multiple INs in a row = only the last IN before an OUT is used
  static List<_PunchSession> _extractSessions(List<AttendenceLog> logs) {
    // Sort logs by time to handle out-of-order API responses
    final sorted = List<AttendenceLog>.from(logs);
    sorted.sort((a, b) {
      final ta = DateTime.tryParse(a.time?.toString() ?? '') ?? DateTime(0);
      final tb = DateTime.tryParse(b.time?.toString() ?? '') ?? DateTime(0);
      return ta.compareTo(tb);
    });

    final List<_PunchSession> sessions = [];
    DateTime? pendingInTime;
    double? pendingInLat, pendingInLng;

    for (final log in sorted) {
      final t = DateTime.tryParse(log.time?.toString() ?? '');
      if (t == null) continue;

      final lat = double.tryParse(log.latitude?.toString() ?? '');
      final lng = double.tryParse(log.longitude?.toString() ?? '');

      if (log.status == 'IN') {
        // Start or restart a session (handles back-to-back INs gracefully)
        pendingInTime = t;
        pendingInLat = lat;
        pendingInLng = lng;
      } else if (log.status == 'OUT' && pendingInTime != null) {
        // Close the open session
        sessions.add(
          _PunchSession(
            inTime: pendingInTime,
            outTime: t,
            inLat: pendingInLat,
            inLng: pendingInLng,
            outLat: lat,
            outLng: lng,
          ),
        );
        // Reset pending
        pendingInTime = null;
        pendingInLat = null;
        pendingInLng = null;
      }
    }

    // If there is a dangling IN with no OUT, it's an open "currently working" session
    if (pendingInTime != null) {
      sessions.add(
        _PunchSession(
          inTime: pendingInTime,
          outTime: null, // open
          inLat: pendingInLat,
          inLng: pendingInLng,
        ),
      );
    }

    return sessions;
  }

  // ── Session merge ──────────────────────────────────────────────────────────
  /// Combines multiple processed session timelines into a single timeline.
  /// Events are sorted by startTime. Totals (distance, working minutes) are summed.
  static ProcessedTimeline _mergeSessions(List<ProcessedTimeline> timelines) {
    if (timelines.isEmpty) return ProcessedTimeline.empty();
    if (timelines.length == 1) return timelines.first;

    final List<TimelineEvent> allEvents = [];
    final List<List<LatLng>> allRouteSegments = [];
    double totalDist = 0;
    int totalMins = 0;
    int totalStops = 0;
    bool anyOpen = false;

    for (final t in timelines) {
      allEvents.addAll(t.events);
      allRouteSegments.addAll(t.routeSegments);
      totalDist += t.totalDistanceKm;
      totalMins += t.totalWorkingMinutes;
      totalStops += t.stopsCount;
      if (t.isCurrentlyWorkedIn) anyOpen = true;
    }

    // Sort all events chronologically across sessions
    allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    return ProcessedTimeline(
      events: allEvents,
      routeSegments: allRouteSegments,
      totalDistanceKm: totalDist,
      totalWorkingMinutes: totalMins,
      stopsCount: totalStops,
      isCurrentlyWorkedIn: anyOpen,
    );
  }

  /// Changes the selected date and reloads data.
  Future<void> changeDate(DateTime newDate, String empId) async {
    selectedDate = newDate;
    await load(empId: empId);
  }
}
