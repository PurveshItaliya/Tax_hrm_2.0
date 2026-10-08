// =============================================================================
// common_splash_ad.dart  — v3.0 (FrqCount · Platform · AppVersion · Settings)
//
// ★ DROP-IN COMPONENT — copy only THIS file into any Flutter app's lib/.
//   NO changes required in any other existing screen.
//
// ─────────────────────────────────────────────────────────────────────────────
// MINIMUM USAGE  (only 1 line per entry-point screen)
// ─────────────────────────────────────────────────────────────────────────────
//
//   In your post-login screen's initState / addPostFrameCallback:
//
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await CommonSplashAd.show(
//         context,
//         baseUrl: 'https://your-api.com',
//         appName: 'YOURAPP',
//         custId:  'CUST001',
//       );
//     });
//
//   That's ALL. No splash screen changes. No other file changes.
//   show() handles: API fetch → shimmer → media load → fade-in → close.
//
// ─────────────────────────────────────────────────────────────────────────────
// OPTIONAL PERFORMANCE BOOST  (add to your SplashScreen initState)
// ─────────────────────────────────────────────────────────────────────────────
//
//   CommonSplashAd.prefetch(
//     baseUrl: 'https://your-api.com',
//     appName: 'YOURAPP',
//     custId:  'CUST001',
//   ); // fire-and-forget — media is cached by the time user reaches home
//
//   With prefetch: dialog opens with media already ready (instant display).
//   Without prefetch: dialog opens with shimmer, media fades in when loaded.
//   Either way the dialog always appears — no silent skips.
//
// ─────────────────────────────────────────────────────────────────────────────
// FULL EXAMPLE WITH SEQUENCED DIALOGS (show ad AFTER all other dialogs close)
// ─────────────────────────────────────────────────────────────────────────────
//
//   WidgetsBinding.instance.addPostFrameCallback((_) async {
//     await myOtherFlowCoordinator.start(context); // permissions, upgrade etc.
//     if (!context.mounted) return;
//     await CommonSplashAd.show(
//       context,
//       baseUrl: 'https://your-api.com',
//       appName: 'YOURAPP',
//       custId:  'CUST001',
//       closeButtonDelay: const Duration(seconds: 3),
//       autoCloseOnVideoComplete: false,
//       isLogin: true,
//     );
//   });
//
// ─────────────────────────────────────────────────────────────────────────────
// NEW PARAMETERS (v3.0) — all parsed from API response automatically:
// ─────────────────────────────────────────────────────────────────────────────
//   "FrqCount": 8
//     ↳ Max times to show this ad per day. If user opens app 10×/day and
//       FrqCount=8, the ad shows only on the first 8 opens. Across multiple
//       days each day resets to 0.
//
//   "IsIos": true / "IsAndroid": false
//     ↳ Platform filter. If IsIos=true show only on iOS; IsAndroid=false →
//       skip on Android. Both null/missing → show on all platforms.
//
//   "IsClose": false
//     ↳ false → no close button, dialog cannot be dismissed (forced ad).
//       true  → close button appears after closeButtonDelay (default 3s).
//
//   "AppVersion": "1.0.2,2.0.2,1.22"
//     ↳ Comma-separated list of versions. Ad shown only when current app
//       version matches one of these. Null/empty → show on all versions.
//       Pass current version via CommonSplashAd.appVersion = '1.0.2';
//
//   "Setting": [{"Splashkey":"Download","Splashvalue":"https://...","IsActive":true}]
//     ↳ Bottom action buttons (max 2). Splashkey = label, Splashvalue = URL.
//       IsActive must be true to show. 1 button → full-width expanded.
//       2 buttons → side-by-side, each expanded. Uses theme primary color.
//
// ─────────────────────────────────────────────────────────────────────────────
// 1) PUBSPEC DEPENDENCIES
// ─────────────────────────────────────────────────────────────────────────────
//   http: ^1.2.0
//   shared_preferences: ^2.2.2
//   video_player: ^2.9.1
//   flutter_svg: ^2.0.10
//   flutter_pdfview: ^1.3.2
//   path_provider: ^2.1.3
//   url_launcher: ^6.2.5          ← NEW for Setting button links
//
// ─────────────────────────────────────────────────────────────────────────────
// 2) ANDROID — AndroidManifest.xml
// ─────────────────────────────────────────────────────────────────────────────
//   <uses-permission android:name="android.permission.INTERNET"/>
//   Add to <application> tag if API is HTTP (not HTTPS):
//   android:usesCleartextTraffic="true"
//
// ─────────────────────────────────────────────────────────────────────────────
// 3) iOS — Info.plist (inside root <dict>)
// ─────────────────────────────────────────────────────────────────────────────
//   <key>NSAppTransportSecurity</key>
//   <dict><key>NSAllowsArbitraryLoads</key><true/></dict>
//
// ─────────────────────────────────────────────────────────────────────────────
// LOADING STRATEGY (handles slow networks & release builds)
// ─────────────────────────────────────────────────────────────────────────────
//  show() is called:
//   ├─ prefetch DONE  → dialog opens with media instantly ✅
//   ├─ prefetch IN-FLIGHT → wait up to 6s for list, open with shimmer ✅
//   ├─ prefetch NOT STARTED → fast list-fetch (~100ms), open with shimmer ✅
//   └─ no ad / already shown today → silent no-op ✅
// =============================================================================

// ignore_for_file: unnecessary_underscores, deprecated_member_use, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================================
// JSON HELPERS
// =============================================================================
class _JsonUtils {
  static dynamic ci(Map<String, dynamic> map, String key) {
    if (map.containsKey(key)) return map[key];
    final lowerKey = key.toLowerCase();
    for (final k in map.keys) {
      if (k.toLowerCase() == lowerKey) return map[k];
    }
    return null;
  }

  static String? str(Map<String, dynamic> map, String key) {
    final v = ci(map, key);
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static bool? boolVal(Map<String, dynamic> map, String key) {
    final v = ci(map, key);
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  static int? intVal(Map<String, dynamic> map, String key) {
    final v = ci(map, key);
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString().trim());
  }
}

// =============================================================================
// SETTING BUTTON MODEL
// =============================================================================
class SplashSettingButton {
  final String splashCguid;
  final String key;   // button label (Splashkey)
  final String value; // URL to open (Splashvalue)
  final bool isActive;

  const SplashSettingButton({
    required this.splashCguid,
    required this.key,
    required this.value,
    required this.isActive,
  });

  factory SplashSettingButton.fromJson(Map<String, dynamic> json) {
    return SplashSettingButton(
      splashCguid: _JsonUtils.str(json, 'SplashCguid') ?? '',
      key:        _JsonUtils.str(json, 'Splashkey')   ?? '',
      value:      _JsonUtils.str(json, 'Splashvalue') ?? '',
      isActive:   _JsonUtils.boolVal(json, 'IsActive') ?? false,
    );
  }
}

// =============================================================================
// MODEL
// =============================================================================
class SplashAdModel {
  final String splashCguid;
  final String imageFile;
  final String pdfFile;
  final String title;
  final String remarks;
  final String? startTime;
  final String? endTime;
  final String? appName;

  // ── New v3.0 fields ──────────────────────────────────────────────────────
  /// Max times this ad may be shown per day. 0/null = unlimited.
  final int frqCount;

  /// If non-null, restricts to iOS only (true) or skips iOS (false).
  final bool? isIos;

  /// If non-null, restricts to Android only (true) or skips Android (false).
  final bool? isAndroid;

  /// false = forced (no close button). true = close button shown after delay.
  final bool isClose;

  /// Comma-separated app version strings. Empty = show on all versions.
  final String appVersionRaw;

  /// Bottom action buttons (max 2 active ones are shown).
  final List<SplashSettingButton> settings;

  const SplashAdModel({
    required this.splashCguid,
    required this.imageFile,
    required this.pdfFile,
    required this.title,
    required this.remarks,
    this.startTime,
    this.endTime,
    this.appName,
    this.frqCount         = 0,
    this.isIos,
    this.isAndroid,
    this.isClose          = true,
    this.appVersionRaw    = '',
    this.settings         = const [],
  });

  bool get hasFile => imageFile.isNotEmpty || pdfFile.isNotEmpty;
  String get effectiveFile => imageFile.isNotEmpty ? imageFile : pdfFile;

  /// Active buttons list, limited to max 2.
  List<SplashSettingButton> get activeButtons =>
      settings.where((b) => b.isActive && b.key.isNotEmpty).take(2).toList();

  /// Parsed list of app versions that should see this ad.
  List<String> get allowedVersions =>
      appVersionRaw
          .split(',')
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();

  factory SplashAdModel.fromJson(Map<String, dynamic> json) {
    final rawId       = _JsonUtils.str(json, 'SplashCguid');
    final fileName    = _JsonUtils.str(json, 'Imagefile') ?? '';
    final pdfFileName = _JsonUtils.str(json, 'PDFfile') ??
        _JsonUtils.str(json, 'Pdffile') ??
        _JsonUtils.str(json, 'pdffile') ??
        '';
    final title   = _JsonUtils.str(json, 'Title') ?? '';
    final remarks = _JsonUtils.str(json, 'Remakrs') ??
        _JsonUtils.str(json, 'Remarks') ?? '';
    final startTime = _JsonUtils.str(json, 'StartTime');
    final endTime   = _JsonUtils.str(json, 'endtime') ??
        _JsonUtils.str(json, 'EndTime');
    final appName = _JsonUtils.str(json, 'AppName');
    final stableId = rawId ?? _stableKey(fileName, title, startTime);

    // v3.0 fields
    final frqCount      = _JsonUtils.intVal(json, 'FrqCount') ?? 0;
    final isIos         = _JsonUtils.boolVal(json, 'IsIos');
    final isAndroid     = _JsonUtils.boolVal(json, 'IsAndroid');
    final isClose       = _JsonUtils.boolVal(json, 'IsClose') ?? true;
    final appVersionRaw = _JsonUtils.str(json, 'AppVersion') ?? '';

    // Parse Setting array
    final settingRaw = _JsonUtils.ci(json, 'Setting');
    final List<SplashSettingButton> settings = [];
    if (settingRaw is List) {
      for (final s in settingRaw) {
        try {
          Map<String, dynamic>? map;
          if (s is Map<String, dynamic>) {
            map = s;
          } else if (s is Map) {
            map = Map<String, dynamic>.from(s);
          }
          if (map != null) settings.add(SplashSettingButton.fromJson(map));
        } catch (_) {}
      }
    }

    return SplashAdModel(
      splashCguid:    stableId,
      imageFile:      fileName,
      pdfFile:        pdfFileName,
      title:          title,
      remarks:        remarks,
      startTime:      startTime,
      endTime:        endTime,
      appName:        appName,
      frqCount:       frqCount,
      isIos:          isIos,
      isAndroid:      isAndroid,
      isClose:        isClose,
      appVersionRaw:  appVersionRaw,
      settings:       settings,
    );
  }

  static String _stableKey(String fn, String t, String? et) =>
      'gen_${'$fn|$t|${et ?? ''}'.hashCode}';
}

// =============================================================================
// MEDIA TYPE
// =============================================================================
enum SplashMediaType { image, video, pdf, textOnly, unsupported }

class MediaTypeDetector {
  static const _img = {'png', 'jpg', 'jpeg', 'webp', 'gif', 'svg'};
  static const _vid = {'mp4', 'mov', 'webm', 'm3u8'};

  static SplashMediaType detect(String fileName) {
    if (fileName.trim().isEmpty) return SplashMediaType.textOnly;
    final ext = _ext(fileName);
    if (ext == null) return SplashMediaType.unsupported;
    if (_img.contains(ext)) return SplashMediaType.image;
    if (_vid.contains(ext)) return SplashMediaType.video;
    if (ext == 'pdf') return SplashMediaType.pdf;
    return SplashMediaType.unsupported;
  }

  static String? _ext(String fn) {
    final i = fn.lastIndexOf('.');
    if (i == -1 || i == fn.length - 1) return null;
    return fn.substring(i + 1).toLowerCase().trim();
  }
}

// =============================================================================
// API SERVICE
// =============================================================================
class SplashAdApiService {
  static const _listTimeout  = Duration(seconds: 8);
  static const _mediaTimeout = Duration(seconds: 30);

  static Future<List<SplashAdModel>> fetch({
    required String baseUrl,
    required String appName,
    required String custId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/Master/SplashList').replace(
        queryParameters: {'AppName': appName, 'CustId': custId},
      );
      final response = await http.get(uri).timeout(_listTimeout);
      if (response.statusCode != 200) return [];
      if (response.body.trim().isEmpty) return [];

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        return [];
      }

      List<dynamic> rawList;
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map && decoded['Data'] is List) {
        rawList = decoded['Data'] as List;
      } else if (decoded is Map && decoded['data'] is List) {
        rawList = decoded['data'] as List;
      } else {
        return [];
      }

      final ads = <SplashAdModel>[];
      for (final item in rawList) {
        try {
          Map<String, dynamic>? map;
          if (item is Map<String, dynamic>) {
            map = item;
          } else if (item is Map) {
            map = Map<String, dynamic>.from(item);
          }
          if (map == null) continue;
          final ad = SplashAdModel.fromJson(map);
          if (!ad.hasFile && ad.title.isEmpty && ad.remarks.isEmpty) continue;
          final t = MediaTypeDetector.detect(ad.effectiveFile);
          if (t == SplashMediaType.unsupported) continue;
          ads.add(ad);
        } catch (_) {
          continue;
        }
      }
      return _dedupe(ads);
    } catch (_) {
      return [];
    }
  }

  /// Downloads media bytes to a temp file and returns the File.
  /// Returns null on any failure — caller shows shimmer until this resolves.
  static Future<File?> downloadMedia({
    required String url,
    required String cacheKey,
    required String ext,
  }) async {
    try {
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/splash_ad_$cacheKey.$ext');

      // Return cached file if valid
      if (await file.exists() && await file.length() > 0) return file;

      final response = await http.get(Uri.parse(url)).timeout(_mediaTimeout);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes, flush: true);
        return file;
      }
    } catch (_) {}
    return null;
  }

  static List<SplashAdModel> _dedupe(List<SplashAdModel> ads) {
    final seen   = <String>{};
    final result = <SplashAdModel>[];
    for (final ad in ads) {
      if (seen.add(ad.splashCguid)) result.add(ad);
    }
    return result;
  }
}

