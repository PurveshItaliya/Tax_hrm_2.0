// =============================================================================
// common_splash_ad.dart  — v2.0 (Robust / Shimmer-Loading Edition)
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
// 1) PUBSPEC DEPENDENCIES
// ─────────────────────────────────────────────────────────────────────────────
//   http: ^1.2.0
//   shared_preferences: ^2.2.2
//   video_player: ^2.9.1
//   flutter_svg: ^2.0.10
//   flutter_pdfview: ^1.3.2
//   path_provider: ^2.1.3
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

// ignore_for_file: unnecessary_underscores

import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

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

  const SplashAdModel({
    required this.splashCguid,
    required this.imageFile,
    required this.pdfFile,
    required this.title,
    required this.remarks,
    this.startTime,
    this.endTime,
    this.appName,
  });

  bool get hasFile => imageFile.isNotEmpty || pdfFile.isNotEmpty;
  String get effectiveFile => imageFile.isNotEmpty ? imageFile : pdfFile;

  factory SplashAdModel.fromJson(Map<String, dynamic> json) {
    final rawId      = _JsonUtils.str(json, 'SplashCguid');
    final fileName   = _JsonUtils.str(json, 'Imagefile') ?? '';
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

    return SplashAdModel(
      splashCguid: stableId,
      imageFile: fileName,
      pdfFile: pdfFileName,
      title: title,
      remarks: remarks,
      startTime: startTime,
      endTime: endTime,
      appName: appName,
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
  static const _mediaTimeout = Duration(seconds: 30); // generous for release

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
// DAILY HISTORY MANAGER
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
    if (!_SplashAdSession.canShow) return;
    if (_preloadedAd != null || _pendingAd != null) return;
    if (_prefetchFuture != null) return; // already running

    _prefetchFuture = _doPrefetch(
      baseUrl: baseUrl,
      appName: appName,
      custId: custId,
    );
    await _prefetchFuture;
    _prefetchFuture = null;
  }

  static Future<void> _doPrefetch({
    required String baseUrl,
    required String appName,
    required String custId,
  }) async {
    try {
      // ── Step 1: Fetch ad list (fast) ──────────────────────────────────────
      final ads = await SplashAdApiService.fetch(
        baseUrl: baseUrl,
        appName: appName,
        custId: custId,
      );
      if (ads.isEmpty) return;

      final selected = await _selectAd(ads, appName, custId);
      if (selected == null) return;

      final mediaType = MediaTypeDetector.detect(selected.effectiveFile);
      if (mediaType == SplashMediaType.unsupported) return;

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
          cacheKey: selected.splashCguid,
          ext: ext,
        );
      }

      if (mediaType == SplashMediaType.video && mediaUrl.isNotEmpty) {
        try {
          videoController = VideoPlayerController.networkUrl(
            Uri.parse(mediaUrl),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
          );
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
      }) async {
    if (!isLogin || !_SplashAdSession.canShow) return;

    try {
      // ── Ensure we have at least the ad metadata ───────────────────────────
      // Case 1: prefetch already finished fully → _preloadedAd is set
      // Case 2: prefetch is still running       → wait for it (max 6s)
      // Case 3: prefetch never started          → run fast list-fetch now
      if (_preloadedAd == null && _pendingAd == null) {
        if (_prefetchFuture != null) {
          // prefetch is in-flight, wait up to 6s for the list at minimum
          await _prefetchFuture!.timeout(
            const Duration(seconds: 6),
            onTimeout: () {},
          );
        } else {
          // Nothing started — kick off now, wait only for the list (not media)
          await _fetchListOnly(
            baseUrl: baseUrl,
            appName: appName,
            custId: custId,
          );
        }
      }

      // After waiting, decide what we have
      final _PreloadedSplashAd? readyAd = _preloadedAd;
      final SplashAdModel?     pendingAd = _pendingAd;
      final String             pendingUrl = _pendingMediaUrl ?? '';
      final SplashMediaType    pendingType =
          _pendingMediaType ?? SplashMediaType.textOnly;

      // If nothing at all → no ad configured / already shown
      if (readyAd == null && pendingAd == null) return;

      if (!context.mounted || !_SplashAdSession.canShow) {
        readyAd?.videoController?.dispose();
        _cleanup();
        return;
      }

      // ── Mark session as shown BEFORE opening dialog ───────────────────────
      _SplashAdSession.setDialogOpen(true);
      _SplashAdSession.markShown();

      final adModel = readyAd?.ad ?? pendingAd!;
      await _DailyHistoryManager.markShown(appName, custId, adModel.splashCguid);

      if (!context.mounted) {
        readyAd?.videoController?.dispose();
        _cleanup();
        _SplashAdSession.setDialogOpen(false);
        return;
      }

      // ── Open dialog ───────────────────────────────────────────────────────
      // If media is ready → pass it in, dialog shows media instantly.
      // If media is NOT ready → dialog opens with shimmer, loads inside itself.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SplashAdViewer(
          ad: adModel,
          mediaUrl: readyAd?.mediaUrl ?? pendingUrl,
          mediaType: readyAd?.mediaType ?? pendingType,
          // If fully preloaded, pass local file / video controller
          preloadedLocalFile: readyAd?.localFile,
          preloadedVideo: readyAd?.videoController,
          // If NOT fully preloaded, dialog must download media internally
          needsMediaLoad: readyAd == null,
          closeButtonDelay: closeButtonDelay,
          autoCloseOnVideoComplete: autoCloseOnVideoComplete,
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
      if (ads.isEmpty) return;
      final selected = await _selectAd(ads, appName, custId);
      if (selected == null) return;
      final mediaType = MediaTypeDetector.detect(selected.effectiveFile);
      if (mediaType == SplashMediaType.unsupported) return;
      _pendingAd        = selected;
      _pendingMediaUrl  = _buildMediaUrl(baseUrl, selected, mediaType);
      _pendingMediaType = mediaType;
    } catch (_) {}
  }

  static Future<SplashAdModel?> _selectAd(
      List<SplashAdModel> ads, String appName, String custId) async {
    final shownToday = await _DailyHistoryManager.getTodayShown(appName, custId);
    for (final ad in ads) {
      if (!shownToday.contains(ad.splashCguid)) return ad;
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

  const _SplashAdViewer({
    required this.ad,
    required this.mediaUrl,
    required this.mediaType,
    this.preloadedLocalFile,
    this.preloadedVideo,
    required this.needsMediaLoad,
    required this.closeButtonDelay,
    required this.autoCloseOnVideoComplete,
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

    // Close button timer
    _closeTimer = Timer(widget.closeButtonDelay, () {
      if (mounted) setState(() => _canClose = true);
    });

    // Initialize media
    if (!widget.needsMediaLoad &&
        widget.mediaType != SplashMediaType.textOnly) {
      // Prefetch was ready — use preloaded assets
      _initFromPreloaded();
    } else if (widget.mediaType == SplashMediaType.textOnly) {
      // No media — instantly ready
      _setReady();
    } else {
      // Must load inside dialog
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
        // Video wasn't cached — load network stream in dialog
        _loadVideoInDialog();
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
    try {
      final ext = widget.mediaUrl.split('.').last.split('?').first;
      final file = await SplashAdApiService.downloadMedia(
        url: widget.mediaUrl,
        cacheKey: widget.ad.splashCguid,
        ext: ext,
      );
      if (!mounted) return;
      _localFile = file; // null = fall back to network Image.network
      _setReady();
    } catch (_) {
      if (mounted) _setReady(); // still try network render
    }
  }

  Future<void> _loadVideoInDialog() async {
    if (widget.mediaUrl.isEmpty) { _setError(); return; }
    try {
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse(widget.mediaUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      ctrl.addListener(_onVideoTick);
      ctrl.setLooping(true);
      ctrl.play();
      _videoController = ctrl;
      _setReady();
    } catch (_) {
      if (mounted) _setError();
    }
  }

  Future<void> _loadPdfInDialog() async {
    if (widget.mediaUrl.isEmpty) { _setError(); return; }
    try {
      final file = await SplashAdApiService.downloadMedia(
        url: widget.mediaUrl,
        cacheKey: widget.ad.splashCguid,
        ext: 'pdf',
      );
      if (!mounted) return;
      if (file != null) {
        _pdfLocalPath = file.path;
        _setReady();
      } else {
        _setError();
      }
    } catch (_) {
      if (mounted) _setError();
    }
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

    _checkScrollable();

    return Dialog(
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
                  // Media area: constrained by maxMediaH, media sizes itself
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
                ],
              ),

              // ── Close button (fades in after delay) ───────────────────────
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

  // ── Shimmer skeleton — fixed comfortable height while media is unknown ───────
  Widget _buildShimmer(bool isDark, double mediaH) {
    // Use 220px as shimmer height — comfortable placeholder regardless of
    // what the actual media height will be once loaded.
    const shimmerH = 220.0;
    final baseColor      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8E8);
    final highlightColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF5F5F5);

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
                width: 52,
                height: 52,
                child: _SpinningRing(
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading…',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Loaded / error media — each widget sizes itself, no forced height ────────
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

  // Error state — compact fixed height, no wasted space
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

  // Image: fills full width, height auto-adapts to image's own aspect ratio.
  // BoxFit.fitWidth = fill width exactly, let height follow → no black space.
  // Parent ConstrainedBox(maxHeight) prevents it from being too tall.
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
              width: 32,
              height: 32,
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

  // Video: AspectRatio drives height from the video's real ratio.
  // Width is constrained by dialog; height is natural. No black bars.
  Widget _buildVideo() {
    final ctrl = _videoController;
    if (ctrl == null || !ctrl.value.isInitialized) return _buildError();
    final ratio = ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : 16 / 9;
    return AspectRatio(
      aspectRatio: ratio,
      child: VideoPlayer(ctrl),
    );
  }

  // PDF: needs an explicit height for the native PDFView renderer.
  // We use maxH (the ConstrainedBox cap) to fill the allowed space fully.
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