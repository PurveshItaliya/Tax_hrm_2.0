import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigServices {
  RemoteConfigServices._privateConstructor();
  static final RemoteConfigServices instance = RemoteConfigServices._privateConstructor();

  /// Reactive notifier that increments whenever fresh config is fetched and applied.
  /// Screens can listen to this to immediately refresh UI without reloading.
  static final ValueNotifier<int> configVersion = ValueNotifier<int>(0);

  bool faceVerify = false;
  // Default 0.70 (70%) for both identity and liveness as required
  double _livenessThreshold = 0.70;
  double _identityThreshold = 0.70;

  /// Single switch for the complete Face Verification feature
  /// (punch-screen registration dialog, live verification on punch,
  /// and the re-register tile in Settings). Toggle "faceVerify" in
  /// Firebase Remote Config to turn it ON/OFF without an app update.
  static bool get isFaceVerifyEnabled => instance.faceVerify;

  /// Liveness threshold from Remote Config (default 0.70 / 70%)
  static double get livenessThreshold => instance._livenessThreshold;

  /// Identity threshold from Remote Config (default 0.70 / 70%)
  static double get identityThreshold => instance._identityThreshold;

  /// Normalizes any input representation (e.g. 0.65, 65, "0.65", "65", "65%") into a float [0.05 .. 1.0].
  /// If the number is greater than 1.0 (e.g. 65 or 70), it is automatically divided by 100.
  static double? _normalizeThreshold(dynamic val) {
    if (val == null) return null;
    double? numVal;
    if (val is num) {
      numVal = val.toDouble();
    } else if (val is String) {
      final cleaned = val.replaceAll('%', '').trim();
      numVal = double.tryParse(cleaned);
    }
    if (numVal == null) return null;
    if (numVal > 1.0 && numVal <= 100.0) {
      numVal = numVal / 100.0;
    }
    return numVal.clamp(0.05, 1.0);
  }

  void _parseVerificationConfig(String rawJson) {
    if (rawJson.trim().isEmpty) return;
    try {
      final dynamic decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        // 1. Check Liveness threshold aliases
        for (final key in [
          'liveness_threshold',
          'livenessThreshold',
          'liveness',
          'live_threshold',
          'liveThreshold',
        ]) {
          if (decoded.containsKey(key)) {
            final parsed = _normalizeThreshold(decoded[key]);
            if (parsed != null) {
              _livenessThreshold = parsed;
              debugPrint('[RemoteConfigServices] JSON key "$key" parsed -> $_livenessThreshold (${(_livenessThreshold * 100).toStringAsFixed(1)}%)');
              break;
            }
          }
        }

        // 2. Check Identity threshold aliases
        for (final key in [
          'identity_threshold',
          'identify_threshold',
          'identityThreshold',
          'identifyThreshold',
          'identity',
          'identify',
          'face_match_threshold',
          'match_threshold',
          'threshold',
        ]) {
          if (decoded.containsKey(key)) {
            final parsed = _normalizeThreshold(decoded[key]);
            if (parsed != null) {
              _identityThreshold = parsed;
              debugPrint('[RemoteConfigServices] JSON key "$key" parsed -> $_identityThreshold (${(_identityThreshold * 100).toStringAsFixed(1)}%)');
              break;
            }
          }
        }
      } else if (decoded is num || decoded is String) {
        // If single number or string was passed for the entire config
        final parsed = _normalizeThreshold(decoded);
        if (parsed != null) {
          _identityThreshold = parsed;
          _livenessThreshold = parsed;
          debugPrint('[RemoteConfigServices] Single threshold value applied to both -> $parsed');
        }
      }
    } catch (e) {
      // In case rawJson was a plain number like "0.65" or "65" instead of valid JSON
      final parsed = _normalizeThreshold(rawJson);
      if (parsed != null) {
        _identityThreshold = parsed;
        _livenessThreshold = parsed;
        debugPrint('[RemoteConfigServices] Non-JSON direct threshold applied to both -> $parsed');
      } else {
        debugPrint('[RemoteConfigServices] Error parsing face_verification_config: $e');
      }
    }
  }

  /// Extracts standalone parameters if the user configured them directly in Firebase Console
  void _extractDirectRemoteConfigParams(FirebaseRemoteConfig remoteConfig) {
    // Direct identity threshold keys
    for (final key in [
      'identity_threshold',
      'identify_threshold',
      'identityThreshold',
      'identifyThreshold',
      'face_match_threshold',
      'match_threshold',
      'threshold',
    ]) {
      try {
        final val = remoteConfig.getValue(key);
        if (val.source == ValueSource.valueRemote) {
          final parsed = _normalizeThreshold(val.asString());
          if (parsed != null) {
            _identityThreshold = parsed;
            debugPrint('[RemoteConfigServices] Direct Remote Config key "$key" parsed -> $_identityThreshold (${(_identityThreshold * 100).toStringAsFixed(1)}%)');
            break;
          }
        }
      } catch (_) {}
    }

    // Direct liveness threshold keys
    for (final key in [
      'liveness_threshold',
      'livenessThreshold',
      'live_threshold',
      'liveThreshold',
    ]) {
      try {
        final val = remoteConfig.getValue(key);
        if (val.source == ValueSource.valueRemote) {
          final parsed = _normalizeThreshold(val.asString());
          if (parsed != null) {
            _livenessThreshold = parsed;
            debugPrint('[RemoteConfigServices] Direct Remote Config key "$key" parsed -> $_livenessThreshold (${(_livenessThreshold * 100).toStringAsFixed(1)}%)');
            break;
          }
        }
      } catch (_) {}
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First read from local cache for instant offline fallback
    faceVerify = prefs.getBool('faceVerify_cache') ?? false;
    final cachedConfig = prefs.getString('face_verification_config_cache');
    if (cachedConfig != null && cachedConfig.isNotEmpty) {
      _parseVerificationConfig(cachedConfig);
    } else {
      final savedLive = prefs.getString('liveness_threshold');
      final savedId = prefs.getString('identify_threshold');
      if (savedLive != null && savedLive.isNotEmpty) {
        _livenessThreshold = _normalizeThreshold(savedLive) ?? 0.70;
      }
      if (savedId != null && savedId.isNotEmpty) {
        _identityThreshold = _normalizeThreshold(savedId) ?? 0.70;
      }
    }

    debugPrint('[RemoteConfigServices] Initial local cache: faceVerify=$faceVerify, liveness=$_livenessThreshold, identity=$_identityThreshold');

    // Fetch and activate latest configuration from Firebase
    await fetchLatestConfig();
  }

  /// Fetches and activates latest configuration from Firebase Remote Config.
  /// Safe to call anywhere anytime (e.g. screen open, pull to refresh).
  Future<void> fetchLatestConfig() async {
    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      final prefs = await SharedPreferences.getInstance();

      // Zero fetch interval allows instant fetch of changes
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: Duration.zero,
      ));

      // Defaults for both are strictly 0.7 (70%)
      await remoteConfig.setDefaults(const {
        "faceVerify": false,
        "face_verification_config": '{"liveness_threshold": 0.7, "identity_threshold": 0.7}',
        "identity_threshold": 0.7,
        "identify_threshold": 0.7,
        "liveness_threshold": 0.7,
      });

      final bool activated = await remoteConfig.fetchAndActivate();
      debugPrint('[RemoteConfigServices] fetchAndActivate finished (activated: $activated)');

      faceVerify = remoteConfig.getBool("faceVerify");
      await prefs.setBool('faceVerify_cache', faceVerify);

      final String remoteConfigStr = remoteConfig.getString("face_verification_config");
      if (remoteConfigStr.isNotEmpty) {
        _parseVerificationConfig(remoteConfigStr);
        await prefs.setString('face_verification_config_cache', remoteConfigStr);
      }

      // Check if standalone keys were configured in Firebase Console
      _extractDirectRemoteConfigParams(remoteConfig);

      // Persist latest active values to SharedPreferences
      await prefs.setString('liveness_threshold', _livenessThreshold.toString());
      await prefs.setString('identify_threshold', _identityThreshold.toString());

      // Notify any listening screens that new config values are available
      configVersion.value++;

      debugPrint(
        "[RemoteConfigServices] ACTIVE CONFIG APPLIED: faceVerify=$faceVerify, "
        "livenessThreshold=$_livenessThreshold (${(_livenessThreshold * 100).toStringAsFixed(1)}%), "
        "identityThreshold=$_identityThreshold (${(_identityThreshold * 100).toStringAsFixed(1)}%)",
      );
    } catch (e) {
      debugPrint(
        "[RemoteConfigServices] fetch failed, using active values "
        "(faceVerify=$faceVerify, livenessThreshold=$_livenessThreshold, identityThreshold=$_identityThreshold) : $e",
      );
    }
  }

  Future<void> refresh() async {
    await fetchLatestConfig();
  }
}