// =============================================================================
// DAILY HISTORY MANAGER  (tracks shown-today set)
// =============================================================================
class _DailyHistoryManager {
  static String _key(String a, String c) =>
      'common_splash_ad_history_${a}_$c';

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  static Future<Set<String>> getTodayShown(String appName, String custId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_key(appName, custId));
      if (raw == null) return {};
      final map   = jsonDecode(raw) as Map<String, dynamic>;
      if ((map['date'] as String?) != _today()) {
        await prefs.remove(_key(appName, custId));
        return {};
      }
      return ((map['shown'] as List?)?.whereType<String>().toList() ?? <String>[])
          .toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> markShown(
      String appName, String custId, String cguid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shown = await getTodayShown(appName, custId);
      shown.add(cguid);
      await prefs.setString(
        _key(appName, custId),
        jsonEncode({'date': _today(), 'shown': shown.toList()}),
      );
    } catch (_) {}
  }
}

// =============================================================================
// FREQUENCY COUNTER MANAGER  (FrqCount — counts opens per ad per day)
// =============================================================================
class _FrequencyManager {
  static String _key(String appName, String custId, String cguid) =>
      'splash_frq_${appName}_${custId}_$cguid';

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  /// Returns how many times this ad has been shown today.
  static Future<int> getTodayCount(
      String appName, String custId, String cguid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw   = prefs.getString(_key(appName, custId, cguid));
      if (raw == null) return 0;
      final map   = jsonDecode(raw) as Map<String, dynamic>;
      if ((map['date'] as String?) != _today()) return 0;
      return (map['count'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Increments the daily show-count for this ad.
  static Future<void> increment(
      String appName, String custId, String cguid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = await getTodayCount(appName, custId, cguid);
      await prefs.setString(
        _key(appName, custId, cguid),
        jsonEncode({'date': _today(), 'count': count + 1}),
      );
    } catch (_) {}
  }

  /// Returns true if this ad may still be shown (count < frqCount, or frqCount=0=unlimited).
  static Future<bool> canShow(
      String appName, String custId, SplashAdModel ad) async {
    if (ad.frqCount <= 0) return true; // 0 = unlimited
    final count = await getTodayCount(appName, custId, ad.splashCguid);
    final ok = count < ad.frqCount;
    if (!ok) {
      debugPrint(
        '[SplashAd] ❌ SKIP "${ad.splashCguid}" — FrqCount limit reached. '
            'Shown today: $count | Max allowed: ${ad.frqCount}',
      );
    }
    return ok;
  }
}

// =============================================================================
// PLATFORM FILTER
// =============================================================================
class _PlatformFilter {
  /// Returns false when the ad should be hidden on the current platform.
  ///
  /// Both flags work together as INCLUSION rules:
  ///   IsIos=true,  IsAndroid=true  → show on BOTH iOS and Android
  ///   IsIos=true,  IsAndroid=false → show on iOS only
  ///   IsIos=false, IsAndroid=true  → show on Android only
  ///   IsIos=null,  IsAndroid=null  → show on all platforms (no filter)
  ///   IsIos=null,  IsAndroid=true  → show on Android only (IsIos implicitly excluded)
  ///   IsIos=true,  IsAndroid=null  → show on iOS only (IsAndroid implicitly excluded)
  static bool passes(SplashAdModel ad) {
    try {
      final onIos     = Platform.isIOS;
      final onAndroid = Platform.isAndroid;

      if (onIos) {
        // On iOS: pass if IsIos==true,
        //         OR both flags are null (no restriction).
        //         Block if IsIos==false (explicitly excluded),
        //         OR IsIos==null but IsAndroid==true (Android-only ad).
        final allowed = ad.isIos == true ||
            (ad.isIos == null && ad.isAndroid != true);
        if (!allowed) {
          final reason = ad.isIos == false
              ? 'IsIos=false (iOS explicitly excluded)'
              : 'IsAndroid=true without IsIos=true (Android-only ad)';
          debugPrint('[SplashAd] ❌ SKIP "${ad.splashCguid}" — on iOS but not allowed. Reason: $reason');
          return false;
        }
      }

      if (onAndroid) {
        // On Android: pass if IsAndroid==true,
        //             OR both flags are null (no restriction).
        //             Block if IsAndroid==false (explicitly excluded),
        //             OR IsAndroid==null but IsIos==true (iOS-only ad).
        final allowed = ad.isAndroid == true ||
            (ad.isAndroid == null && ad.isIos != true);
        if (!allowed) {
          final reason = ad.isAndroid == false
              ? 'IsAndroid=false (Android explicitly excluded)'
              : 'IsIos=true without IsAndroid=true (iOS-only ad)';
          debugPrint('[SplashAd] ❌ SKIP "${ad.splashCguid}" — on Android but not allowed. Reason: $reason');
          return false;
        }
      }

      return true;
    } catch (_) {
      return true; // non-mobile platforms: skip filter
    }
  }
}

// =============================================================================
// APP VERSION FILTER
// =============================================================================
class _AppVersionFilter {
  /// Returns false when this ad should not be shown on the current app version.
  /// Pass [currentVersion] via [CommonSplashAd.appVersion].
  static bool passes(SplashAdModel ad, String? currentVersion) {
    final allowed = ad.allowedVersions;
    if (allowed.isEmpty) return true;             // empty = all versions
    if (currentVersion == null || currentVersion.trim().isEmpty) {
      debugPrint('[SplashAd] ❌ SKIP "${ad.splashCguid}" — AppVersion is required [${allowed.join(", ")}] but CommonSplashAd.appVersion is NOT SET in the app!');
      return false;
    }
    final cur = currentVersion.trim();
    final ok = allowed.any((v) => v == cur);
    if (!ok) {
      debugPrint(
        '[SplashAd] ❌ SKIP "${ad.splashCguid}" — AppVersion mismatch. '
            'Current: "$cur" | Allowed: [${allowed.join(", ")}]',
      );
    }
    return ok;
  }
}

// =============================================================================
// SESSION MANAGER
// =============================================================================
class _SplashAdSession {
  static bool _shownThisSession = false;
  static bool _dialogOpen       = false;

  static bool get canShow => !_shownThisSession && !_dialogOpen;

  static void markShown()             => _shownThisSession = true;
  static void setDialogOpen(bool v)   => _dialogOpen = v;
}

// =============================================================================
// PRELOADED AD HOLDER
// =============================================================================
class _PreloadedSplashAd {
  final SplashAdModel       ad;
  final String              mediaUrl;
  final SplashMediaType     mediaType;
  final File?               localFile;
  final VideoPlayerController? videoController;

  _PreloadedSplashAd({
    required this.ad,
    required this.mediaUrl,
    required this.mediaType,
    this.localFile,
    this.videoController,
  });
}

// =============================================================================
// PUBLIC API
// =============================================================================
class CommonSplashAd {
  CommonSplashAd._();

  // ── v3.0: set this once at app startup (e.g. from package_info_plus) ──────
  /// Set to the running app's version string before calling show() or prefetch().
  /// Example:  CommonSplashAd.appVersion = packageInfo.version;  // e.g. "1.0.2"
  /// If not set, CommonSplashAd will attempt to read it automatically from package_info_plus.
  static String? appVersion;

  static Future<void> _ensureAppVersion() async {
    if (appVersion == null || appVersion!.trim().isEmpty) {
      try {
        final info = await PackageInfo.fromPlatform();
        appVersion = info.version;
        debugPrint('[SplashAd] 📱 Auto-detected AppVersion: "$appVersion"');
      } catch (_) {
        debugPrint('[SplashAd] ⚠️ Failed to auto-detect AppVersion');
      }
    }
  }

  // Holds the result of prefetch (may be null if prefetch not finished yet)
  static _PreloadedSplashAd? _preloadedAd;

  // Holds raw ad list fetched from API (set as soon as list arrives,
  // even before media is downloaded — used by show() to open dialog fast)
  static SplashAdModel? _pendingAd;
  static String?        _pendingMediaUrl;
  static SplashMediaType? _pendingMediaType;

  // Tracks ongoing prefetch so show() can wait for it
  static Future<void>? _prefetchFuture;

  // ──────────────────────────────────────────────────────────────────────────
  //  prefetch — call from splash screen, fire-and-forget
  // ──────────────────────────────────────────────────────────────────────────
  static Future<void> prefetch({
    required String baseUrl,
    required String appName,
    required String custId,
  }) async {
    if (!_SplashAdSession.canShow) {
      debugPrint('[SplashAd] ⏭ prefetch() skipped — already shown this session or dialog is open');
      return;
    }
    if (_reloadedAd != null || _pendingAd != null) {
      debugPrint('[SplashAd] ⏭ prefetch() skipped — ad already preloaded/pending');
      return;
    }
    if (_prefetchFuture != null) {
      debugPrint('[SplashAd] ⏭ prefetch() skipped — prefetch already in progress');
      return;
    }

    _prefetchFuture = _doPrefetch(
      baseUrl: baseUrl,
      appName: appName,
      custId: custId,
    );
    await _prefetchFuture;
    _prefetchFuture = null;
  }

  // alias for internal readability
  static _PreloadedSplashAd? get _reloadedAd => _preloadedAd;

  static Future<void> _doPrefetch({
    required String baseUrl,
    required String appName,
    required String custId,
  }) async {
    await _ensureAppVersion();
    try {
      // ── Step 1: Fetch ad list (fast) ──────────────────────────────────────
      debugPrint('[SplashAd] 🔄 Fetching ad list from API...');
      final ads = await SplashAdApiService.fetch(
        baseUrl: baseUrl,
        appName: appName,
        custId: custId,
      );
      if (ads.isEmpty) {
        debugPrint('[SplashAd] ❌ No ads returned from API — dialog will NOT show');
        return;
      }
      debugPrint('[SplashAd] ✅ API returned ${ads.length} ad(s). Running filters...');

      final selected = await _selectAd(ads, appName, custId);
      if (selected == null) {
        debugPrint('[SplashAd] ❌ No eligible ad after all filters — dialog will NOT show');
        return;
      }

      final mediaType = MediaTypeDetector.detect(selected.effectiveFile);
      if (mediaType == SplashMediaType.unsupported) {
        debugPrint('[SplashAd] ❌ SKIP "${selected.splashCguid}" — unsupported media type (file: "${selected.effectiveFile}")');
        return;
      }

      final mediaUrl = _buildMediaUrl(baseUrl, selected, mediaType);

      // Expose the ad metadata immediately so show() can open dialog
      // even if media hasn't downloaded yet
      _pendingAd        = selected;
      _pendingMediaUrl  = mediaUrl;
      _pendingMediaType = mediaType;

      // ── Step 2: Download media (may be slow) ──────────────────────────────
      File? localFile;
      VideoPlayerController? videoController;

      if (mediaUrl.isNotEmpty && mediaType != SplashMediaType.video) {
        final ext = selected.effectiveFile.split('.').last;
        localFile = await SplashAdApiService.downloadMedia(
          url: mediaUrl,
          cacheKey: '${selected.splashCguid}_${selected.effectiveFile.hashCode}',
          ext: ext,
        );
      }

      if (mediaType == SplashMediaType.video && mediaUrl.isNotEmpty) {
        try {
          videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
          await videoController.initialize();
          videoController.setLooping(true);
        } catch (_) {
          videoController?.dispose();
          videoController = null;
        }
      }

      // Promote to fully preloaded
      _preloadedAd = _PreloadedSplashAd(
        ad: selected,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        localFile: localFile,
        videoController: videoController,
      );
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  show — call from bottom bar addPostFrameCallback, after all other dialogs
  // ──────────────────────────────────────────────────────────────────────────
  static Future<void> show(
      BuildContext context, {
        required String baseUrl,
        required String appName,
        required String custId,
        Duration closeButtonDelay       = const Duration(seconds: 3),
        bool autoCloseOnVideoComplete   = false,
        bool isLogin                    = true,
        Color? buttonColor,
      }) async {
    if (!isLogin) {
      debugPrint('[SplashAd] ❌ show() skipped — isLogin=false');
      return;
    }
    if (!_SplashAdSession.canShow) {
      if (_SplashAdSession._shownThisSession) {
        debugPrint('[SplashAd] ❌ show() skipped — already shown once this session');
      } else {
        debugPrint('[SplashAd] ❌ show() skipped — dialog is currently open');
      }
      return;
    }

    await _ensureAppVersion();
    debugPrint('[SplashAd] 🚀 show() called. appVersion="${CommonSplashAd.appVersion ?? "(not set)"}"');

    try {
      // ── Ensure we have at least the ad metadata ───────────────────────────
      if (_preloadedAd == null && _pendingAd == null) {
        if (_prefetchFuture != null) {
          debugPrint('[SplashAd] ⏳ Prefetch in-flight — waiting up to 6s...');
          await _prefetchFuture!.timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              debugPrint('[SplashAd] ⚠️ Prefetch timed out after 6s — will try opening dialog with whatever is ready');
            },
          );
        } else {
          debugPrint('[SplashAd] 🔄 No prefetch started — fetching list now...');
          await _fetchListOnly(
            baseUrl: baseUrl,
            appName: appName,
            custId: custId,
          );
        }
      } else {
        debugPrint('[SplashAd] ⚡ Using prefetched ad data (fast path)');
      }

      // After waiting, decide what we have
      final _PreloadedSplashAd? readyAd    = _preloadedAd;
      final SplashAdModel?      pendingAd  = _pendingAd;
      final String              pendingUrl = _pendingMediaUrl ?? '';
      final SplashMediaType     pendingType =
          _pendingMediaType ?? SplashMediaType.textOnly;

      if (readyAd == null && pendingAd == null) {
        debugPrint('[SplashAd] ❌ No ad available after fetch — dialog will NOT show');
        return;
      }

      if (!context.mounted) {
        debugPrint('[SplashAd] ❌ show() aborted — BuildContext is no longer mounted');
        readyAd?.videoController?.dispose();
        _cleanup();
        return;
      }
      if (!_SplashAdSession.canShow) {
        debugPrint('[SplashAd] ❌ show() aborted — session state changed while fetching');
        readyAd?.videoController?.dispose();
        _cleanup();
        return;
      }

      // ── Mark session as shown BEFORE opening dialog ───────────────────────
      _SplashAdSession.setDialogOpen(true);
      _SplashAdSession.markShown();

      final adModel = readyAd?.ad ?? pendingAd!;

      // Increment frequency counter
      await _FrequencyManager.increment(appName, custId, adModel.splashCguid);
      await _DailyHistoryManager.markShown(appName, custId, adModel.splashCguid);

      if (!context.mounted) {
        debugPrint('[SplashAd] ❌ show() aborted — context unmounted after markShown()');
        readyAd?.videoController?.dispose();
        _cleanup();
        _SplashAdSession.setDialogOpen(false);
        return;
      }
      debugPrint('[SplashAd] ✅ Showing dialog for ad "${adModel.splashCguid}" '
          '| IsClose=${adModel.isClose} | FrqCount=${adModel.frqCount} '
          '| Buttons=${adModel.activeButtons.length} | MediaType=${MediaTypeDetector.detect(adModel.effectiveFile).name}');

      // ── Open dialog ───────────────────────────────────────────────────────
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SplashAdViewer(
          ad: adModel,
          mediaUrl: readyAd?.mediaUrl ?? pendingUrl,
          mediaType: readyAd?.mediaType ?? pendingType,
          preloadedLocalFile: readyAd?.localFile,
          preloadedVideo: readyAd?.videoController,
          needsMediaLoad: readyAd == null,
          closeButtonDelay: closeButtonDelay,
          autoCloseOnVideoComplete: autoCloseOnVideoComplete,
          buttonColor: buttonColor,
        ),
      );
    } catch (_) {
    } finally {
      _cleanup();
      _SplashAdSession.setDialogOpen(false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  static String _buildMediaUrl(
      String base, SplashAdModel ad, SplashMediaType type) {
    if (type == SplashMediaType.pdf && ad.pdfFile.isNotEmpty) {
      return '$base/Uploads/CommonSplash/${ad.pdfFile}';
    } else if (ad.imageFile.isNotEmpty) {
      return '$base/Uploads/CommonSplash/${ad.imageFile}';
    }
    return '';
  }

  /// Lightweight: only fetches the list and sets _pendingAd.
  /// Media download happens inside the dialog widget itself.
  static Future<void> _fetchListOnly({
    required String baseUrl,
    required String appName,
    required String custId,
  }) async {
    try {
      final ads = await SplashAdApiService.fetch(
        baseUrl: baseUrl,
        appName: appName,
        custId: custId,
      );
      if (ads.isEmpty) {
        debugPrint('[SplashAd] ❌ No ads returned from API — dialog will NOT show');
        return;
      }
      debugPrint('[SplashAd] ✅ API returned ${ads.length} ad(s). Running filters...');
      final selected = await _selectAd(ads, appName, custId);
      if (selected == null) {
        debugPrint('[SplashAd] ❌ No eligible ad after all filters — dialog will NOT show');
        return;
      }
      final mediaType = MediaTypeDetector.detect(selected.effectiveFile);
      if (mediaType == SplashMediaType.unsupported) {
        debugPrint('[SplashAd] ❌ SKIP "${selected.splashCguid}" — unsupported media type (file: "${selected.effectiveFile}")');
        return;
      }
      _pendingAd        = selected;
      _pendingMediaUrl  = _buildMediaUrl(baseUrl, selected, mediaType);
      _pendingMediaType = mediaType;
    } catch (_) {}
  }

  /// Selects the first eligible ad applying all v3.0 filters:
  ///   1. Platform filter (IsIos / IsAndroid)
  ///   2. App version filter (AppVersion)
  ///   3. Frequency filter (FrqCount per day)
  ///   4. Not already shown today (daily dedup)
  static Future<SplashAdModel?> _selectAd(
      List<SplashAdModel> ads, String appName, String custId) async {
    final shownToday = await _DailyHistoryManager.getTodayShown(appName, custId);

    for (int i = 0; i < ads.length; i++) {
      final ad = ads[i];
      debugPrint('[SplashAd] 🔍 Checking ad [${i + 1}/${ads.length}]: "${ad.splashCguid}"');

      // 1. Platform filter
      if (!_PlatformFilter.passes(ad)) continue;

      // 2. App version filter
      if (!_AppVersionFilter.passes(ad, appVersion)) continue;

      // 3. Frequency filter — if FrqCount > 0, count must be < FrqCount
      final freqOk = await _FrequencyManager.canShow(appName, custId, ad);
      if (!freqOk) continue;

      // 4. Daily dedup — skip if this ad was already "fully used" today
      //    (We rely on frqCount for repeat ads; shownToday is legacy dedup
      //     kept for backward compat when FrqCount = 0/unlimited.)
      if (ad.frqCount <= 0 && shownToday.contains(ad.splashCguid)) {
        debugPrint('[SplashAd] ❌ SKIP "${ad.splashCguid}" — already shown today (FrqCount=0 unlimited dedup)');
        continue;
      }

      debugPrint('[SplashAd] ✅ Selected ad "${ad.splashCguid}" — all filters passed');
      return ad;
    }
    return null;
  }

  static void _cleanup() {
    _preloadedAd      = null;
    _pendingAd        = null;
    _pendingMediaUrl  = null;
    _pendingMediaType = null;
    _prefetchFuture   = null;
  }
}

// =============================================================================
// VIEWER WIDGET
// The key improvement: when needsMediaLoad=true the widget opens immediately
// showing a shimmer skeleton, then downloads & renders media internally,
// fading it in smoothly once ready.
// =============================================================================
class _SplashAdViewer extends StatefulWidget {
  final SplashAdModel           ad;
  final String                  mediaUrl;
  final SplashMediaType         mediaType;
  final File?                   preloadedLocalFile;
  final VideoPlayerController?  preloadedVideo;
  /// When true the widget must download the media itself (prefetch wasn't ready)
  final bool                    needsMediaLoad;
  final Duration                closeButtonDelay;
  final bool                    autoCloseOnVideoComplete;
  final Color?                  buttonColor;

  const _SplashAdViewer({
    required this.ad,
    required this.mediaUrl,
    required this.mediaType,
    this.preloadedLocalFile,
    this.preloadedVideo,
    required this.needsMediaLoad,
    required this.closeButtonDelay,
    required this.autoCloseOnVideoComplete,
    this.buttonColor,
  });

  @override
  State<_SplashAdViewer> createState() => _SplashAdViewerState();
}

// ── Media load state ────────────────────────────────────────────────────────
enum _MediaState { loading, ready, error }

class _SplashAdViewerState extends State<_SplashAdViewer>
    with TickerProviderStateMixin {

  // ── media state ────────────────────────────────────────────────────────────
  _MediaState           _mediaState = _MediaState.loading;
  File?                 _localFile;
  VideoPlayerController? _videoController;
  String?               _pdfLocalPath;

  // ── loading progress (0.0–1.0; -1 = indeterminate) ───────────────────────
  double _loadProgress  = -1;
  String _loadingLabel  = 'Loading…';

  // ── close-button timer ────────────────────────────────────────────────────
  bool   _canClose   = false;
  Timer? _closeTimer;

  // ── animations ────────────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;
  late AnimationController _shimmerController;

  // ── scroll ────────────────────────────────────────────────────────────────
  final ScrollController _scrollCtrl = ScrollController();
  bool _isScrollable = false;

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for media
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    // Shimmer pulse animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    // Close button timer — only relevant when IsClose=true
    if (widget.ad.isClose) {
      _closeTimer = Timer(widget.closeButtonDelay, () {
        if (mounted) setState(() => _canClose = true);
      });
    }
    // IsClose=false → _canClose stays false forever → button never shown

    // Initialize media
    if (!widget.needsMediaLoad &&
        widget.mediaType != SplashMediaType.textOnly) {
      _initFromPreloaded();
    } else if (widget.mediaType == SplashMediaType.textOnly) {
      _setReady();
    } else {
      _loadMediaInDialog();
    }
  }

  // ── Preloaded path (prefetch finished before show()) ─────────────────────
  void _initFromPreloaded() {
    if (widget.mediaType == SplashMediaType.video) {
      if (widget.preloadedVideo != null) {
        _videoController = widget.preloadedVideo!;
        _videoController!.addListener(_onVideoTick);
        _videoController!.play();
        _setReady();
      } else {
        _updateLabel('Preparing video…');
        _loadVideoInDialog();
      }
    } else if (widget.mediaType == SplashMediaType.pdf) {
      final cachedPath = widget.preloadedLocalFile?.path;
      if (cachedPath != null) {
        _pdfLocalPath = cachedPath;
        _setReady();
      } else {
        _updateLabel('Downloading PDF…');
        _loadPdfInDialog();
      }
    } else {
      _localFile = widget.preloadedLocalFile;
      _setReady();
    }
  }

  // ── Load everything inside the open dialog ────────────────────────────────
  Future<void> _loadMediaInDialog() async {
    switch (widget.mediaType) {
      case SplashMediaType.image:
        await _loadImageInDialog();
        break;
      case SplashMediaType.video:
        await _loadVideoInDialog();
        break;
      case SplashMediaType.pdf:
        await _loadPdfInDialog();
        break;
      default:
        _setReady();
    }
  }

  Future<void> _loadImageInDialog() async {
    if (widget.mediaUrl.isEmpty) { _setError(); return; }
    _updateLabel('Downloading image…');
    try {
      final ext  = widget.mediaUrl.split('.').last.split('?').first;
      final dir  = await getTemporaryDirectory();
      final cacheKey = '${widget.ad.splashCguid}_${widget.ad.effectiveFile.hashCode}';
      final file = File('${dir.path}/splash_ad_$cacheKey.$ext');

      if (await file.exists() && await file.length() > 0) {
        if (!mounted) return;
        _localFile = file;
        _setReady();
        return;
      }

      final downloaded = await _streamDownload(
        url: widget.mediaUrl,
        dest: file,
        label: 'Downloading image…',
      );
      if (!mounted) return;
      _localFile = downloaded;
      _setReady();
    } catch (_) {
      if (mounted) _setReady();
    }
  }

  Future<void> _loadVideoInDialog() async {
    if (widget.mediaUrl.isEmpty) { _setError(); return; }
    _updateLabel('Buffering video…');

    Future<VideoPlayerController?> _tryInit() async {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl));
      try {
        await ctrl.initialize().timeout(const Duration(seconds: 40));
        return ctrl;
      } catch (_) {
        await ctrl.dispose();
        return null;
      }
    }

    VideoPlayerController? ctrl = await _tryInit();

    if (ctrl == null) {
      _updateLabel('Retrying video…');
      await Future.delayed(const Duration(seconds: 2));
      ctrl = await _tryInit();
    }

    if (!mounted) { ctrl?.dispose(); return; }

    if (ctrl != null) {
      ctrl.addListener(_onVideoTick);
      ctrl.setLooping(true);
      ctrl.play();
      _videoController = ctrl;
      _setReady();
    } else {
      _setError();
    }
  }

  Future<void> _loadPdfInDialog() async {
    if (widget.mediaUrl.isEmpty) { _setError(); return; }
    _updateLabel('Downloading PDF…');
    try {
      final dir  = await getTemporaryDirectory();
      final cacheKey = '${widget.ad.splashCguid}_${widget.ad.effectiveFile.hashCode}';
      final file = File('${dir.path}/splash_ad_$cacheKey.pdf');

      if (await file.exists() && await file.length() > 0) {
        if (!mounted) return;
        _pdfLocalPath = file.path;
        _setReady();
        return;
      }

      final downloaded = await _streamDownload(
        url: widget.mediaUrl,
        dest: file,
        label: 'Downloading PDF…',
      );
      if (!mounted) return;
      if (downloaded != null) {
        _pdfLocalPath = downloaded.path;
        _setReady();
      } else {
        _setError();
      }
    } catch (_) {
      if (mounted) _setError();
    }
  }

  /// Streams a download and updates [_loadProgress] + [_loadingLabel].
  Future<File?> _streamDownload({
    required String url,
    required File dest,
    required String label,
  }) async {
    final client = http.Client();
    try {
      final request  = http.Request('GET', Uri.parse(url));
      final response = await client.send(request)
          .timeout(const Duration(seconds: 60));

      final total    = response.contentLength ?? 0;
      int received   = 0;
      final bytes    = <int>[];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0 && mounted) {
          setState(() {
            _loadProgress = received / total;
            _loadingLabel = '$label  ${(received / total * 100).toStringAsFixed(0)}%';
          });
        }
      }

      if (response.statusCode == 200 && bytes.isNotEmpty) {
        await dest.writeAsBytes(bytes, flush: true);
        return dest;
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return null;
  }

  void _updateLabel(String label) {
    if (mounted) setState(() { _loadingLabel = label; _loadProgress = -1; });
  }

  void _setReady() {
    if (!mounted) return;
    setState(() => _mediaState = _MediaState.ready);
    _fadeController.forward();
  }

  void _setError() {
    if (!mounted) return;
    setState(() => _mediaState = _MediaState.error);
    _fadeController.forward();
  }

  void _onVideoTick() {
    final c = _videoController;
    if (c == null || !mounted) return;
    final v = c.value;
    if (widget.autoCloseOnVideoComplete &&
        v.isInitialized &&
        v.duration > Duration.zero &&
        !v.isPlaying &&
        v.position >= v.duration) {
      _close();
    }
  }

  void _close() {
    if (!mounted || _isClosing) return;
    _isClosing = true;
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _closeTimer?.cancel();
    _scrollCtrl.dispose();
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  void _checkScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        final can = _scrollCtrl.position.maxScrollExtent > 0;
        if (can != _isScrollable && mounted) {
          setState(() => _isScrollable = can);
        }
      }
    });
  }

  // ── Open a URL from a Setting button ─────────────────────────────────────
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // 1. Try external application first (for deep links and App/Play store)
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      // 2. If it fails (e.g. Android can't find a component for an apple.com link),
      // fallback to the default platform browser handler.
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('[SplashAd] ❌ Failed to launch URL: $url - Error: $e');
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final size         = MediaQuery.of(context).size;
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final cardBg       = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor   = isDark ? Colors.white : Colors.black87;
    final descColor    = isDark ? const Color(0xFFD0D0D0) : const Color(0xFF4A4A4A);
    final maxH         = size.height * 0.80;
    final maxW         = size.width  * 0.90;
    final maxMediaH    = size.height * 0.52;
    final themeColor   = widget.buttonColor ?? Theme.of(context).primaryColor;

    // Active buttons (max 2, IsActive=true)
    final activeButtons = widget.ad.activeButtons;

    _checkScrollable();

    return PopScope(
        canPop: widget.ad.isClose,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH, maxWidth: maxW),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // ── Main content ──────────────────────────────────────────────
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Media area
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxMediaH,
                          minWidth: double.infinity,
                        ),
                        child: _buildMediaArea(isDark, maxMediaH),
                      ),
                      // Text area
                      if (widget.ad.title.isNotEmpty || widget.ad.remarks.isNotEmpty)
                        Flexible(
                          child: Stack(
                            children: [
                              RawScrollbar(
                                controller: _scrollCtrl,
                                thumbVisibility: _isScrollable,
                                thickness: 4,
                                radius: const Radius.circular(8),
                                thumbColor: isDark ? Colors.white38 : Colors.black26,
                                child: SingleChildScrollView(
                                  controller: _scrollCtrl,
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.ad.title.isNotEmpty)
                                        Text(
                                          widget.ad.title,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.1,
                                            color: titleColor,
                                            height: 1.3,
                                          ),
                                        ),
                                      if (widget.ad.title.isNotEmpty &&
                                          widget.ad.remarks.isNotEmpty)
                                        const SizedBox(height: 10),
                                      if (widget.ad.remarks.isNotEmpty)
                                        Text(
                                          widget.ad.remarks,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: descColor,
                                            height: 1.45,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_isScrollable)
                                Positioned(
                                  bottom: 6, right: 14,
                                  child: IgnorePointer(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.12)
                                            : Colors.black.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.unfold_more, size: 14,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54),
                                          const SizedBox(width: 2),
                                          Text('Scroll',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              )),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // ── Setting buttons (max 2) ───────────────────────────────
                      if (activeButtons.isNotEmpty)
                        _buildSettingButtons(activeButtons, themeColor, isDark),
                    ],
                  ),

                  // ── Close button (IsClose=true only) ─────────────────────────
                  if (widget.ad.isClose)
                    Positioned(
                      top: 10, right: 10,
                      child: AnimatedOpacity(
                        opacity: _canClose ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: !_canClose,
                          child: InkWell(
                            onTap: _close,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.68),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ));
  }

  // ==========================================================================
  // SETTING BUTTONS
  // 1 button  → full-width expanded
  // 2 buttons → side-by-side, each expanded equally
  // Uses theme primary color for styling — works across all apps automatically.
  // ==========================================================================
  Widget _buildSettingButtons(
      List<SplashSettingButton> buttons, Color themeColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _SettingButton(
                label: buttons[i].key,
                url: buttons[i].value,
                themeColor: themeColor,
                onTap: () => _launchUrl(buttons[i].value),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // MEDIA AREA — shimmer → fade-in content
  // ==========================================================================
  Widget _buildMediaArea(bool isDark, double mediaH) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeIn,
      child: _mediaState == _MediaState.loading
          ? _buildShimmer(isDark, mediaH)
          : FadeTransition(
        opacity: _fadeAnim,
        child: _buildLoadedMedia(mediaH),
      ),
    );
  }

  // ── Shimmer skeleton ──────────────────────────────────────────────────────
  Widget _buildShimmer(bool isDark, double mediaH) {
    const shimmerH       = 220.0;
    final baseColor      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8E8);
    final highlightColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F5);
    final labelColor     = isDark ? Colors.white38 : Colors.black38;
    final progressBg     = isDark ? Colors.white12 : Colors.black12;
    final progressFg     = isDark ? Colors.white54 : const Color(0xFF4CAF50);

    return AnimatedBuilder(
      key: const ValueKey('shimmer'),
      animation: _shimmerController,
      builder: (_, __) {
        final t = _shimmerController.value;
        return Container(
          width: double.infinity,
          height: shimmerH,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.5 + t * 3, 0),
              end:   Alignment( 1.5 + t * 3, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 52, height: 52,
                child: _SpinningRing(
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _loadingLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              if (_loadProgress >= 0) ...([
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: _loadProgress,
                        backgroundColor: progressBg,
                        valueColor: AlwaysStoppedAnimation<Color>(progressFg),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  // ── Loaded / error media ──────────────────────────────────────────────────
  Widget _buildLoadedMedia(double maxH) {
    if (_mediaState == _MediaState.error) return _buildError();

    switch (widget.mediaType) {
      case SplashMediaType.image:
        return _buildImage();
      case SplashMediaType.video:
        return _buildVideo();
      case SplashMediaType.pdf:
        return _buildPdf(maxH);
      case SplashMediaType.textOnly:
      case SplashMediaType.unsupported:
        return const SizedBox.shrink();
    }
  }

  Widget _buildError() {
    return const SizedBox(
      width: double.infinity,
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 44, color: Colors.grey),
            SizedBox(height: 8),
            Text('Media unavailable',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final useLocal = _localFile != null &&
        _localFile!.existsSync() &&
        _localFile!.lengthSync() > 0;
    final isSvg = widget.mediaUrl.toLowerCase().endsWith('.svg');

    if (useLocal) {
      if (isSvg) {
        return SvgPicture.file(
          _localFile!,
          width: double.infinity,
          fit: BoxFit.fitWidth,
        );
      }
      return Image.file(
        _localFile!,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (_, __, ___) => _buildNetworkImage(isSvg),
      );
    }
    return _buildNetworkImage(isSvg);
  }

  Widget _buildNetworkImage(bool isSvg) {
    if (widget.mediaUrl.isEmpty) return _buildError();
    if (isSvg) {
      return SvgPicture.network(
        widget.mediaUrl,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        placeholderBuilder: (_) => const SizedBox(
          height: 160,
          child: Center(
            child: SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }
    return Image.network(
      widget.mediaUrl,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => _buildError(),
    );
  }

  Widget _buildVideo() {
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) return _buildError();
    final ratio = ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : 16 / 9;
    return AspectRatio(
      aspectRatio: ratio,
      child: VideoPlayer(ctrl),
    );
  }

  Widget _buildPdf(double maxH) {
    if (_pdfLocalPath == null) return _buildError();
    return SizedBox(
      width: double.infinity,
      height: maxH,
      child: Stack(
        children: [
          Positioned.fill(
            child: PDFView(
              filePath: _pdfLocalPath!,
              fitPolicy: FitPolicy.BOTH,
              enableSwipe: true,
              autoSpacing: true,
              pageSnap: false,
            ),
          ),
          Positioned(
            bottom: 6, right: 6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.black87),
                onPressed: _openFullscreenPdf,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreenPdf() {
    final path = _pdfLocalPath;
    if (path == null) return;
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(widget.ad.title.isEmpty ? 'Document' : widget.ad.title),
          ),
          body: PDFView(filePath: path, fitPolicy: FitPolicy.BOTH),
        ),
      ),
    );
  }
}

// =============================================================================
// SETTING BUTTON WIDGET
// =============================================================================
class _SettingButton extends StatelessWidget {
  final String   label;
  final String   url;
  final Color    themeColor;
  final VoidCallback onTap;

  const _SettingButton({
    required this.label,
    required this.url,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: themeColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SPINNING RING — pure Flutter, no extra package needed
// =============================================================================
class _SpinningRing extends StatefulWidget {
  final Color color;
  const _SpinningRing({required this.color});

  @override
  State<_SpinningRing> createState() => _SpinningRingState();
}

class _SpinningRingState extends State<_SpinningRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.rotate(
        angle: _ctrl.value * 2 * math.pi,
        child: CustomPaint(
          painter: _RingPainter(color: widget.color),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;
  const _RingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color;
}