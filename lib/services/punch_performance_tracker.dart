// ignore_for_file: unused_field

import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// High-precision performance tracking utility for the punch flow.
/// Tracks duration of every function, API, and background process
/// from punch button tap until final confirmation/navigation.
class PunchPerformanceTracker {
  static final Stopwatch _totalStopwatch = Stopwatch();
  static final Stopwatch _stepStopwatch = Stopwatch();
  static String _currentFlow = '';
  static final List<PunchStepMetric> _stepMetrics = [];

  /// Start tracking a new punch flow execution
  static void start([String flowName = 'Face Punch Flow']) {
    _currentFlow = flowName;
    _stepMetrics.clear();
    _totalStopwatch.reset();
    _totalStopwatch.start();
    _stepStopwatch.reset();
    _stepStopwatch.start();

    _log('╔══════════════════════════════════════════════════════════════════════════════');
    _log('║ ⏱️ [PUNCH_BENCHMARK] PUNCH FLOW STARTED: $flowName');
    _log('╠══════════════════════════════════════════════════════════════════════════════');
  }

  /// Mark completion of a step and measure elapsed time
  static void step(String stepName, [String? extraDetails]) {
    if (!_totalStopwatch.isRunning) {
      return;
    }

    final int stepMs = _stepStopwatch.elapsedMilliseconds;
    final int totalMs = _totalStopwatch.elapsedMilliseconds;
    _stepStopwatch.reset();
    _stepStopwatch.start();

    String speedTag;
    if (stepMs < 100) {
      speedTag = '⚡ FAST';
    } else if (stepMs <= 500) {
      speedTag = '⏱️ OK  ';
    } else if (stepMs <= 1500) {
      speedTag = '⚠️ SLOW';
    } else {
      speedTag = '🚨 VERY SLOW';
    }

    _stepMetrics.add(PunchStepMetric(
      stepName: stepName,
      stepDurationMs: stepMs,
      totalElapsedMs: totalMs,
      details: extraDetails,
    ));

    final String detailsStr = extraDetails != null ? ' ($extraDetails)' : '';
    final String stepNum = '[${_stepMetrics.length}]'.padRight(4);
    _log('║ $stepNum ${stepName.padRight(38)} : ${stepMs.toString().padLeft(5)} ms | Total: ${totalMs.toString().padLeft(5)} ms | $speedTag$detailsStr');
  }

  /// Conclude tracking and print complete summary report with slowest bottlenecks
  static void finish({required bool isSuccess, String? message}) {
    if (!_totalStopwatch.isRunning) return;
    final int totalMs = _totalStopwatch.elapsedMilliseconds;
    _totalStopwatch.stop();
    _stepStopwatch.stop();

    _log('╠══════════════════════════════════════════════════════════════════════════════');
    _log('║ 🏁 [PUNCH_BENCHMARK] FLOW COMPLETED: ${isSuccess ? "SUCCESS ✅" : "FAILED ❌"} (${message ?? ""})');
    _log('║ 📊 TOTAL PUNCH DURATION: $totalMs ms (${(totalMs / 1000).toStringAsFixed(2)}s)');
    _log('╠──────────────────────────────────────────────────────────────────────────────');
    _log('║ 🔍 TOP TIME-CONSUMING STEPS (BOTTLENECK ANALYSIS):');

    final sorted = List<PunchStepMetric>.from(_stepMetrics)
      ..sort((a, b) => b.stepDurationMs.compareTo(a.stepDurationMs));

    for (int i = 0; i < sorted.length && i < 6; i++) {
      final s = sorted[i];
      final double pct = totalMs > 0 ? (s.stepDurationMs / totalMs * 100) : 0;
      _log('║   #${i + 1} ${s.stepName.padRight(38)} : ${s.stepDurationMs.toString().padLeft(5)} ms (${pct.toStringAsFixed(1)}%)');
    }
    _log('╚══════════════════════════════════════════════════════════════════════════════');
  }

  static void _log(String msg) {
    debugPrint(msg);
    dev.log(msg, name: 'PunchBenchmark');
  }
}

class PunchStepMetric {
  final String stepName;
  final int stepDurationMs;
  final int totalElapsedMs;
  final String? details;

  PunchStepMetric({
    required this.stepName,
    required this.stepDurationMs,
    required this.totalElapsedMs,
    this.details,
  });
}
