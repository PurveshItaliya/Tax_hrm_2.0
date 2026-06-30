// ignore_for_file: avoid_print

/// ─────────────────────────────────────────────────────────────────────────────
/// AttendancePerformanceLogger
/// ─────────────────────────────────────────────────────────────────────────────
/// Pure debug/monitoring utility for the AttendanceScreen.
/// ZERO impact on production data-flow — only wraps calls with timing logic
/// and emits structured [print] lines visible in the Flutter debug console.
///
/// Usage:
///   final _logger = AttendancePerformanceLogger();
///   await _logger.track('loadingData', index: 1, () => provider.loadingData(...));
///   _logger.printSummary();
///
/// Thresholds:
///   WARN  ≥ 500 ms
///   SLOW  ≥ 1 000 ms   ← highlighted separately in summary
/// ─────────────────────────────────────────────────────────────────────────────
class AttendancePerformanceLogger {
  static bool isLoggingEnabled = false; // Set to false to disable all logs in production
  static const int _warnThresholdMs = 500;
  static const int _slowThresholdMs = 1000;

  static final AttendancePerformanceLogger instance = AttendancePerformanceLogger._internal();
  AttendancePerformanceLogger._internal();

  int _currentIndex = 1;

  /// Sequential call records, in the order they complete.
  final List<_ApiCallRecord> _records = [];

  /// Session start time (set on first [track] call or [startSession]).
  DateTime? _sessionStart;

  /// Call to record the session start explicitly (optional — first [track]
  /// sets it automatically).
  void startSession(String screenName) {
    if (!isLoggingEnabled) return;
    _sessionStart = DateTime.now();
    _records.clear();
    _currentIndex = 1;
    _sessionStart = DateTime.now();
    _log('┌─────────────────────────────────────────────────────────────────');
    _log('│  ⏱  ATTENDANCE SCREEN — PERFORMANCE SESSION STARTED');
    _log('│  Screen : $screenName');
    _log('│  Start  : ${_fmt(_sessionStart!)}');
    _log('└─────────────────────────────────────────────────────────────────');
  }

  /// Wraps [call] with timing, assigns [index], and logs the result.
  ///
  /// [name]  – human-readable API / method label.
  /// [index] – sequential 1-based call number (assigned by caller for clarity).
  /// [executionMode] – 'sequential' or 'parallel' (default 'sequential').
  Future<T> track<T>(
    String name,
    Future<T> Function() call, {
    String executionMode = 'sequential',
  }) async {
    if (!isLoggingEnabled) {
      return await call();
    }
    _sessionStart ??= DateTime.now();
    final index = _currentIndex++;

    final DateTime startTime = DateTime.now();
    final String modeIcon = executionMode == 'parallel' ? '⇉' : '→';

    _log('  $modeIcon [#$index] START  [$name]  at ${_fmt(startTime)}');

    T result;
    Object? error;
    try {
      result = await call();
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      final DateTime endTime = DateTime.now();
      final int durationMs = endTime.difference(startTime).inMilliseconds;

      final _ApiCallRecord record = _ApiCallRecord(
        index: index,
        name: name,
        startTime: startTime,
        endTime: endTime,
        durationMs: durationMs,
        executionMode: executionMode,
        hadError: error != null,
        errorInfo: error?.toString(),
      );
      _records.add(record);

      final String badge = _badge(durationMs);
      final String errPart = error != null ? '  ❌ ERROR: $error' : '';
      _log('  $modeIcon [#$index] END    [$name]  '
          '${durationMs}ms  $badge  '
          'end: ${_fmt(endTime)}$errPart');
    }

    // return is only reached when no error was thrown
    return result;
  }

  /// Logs a simple milestone (no async work) — useful for marking sync steps.
  void milestone(String label) {
    if (!isLoggingEnabled) return;
    _log('  ★  MILESTONE : $label  at ${_fmt(DateTime.now())}');
  }

