// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:tax_hrm/page/face_punch_2/face_sdk_engine.dart';
import 'package:tax_hrm/services/remote_config_services.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Data model
// ──────────────────────────────────────────────────────────────────────────────

class FaceSdkPerson {
  final String name;
  final Uint8List faceJpg;
  final Uint8List templates;

  const FaceSdkPerson({
    required this.name,
    required this.faceJpg,
    required this.templates,
  });

  factory FaceSdkPerson.fromMap(Map<String, dynamic> data) => FaceSdkPerson(
        name: data['name'] as String,
        faceJpg: Uint8List.fromList(data['faceJpg'] as List<int>),
        templates: Uint8List.fromList(data['templates'] as List<int>),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
// DB helper (shared with enroll flow)
// ──────────────────────────────────────────────────────────────────────────────

class FaceSdkDatabase {
  static const _dbName = 'facesdk_person.db';
  static const _tableName = 'person';

  static Future<Database> open() async {
    return openDatabase(
      p.join(await getDatabasesPath(), _dbName),
      onCreate: (db, _) =>
          db.execute('CREATE TABLE $_tableName(name text, faceJpg blob, templates blob)'),
      version: 1,
    );
  }

  static Future<List<FaceSdkPerson>> loadAll() async {
    final db = await open();
    final maps = await db.query(_tableName);
    return maps.map((m) => FaceSdkPerson.fromMap(m)).toList();
  }

  static Future<void> insertPerson(FaceSdkPerson person) async {
    final db = await open();
    await db.delete(_tableName, where: 'name = ?', whereArgs: [person.name]);
    await db.insert(
      _tableName,
      {'name': person.name, 'faceJpg': person.faceJpg, 'templates': person.templates},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deletePerson(String name) async {
    final db = await open();
    await db.delete(_tableName, where: 'name = ?', whereArgs: [name]);
  }

  static Future<void> deleteUserTemplates(String userId) async {
    final db = await open();
    await db.delete(_tableName, where: 'name = ? OR name LIKE ?', whereArgs: [userId, '${userId}_%']);
  }

  static Future<void> deleteAll() async {
    final db = await open();
    await db.delete(_tableName);
  }

  static Future<void> migrateLegacyEmployeeNameIfNeeded(String targetName) async {
    try {
      final db = await open();
      final existingUserRows = await db.query(
        _tableName,
        where: 'name = ? OR name LIKE ?',
        whereArgs: [targetName, '${targetName}_%'],
      );
      if (existingUserRows.isNotEmpty) {
        // User already has a valid enrollment; clean up any stale legacy 'Employee' test record
        await db.delete(_tableName, where: 'name = ?', whereArgs: ['Employee']);
        debugPrint('[FaceSdkDatabase] Removed stale legacy "Employee" record because user already has valid enrolled template');
        return;
      }

      // Remove any legacy unassigned 'Employee' record so new users never inherit old faces
      await db.delete(_tableName, where: 'name = ?', whereArgs: ['Employee']);
      debugPrint('[FaceSdkDatabase] Ensured stale legacy "Employee" record is removed');
    } catch (e) {
      debugPrint('[FaceSdkDatabase] Migration error: $e');
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Verify Screen Result & Screen definition
// ──────────────────────────────────────────────────────────────────────────────

class FaceSdkVerifyResult {
  final bool isSuccess;
  final Uint8List? faceJpg;
  final String? matchedName;

  const FaceSdkVerifyResult({
    required this.isSuccess,
    this.faceJpg,
    this.matchedName,
  });
}

// ignore: must_be_immutable
class FaceSdkVerifyScreen extends StatefulWidget {
  final List<FaceSdkPerson> personList;

  const FaceSdkVerifyScreen({super.key, required this.personList});

  @override
  State<StatefulWidget> createState() => FaceSdkVerifyScreenState();
}

class FaceSdkVerifyScreenState extends State<FaceSdkVerifyScreen> {
  dynamic _faces;
  double _livenessThreshold = 0.8;
  double _identifyThreshold = 0.8;
  bool _recognized = false;
  String _identifiedName = '';
  String _identifiedSimilarity = '';
  String _identifiedLiveness = '';
  String _identifiedYaw = '';
  String _identifiedRoll = '';
  String _identifiedPitch = '';
  Uint8List? _identifiedFace;
  Uint8List? _enrolledFace;

  final GlobalKey<_FaceDetectionViewWidgetState> _cameraKey = GlobalKey<_FaceDetectionViewWidgetState>();

  @override
  void initState() {
    super.initState();
    RemoteConfigServices.configVersion.addListener(_onRemoteConfigUpdated);
    _loadSettings();
  }

  @override
  void dispose() {
    RemoteConfigServices.configVersion.removeListener(_onRemoteConfigUpdated);
    super.dispose();
  }

  void _onRemoteConfigUpdated() {
    if (!mounted) return;
    _applySettings();
  }

  void _applySettings() {
    if (mounted) {
      setState(() {
        _livenessThreshold = RemoteConfigServices.livenessThreshold;
        _identifyThreshold = RemoteConfigServices.identityThreshold;
      });
    } else {
      _livenessThreshold = RemoteConfigServices.livenessThreshold;
      _identifyThreshold = RemoteConfigServices.identityThreshold;
    }
  }

  Future<void> _loadSettings() async {
    _applySettings();
    RemoteConfigServices.instance.fetchLatestConfig();
  }

  void faceRecognitionStart() {
    setState(() {
      _faces = null;
      _recognized = false;
      _identifiedName = '';
      _identifiedSimilarity = '';
      _identifiedLiveness = '';
      _identifiedYaw = '';
      _identifiedRoll = '';
      _identifiedPitch = '';
      _enrolledFace = null;
      _identifiedFace = null;
    });
    _cameraKey.currentState?.resumeCamera();
  }

  void onMatchResult(FaceSdkMatchResult result) {
    if (_recognized || !mounted) return;

    final box = result.boundingBox;
    final isMatch = result.isMatch;

    setState(() {
      _faces = [
        {
          'x1': box.left,
          'y1': box.top,
          'x2': box.right,
          'y2': box.bottom,
          'liveness': result.liveness,
          'similarity': result.similarity,
          'name': result.matchedName,
          'isMatch': isMatch,
          'frameWidth': result.frameWidth,
          'frameHeight': result.frameHeight,
        }
      ];
      _identifiedName = result.matchedName;
      _identifiedSimilarity = result.similarity.toStringAsFixed(3);
      _identifiedLiveness = result.liveness.toStringAsFixed(2);
      _identifiedYaw = result.yaw.toStringAsFixed(1);
      _identifiedRoll = result.roll.toStringAsFixed(1);
      _identifiedPitch = result.pitch.toStringAsFixed(1);
      _enrolledFace = result.enrolledFaceJpg;
      _identifiedFace = result.liveFaceJpg;
    });

    if (isMatch) {
      HapticFeedback.mediumImpact();
      setState(() {
        _recognized = true;
      });
      _cameraKey.currentState?.pauseCamera();

      // Automatically pop to complete punch verification after showing success view
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _recognized) {
          Navigator.of(context).pop(
            FaceSdkVerifyResult(
              isSuccess: true,
              faceJpg: _identifiedFace,
              matchedName: _identifiedName,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(const FaceSdkVerifyResult(isSuccess: false));
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          toolbarHeight: 65,
          title: const Text(
            'Face Recognition',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(const FaceSdkVerifyResult(isSuccess: false)),
          ),
        ),
        body: Stack(
          children: <Widget>[
            // Camera Stream View
            _FaceDetectionViewWidget(
              key: _cameraKey,
              verifyScreenState: this,
            ),

            // Real-time Bounding Box & Status Painter
            Positioned.fill(
              child: CustomPaint(
                painter: _FacePainter(
                  faces: _faces,
                  livenessThreshold: _livenessThreshold,
                  identifyThreshold: _identifyThreshold,
                ),
              ),
            ),

            // Live status pill at bottom while scanning
            if (!_recognized)
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _faces != null ? Icons.face_rounded : Icons.camera_alt_rounded,
                        color: _faces != null ? const Color(0xFF00E676) : ColorConst.themeColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _faces != null
                                  ? (_identifiedName.isNotEmpty
                                      ? 'Scanning: $_identifiedName'
                                      : 'Face Detected')
                                  : 'Look directly at camera',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (_identifiedSimilarity.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Similarity: $_identifiedSimilarity  |  Target: ${_identifyThreshold.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_faces != null)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00E676),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Verified Result Card Overlay (Exact logic and layout from reference project)
            Visibility(
              visible: _recognized,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFF121212),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Success Icon Badge
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 64),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Verified Successfully',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Side-by-side Enrolled & Identified Images
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          if (_enrolledFace != null)
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Image.memory(
                                    _enrolledFace!,
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Enrolled',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          if (_identifiedFace != null)
                            Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Image.memory(
                                    _identifiedFace!,
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Identified',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Identification Details List (from reference project)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Identified', _identifiedName),
                            const Divider(color: Colors.white12, height: 16),
                            _buildInfoRow('Similarity', _identifiedSimilarity),
                            const Divider(color: Colors.white12, height: 16),
                            _buildInfoRow('Liveness score', _identifiedLiveness),
                            const Divider(color: Colors.white12, height: 16),
                            _buildInfoRow('Yaw', _identifiedYaw),
                            const Divider(color: Colors.white12, height: 16),
                            _buildInfoRow('Roll', _identifiedRoll),
                            const Divider(color: Colors.white12, height: 16),
                            _buildInfoRow('Pitch', _identifiedPitch),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white30),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => faceRecognitionStart(),
                              child: const Text('Try again', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E676),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.of(context).pop(
                                FaceSdkVerifyResult(
                                  isSuccess: true,
                                  faceJpg: _identifiedFace,
                                  matchedName: _identifiedName,
                                ),
                              ),
                              child: const Text('Confirm & Punch', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Camera View
// ──────────────────────────────────────────────────────────────────────────────

class _FaceDetectionViewWidget extends StatefulWidget {
  final FaceSdkVerifyScreenState verifyScreenState;

  const _FaceDetectionViewWidget({super.key, required this.verifyScreenState});

  @override
  State<_FaceDetectionViewWidget> createState() => _FaceDetectionViewWidgetState();
}

class _FaceDetectionViewWidgetState extends State<_FaceDetectionViewWidget> {
  CameraController? _controller;
  CameraDescription? _frontCamera;
  bool _isProcessingFrame = false;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });

      await controller.startImageStream(_onCameraImage);
      _isStreaming = true;
    } catch (e) {
      debugPrint('[FaceSdkVerify] Camera error: $e');
    }
  }

  void pauseCamera() {
    if (_isStreaming && _controller != null && _controller!.value.isStreamingImages) {
      try {
        _controller?.stopImageStream();
        _isStreaming = false;
      } catch (e) {
        debugPrint('[FaceSdkVerify] stopImageStream error: $e');
      }
    }
  }

  void resumeCamera() {
    if (!_isStreaming && _controller != null && _controller!.value.isInitialized) {
      try {
        _controller?.startImageStream(_onCameraImage);
        _isStreaming = true;
      } catch (e) {
        debugPrint('[FaceSdkVerify] startImageStream error: $e');
      }
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_isProcessingFrame || widget.verifyScreenState._recognized || !mounted) return;
    _isProcessingFrame = true;

    try {
      if (_frontCamera == null) return;
      final result = await FaceSdkEngine.instance.processCameraFrame(
        cameraImage: image,
        camera: _frontCamera!,
        enrolledPersons: widget.verifyScreenState.widget.personList,
        threshold: widget.verifyScreenState._identifyThreshold,
      );

      if (result != null && mounted) {
        widget.verifyScreenState.onMatchResult(result);
      }
    } catch (e) {
      debugPrint('[FaceSdkVerify] processCameraFrame error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  @override
  void dispose() {
    if (_isStreaming && _controller != null) {
      try {
        _controller?.stopImageStream();
      } catch (_) {}
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Face bounding box painter (same to same layout & logic as reference FacePainter)
// ──────────────────────────────────────────────────────────────────────────────

typedef _FacePainter = FaceSdkPainter;

class FaceSdkPainter extends CustomPainter {
  final dynamic faces;
  final double livenessThreshold;
  final double identifyThreshold;

  FaceSdkPainter({
    required this.faces,
    required this.livenessThreshold,
    required this.identifyThreshold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faces == null) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final face in faces as List) {
      final double frameWidth = (face['frameWidth'] as num).toDouble();
      final double frameHeight = (face['frameHeight'] as num).toDouble();
      if (frameWidth <= 0 || frameHeight <= 0) continue;

      // Coordinate scaling matching FittedBox(fit: BoxFit.cover)
      final double scale = math.max(size.width / frameWidth, size.height / frameHeight);
      final double scaledWidth = frameWidth * scale;
      final double scaledHeight = frameHeight * scale;
      final double offsetX = (size.width - scaledWidth) / 2;
      final double offsetY = (size.height - scaledHeight) / 2;

      final double x1 = (face['x1'] as num).toDouble();
      final double y1 = (face['y1'] as num).toDouble();
      final double x2 = (face['x2'] as num).toDouble();
      final double y2 = (face['y2'] as num).toDouble();

      final double rectW = (x2 - x1) * scale;
      final double rectH = (y2 - y1) * scale;

      // Flutter's CameraPreview for the front camera is mirrored horizontally.
      // Mirror the horizontal coordinate so the bounding box moves in the exact same direction as the user's face.
      final double rectX = offsetX + (frameWidth - x2) * scale;
      final double rectY = offsetY + y1 * scale;

      final double liveness = (face['liveness'] as num?)?.toDouble() ?? 1.0;
      final double similarity = (face['similarity'] as num?)?.toDouble() ?? 0.0;
      final bool isMatch = face['isMatch'] == true;
      final String name = (face['name'] as String?) ?? '';

      String title = '';
      Color color = const Color(0xFFFF5252); // Red (Spoof)

      if (liveness < livenessThreshold) {
        color = const Color(0xFFFF5252);
        title = 'Spoof ${liveness.toStringAsFixed(2)}';
      } else if (isMatch) {
        color = const Color(0xFF00E676); // Green (Match)
        title = 'Real $name (${(similarity * 100).toStringAsFixed(0)}%)';
      } else {
        color = const Color(0xFFFFB300); // Amber (Evaluating)
        title = 'Real (${(similarity * 100).toStringAsFixed(0)}%)';
      }

      final span = TextSpan(
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
        text: ' $title ',
      );
      final tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      tp.paint(canvas, Offset(rectX, (rectY - 28).clamp(10.0, size.height - 30)));

      paint.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rectX, rectY, rectW, rectH),
          const Radius.circular(8),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
