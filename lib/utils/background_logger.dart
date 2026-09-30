import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;

class BackgroundLogger {
  static String? _logPath;

  static Future<File> get _logFile async {
    if (_logPath == null) {
      final directory = await getApplicationDocumentsDirectory();
      _logPath = '${directory.path}/ios_location_logs.txt';
    }
    return File(_logPath!);
  }

  /// Logs a message to the console AND appends it to a persistent local text file.
  static Future<void> log(
    String message, {
    String name = 'BackgroundTracker',
    Object? error,
    StackTrace? stackTrace,
  }) async {
    // 1. Log to IDE console
    developer.log(message, name: name, error: error, stackTrace: stackTrace);

    // 2. Append to persistent file for later reading
    try {
      final file = await _logFile;
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      
      String logLine = '[$timestamp] [$name] $message';
      if (error != null) logLine += ' | Error: $error';
      // Ignoring stacktrace in file to save space, but keeping it in developer console
      
      await file.writeAsString('$logLine\n', mode: FileMode.append);
    } catch (e) {
      developer.log('Failed to write log to file: $e', name: 'BackgroundTracker');
    }
  }
  
  /// Reads all persistent logs.
  static Future<String> readLogs() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      return 'Error reading logs: $e';
    }
    return 'No logs found.';
  }

  /// Clears the persistent log file.
  static Future<void> clearLogs() async {
    try {
      final file = await _logFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      developer.log('Failed to clear logs: $e', name: 'BackgroundTracker');
    }
  }

  /// Dumps the entire log file to the developer console. Useful when restarting the app with debugger attached.
  static Future<void> dumpLogsToConsole() async {
    developer.log('================= SAVED BACKGROUND LOGS =================', name: 'BackgroundTracker');
    final logs = await readLogs();
    // Split into chunks if too large for single log statement
    final lines = logs.split('\n');
    for (var line in lines) {
      if (line.isNotEmpty) {
        developer.log(line, name: 'BackgroundTracker');
      }
    }
    developer.log('=========================================================', name: 'BackgroundTracker');
  }
}