  /// Prints a structured summary once all tracked calls have finished.
  void printSummary() {
    if (!isLoggingEnabled) return;
    if (_records.isEmpty) {
      _log('  [AttendancePerfLogger] No API calls were tracked.');
      return;
    }

    final int totalMs = _sessionStart == null
        ? 0
        : DateTime.now().difference(_sessionStart!).inMilliseconds;

    final List<_ApiCallRecord> slow =
        _records.where((r) => r.durationMs >= _slowThresholdMs).toList();
    final List<_ApiCallRecord> warn = _records
        .where((r) =>
            r.durationMs >= _warnThresholdMs && r.durationMs < _slowThresholdMs)
        .toList();
    final List<_ApiCallRecord> parallel =
        _records.where((r) => r.executionMode == 'parallel').toList();
    final List<_ApiCallRecord> sequential =
        _records.where((r) => r.executionMode == 'sequential').toList();
    final List<_ApiCallRecord> errors =
        _records.where((r) => r.hadError).toList();

    _log('');
    _log('╔══════════════════════════════════════════════════════════════════');
    _log('║  📊  ATTENDANCE SCREEN — API PERFORMANCE SUMMARY');
    _log('╠══════════════════════════════════════════════════════════════════');
    _log('║  Total API calls triggered on screen open : ${_records.length}');
    _log('║  Sequential calls : ${sequential.length}');
    _log('║  Parallel   calls : ${parallel.length}');
    _log('║  Total session wall-clock duration        : ${totalMs}ms');
    _log('║  Slow  calls (≥ ${_slowThresholdMs}ms) : ${slow.length}');
    _log('║  Warn  calls (≥ ${_warnThresholdMs}ms) : ${warn.length}');
    _log('║  Failed calls                             : ${errors.length}');
    _log('╠══════════════════════════════════════════════════════════════════');
    _log('║  ALL CALLS (chronological)');
    _log('╠──────────────────────────────────────────────────────────────────');

    for (final r in _records) {
      final String mode = r.executionMode == 'parallel' ? '⇉ PAR' : '→ SEQ';
      final String badge = _badge(r.durationMs);
      final String errMark = r.hadError ? '  ❌' : '';
      _log('║  #${r.index.toString().padLeft(2)}  $mode  '
          '${r.name.padRight(36)}  '
          '${r.durationMs.toString().padLeft(6)}ms  $badge$errMark');
    }

    if (slow.isNotEmpty) {
      _log('╠══════════════════════════════════════════════════════════════════');
      _log('║  🔴  SLOW APIs — Optimization Priority (≥ ${_slowThresholdMs}ms)');
      _log('╠──────────────────────────────────────────────────────────────────');
      for (final r in slow) {
        _log('║  #${r.index.toString().padLeft(2)}  ${r.name.padRight(40)}  ${r.durationMs}ms');
      }
    }

    if (warn.isNotEmpty) {
      _log('╠══════════════════════════════════════════════════════════════════');
      _log('║  🟡  WARN APIs — Worth Monitoring (≥ ${_warnThresholdMs}ms)');
      _log('╠──────────────────────────────────────────────────────────────────');
      for (final r in warn) {
        _log('║  #${r.index.toString().padLeft(2)}  ${r.name.padRight(40)}  ${r.durationMs}ms');
      }
    }

    if (errors.isNotEmpty) {
      _log('╠══════════════════════════════════════════════════════════════════');
      _log('║  ❌  FAILED CALLS');
      _log('╠──────────────────────────────────────────────────────────────────');
      for (final r in errors) {
        _log('║  #${r.index.toString().padLeft(2)}  ${r.name}  →  ${r.errorInfo}');
      }
    }

    _log('╚══════════════════════════════════════════════════════════════════');
    _log('');
  }

  // ─────────────── helpers ──────────────────────────────────────────────────

  static String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}.'
      '${dt.millisecond.toString().padLeft(3, '0')}';

  static String _badge(int ms) {
    if (ms >= _slowThresholdMs) return '🔴 SLOW';
    if (ms >= _warnThresholdMs) return '🟡 WARN';
    return '🟢 OK  ';
  }

  static void _log(String msg) => print('[AttendancePerfLogger] $msg');
}

// ─────────────────────────────────────────────────────────────────────────────
/// Immutable record of a single tracked API call.
// ─────────────────────────────────────────────────────────────────────────────
class _ApiCallRecord {
  final int index;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMs;
  final String executionMode; // 'sequential' | 'parallel'
  final bool hadError;
  final String? errorInfo;

  const _ApiCallRecord({
    required this.index,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.durationMs,
    required this.executionMode,
    this.hadError = false,
    this.errorInfo,
  });
}
