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
  /// Extracts standalone parameters if configured directly in Firebase Console.
  /// Returns true if at least one remote value was parsed from Firebase.
  bool _extractDirectRemoteConfigParams(FirebaseRemoteConfig remoteConfig) {
    bool foundRemote = false;

    // Direct identity threshold keys
    for (final key in [
      'identity_threshold',
      'identify_threshold',
      'identityThreshold',
      'identifyThreshold',
      'face_match_threshold',
      'faceMatchThreshold',
      'match_threshold',
      'matchThreshold',
      'similarity_threshold',
      'similarityThreshold',
      'face_threshold',
      'faceThreshold',
      'face_match',
      'faceMatch',
      'threshold',
    ]) {
      try {
        final val = remoteConfig.getValue(key);
        if (val.source == ValueSource.valueRemote) {
          final parsed = _normalizeThreshold(val.asString());
          if (parsed != null) {
            _identityThreshold = parsed;
            foundRemote = true;
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
      'liveness',
      'live',
      'liveness_score',
      'livenessScore',
    ]) {
      try {
        final val = remoteConfig.getValue(key);
        if (val.source == ValueSource.valueRemote) {
          final parsed = _normalizeThreshold(val.asString());
          if (parsed != null) {
            _livenessThreshold = parsed;
            foundRemote = true;
            debugPrint('[RemoteConfigServices] Direct Remote Config key "$key" parsed -> $_livenessThreshold (${(_livenessThreshold * 100).toStringAsFixed(1)}%)');
            break;
          }
        }
      } catch (_) {}
    }

    return foundRemote;
  }

  /// Updates thresholds from user customization (e.g. Face & Liveness Settings dialog)
  /// and saves to SharedPreferences so they persist across app restarts and remote syncs.
  static Future<void> updateCustomThresholds({
    double? identify,
    double? liveness,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (identify != null) {
      instance._identityThreshold = identify.clamp(0.05, 1.0);
      await prefs.setString('identify_threshold', instance._identityThreshold.toStringAsFixed(2));
    }
    if (liveness != null) {
      instance._livenessThreshold = liveness.clamp(0.05, 1.0);
      await prefs.setString('liveness_threshold', instance._livenessThreshold.toStringAsFixed(2));
    }
    await prefs.setBool('user_custom_thresholds_applied', true);
    configVersion.value++;
    debugPrint(
      '[RemoteConfigServices] User custom thresholds saved: identify=${instance._identityThreshold}, liveness=${instance._livenessThreshold}',
    );
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First read from local cache for instant offline fallback
    faceVerify = prefs.getBool('faceVerify_cache') ?? false;
    final cachedConfig = prefs.getString('face_verification_config_cache');
    if (cachedConfig != null && cachedConfig.isNotEmpty) {
      _parseVerificationConfig(cachedConfig);
    }

    final hasUserCustom = prefs.getBool('user_custom_thresholds_applied') ?? false;
    final savedLive = prefs.getString('liveness_threshold');
    final savedId = prefs.getString('identify_threshold');
    if (savedLive != null && savedLive.isNotEmpty) {
      _livenessThreshold = _normalizeThreshold(savedLive) ?? _livenessThreshold;
    }
    if (savedId != null && savedId.isNotEmpty) {
      _identityThreshold = _normalizeThreshold(savedId) ?? _identityThreshold;
    }

    debugPrint(
      '[RemoteConfigServices] Initial local cache: faceVerify=$faceVerify, '
      'liveness=$_livenessThreshold, identity=$_identityThreshold (custom=$hasUserCustom)',
    );

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
      debugPrint('[RemoteConfigServices] =================== REMOTE CONFIG FETCH ===================');
      debugPrint('[RemoteConfigServices] fetchAndActivate finished (activated: $activated)');
      try {
        final allEntries = remoteConfig.getAll();
        debugPrint('[RemoteConfigServices] Total Keys in Remote Config: ${allEntries.length}');
        for (final entry in allEntries.entries) {
          debugPrint('  • ${entry.key}: "${entry.value.asString()}" (source: ${entry.value.source.name})');
        }
      } catch (_) {}

      faceVerify = remoteConfig.getBool("faceVerify");
      await prefs.setBool('faceVerify_cache', faceVerify);

      final hasUserCustom = prefs.getBool('user_custom_thresholds_applied') ?? false;

      // 1. Check if direct standalone keys were provided by Firebase Remote
      final bool hasRemoteDirect = _extractDirectRemoteConfigParams(remoteConfig);

      // 2. Check if face_verification_config was configured on Firebase Remote
      final valJson = remoteConfig.getValue("face_verification_config");
      final bool hasRemoteJson = valJson.source == ValueSource.valueRemote && valJson.asString().isNotEmpty;
      if (hasRemoteJson) {
        _parseVerificationConfig(valJson.asString());
        await prefs.setString('face_verification_config_cache', valJson.asString());
      }

      // If Firebase Remote Config explicitly provided fresh remote values, apply them immediately
      if (hasRemoteDirect || hasRemoteJson) {
        await prefs.setString('liveness_threshold', _livenessThreshold.toString());
        await prefs.setString('identify_threshold', _identityThreshold.toString());
        if (hasUserCustom) {
          await prefs.setBool('user_custom_thresholds_applied', false);
          debugPrint('[RemoteConfigServices] Fresh Firebase Remote Config received. Reset user_custom override flag.');
        }
        debugPrint(
          '[RemoteConfigServices] Fresh Firebase Remote Config applied -> '
          'identityThreshold=$_identityThreshold, livenessThreshold=$_livenessThreshold',
        );
      } else if (!hasUserCustom) {
        // Fallback to cached JSON or default values
        final String remoteConfigStr = remoteConfig.getString("face_verification_config");
        if (remoteConfigStr.isNotEmpty) {
          _parseVerificationConfig(remoteConfigStr);
        }
        await prefs.setString('liveness_threshold', _livenessThreshold.toString());
        await prefs.setString('identify_threshold', _identityThreshold.toString());
      } else {
        // Retain user's custom settings from settings slider
        final savedLive = prefs.getString('liveness_threshold');
        final savedId = prefs.getString('identify_threshold');
        if (savedLive != null && savedLive.isNotEmpty) {
          _livenessThreshold = _normalizeThreshold(savedLive) ?? _livenessThreshold;
        }
        if (savedId != null && savedId.isNotEmpty) {
          _identityThreshold = _normalizeThreshold(savedId) ?? _identityThreshold;
        }
        debugPrint('[RemoteConfigServices] Retained user custom thresholds -> identity=$_identityThreshold, liveness=$_livenessThreshold');
      }

      // Notify any listening screens that new config values are available
      configVersion.value++;

      debugPrint(
        "[RemoteConfigServices] ACTIVE CONFIG APPLIED: faceVerify=$faceVerify, "
        "livenessThreshold=$_livenessThreshold (${(_livenessThreshold * 100).toStringAsFixed(1)}%), "
        "identityThreshold=$_identityThreshold (${(_identityThreshold * 100).toStringAsFixed(1)}%) (userCustom=$hasUserCustom)",
      );
      debugPrint('[RemoteConfigServices] =========================================================');
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
