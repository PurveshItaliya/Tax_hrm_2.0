// ignore_for_file: use_build_context_synchronously, unused_element

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/face_punch_2/face_sdk_engine.dart';
import 'package:tax_hrm/page/face_punch_2/face_sdk_verify_screen.dart';
import 'package:tax_hrm/page/face_punch_2/face_capture_view.dart';
import 'package:tax_hrm/services/remote_config_services.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

class FaceSdkEnrollScreen extends StatefulWidget {
  const FaceSdkEnrollScreen({super.key});

  @override
  State<FaceSdkEnrollScreen> createState() => _FaceSdkEnrollScreenState();
}

class _FaceSdkEnrollScreenState extends State<FaceSdkEnrollScreen> {
  List<FaceSdkPerson> _personList = [];
  bool _isLoading = false;
  String _statusMessage = 'Initializing Face Recognition SDK...';
  double _identifyThreshold = 0.70;

  @override
  void initState() {
    super.initState();
    RemoteConfigServices.configVersion.addListener(_onRemoteConfigUpdated);
    _loadSettings();
    _initSdkAndLoad();
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
        _identifyThreshold = RemoteConfigServices.identityThreshold;
      });
    } else {
      _identifyThreshold = RemoteConfigServices.identityThreshold;
    }
  }

  Future<void> _loadSettings() async {
    try {
      _applySettings();
      RemoteConfigServices.instance.fetchLatestConfig();
    } catch (_) {}
  }

  Future<void> _initSdkAndLoad() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing Face Recognition SDK...';
    });

    try {
      final ret = await FaceSdkEngine.instance.init();
      debugPrint('[FaceSdkEnroll] FaceSdkEngine initialized. Result: $ret');
      await _loadPersons();
    } catch (e) {
      debugPrint('[FaceSdkEnroll] Init error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPersons() async {
    final list = await FaceSdkDatabase.loadAll();
    if (mounted) {
      setState(() {
        _personList = list;
      });
    }
  }

  Future<void> _openLiveFaceRegistration() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceCaptureView(
          personList: _personList,
          insertPerson: (person) async {
            await FaceSdkDatabase.insertPerson(person);
          },
        ),
      ),
    );

    if (result == 'OK' || result == true) {
      await _loadPersons();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Face registered successfully!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _enrollFromSource(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 95,
      );
      if (pickedFile == null) return;

      setState(() {
        _isLoading = true;
        _statusMessage = 'Detecting and extracting facial features...';
      });

      final rotatedImage = await FlutterExifRotation.rotateImage(path: pickedFile.path);
      final faces = await FaceSdkEngine.instance.extractFaces(rotatedImage.path);

      if (faces.isEmpty) {
        if (mounted) {
          _showErrorDialog(
            title: 'No Face Detected',
            message:
                'We could not detect a clear face in the photo. Please ensure good lighting, hold the camera steady, and face forward directly.',
          );
        }
        return;
      }

      // Determine person name tied uniquely to curentUser['Id']
      String defaultName = 'Employee';
      if (curentUser != null) {
        final userId = (curentUser?['Id'] ?? '').toString().trim();
        final firstName = (curentUser?['FirstName'] ?? curentUser?['UserName'] ?? 'User').toString().trim();
        if (userId.isNotEmpty) {
          defaultName = '${userId}_$firstName';
        } else {
          defaultName = firstName;
        }
      }

      int count = 0;
      for (final face in faces) {
        final person = FaceSdkPerson(
          name: faces.length > 1 ? '$defaultName (${count + 1})' : defaultName,
          faceJpg: face['faceJpg'] as Uint8List,
          templates: face['templates'] as Uint8List,
        );
        await FaceSdkDatabase.insertPerson(person);
        count++;
      }

      await _loadPersons();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully enrolled $count face(s)!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[FaceSdkEnroll] Enroll error: $e');
      if (mounted) {
        _showErrorDialog(
          title: 'Enrollment Error',
          message: 'An error occurred during enrollment: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePerson(FaceSdkPerson person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Face'),
        content: Text('Are you sure you want to remove the enrollment for "${person.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FaceSdkDatabase.deletePerson(person.name);
      await _loadPersons();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Face removed successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Faces'),
        content: const Text(
          'Are you sure you want to delete all enrolled faces? You will need to enroll again for punch verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FaceSdkDatabase.deleteAll();
      await _loadPersons();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All enrolled faces cleared.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConst.themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Face Enrollment (SDK)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          if (_personList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              tooltip: 'Clear All',
              onPressed: _clearAll,
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorConst.themeColor,
                      ColorConst.themeColor.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConst.themeColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _personList.isEmpty
                                    ? 'No Face Enrolled'
                                    : '${_personList.length} Face(s) Enrolled',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _personList.isEmpty
                                    ? 'Enroll your face for punch verification'
                                    : 'Face recognition ready for attendance',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConst.themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.camera_alt_rounded, size: 20),
                        label: const Text(
                          'Live Camera',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: _isLoading ? null : _openLiveFaceRegistration,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConst.themeColor,
                          side: BorderSide(color: ColorConst.themeColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library_rounded, size: 20),
                        label: const Text(
                          'Gallery',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () => _enrollFromSource(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Enrolled list title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Enrolled Faces (${_personList.length})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // List of Enrolled Persons
              Expanded(
                child: _personList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No face registered yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap "Camera" or "Gallery" above to enroll.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _personList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final person = _personList[index];
                          return Card(
                            elevation: 0.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  person.faceJpg,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                person.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: const Text(
                                'Enrolled Face Template',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent),
                                tooltip: 'Delete',
                                onPressed: () => _deletePerson(person),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Test Verification Button
              if (_personList.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.verified_user_rounded),
                    label: const Text(
                      'Test Face Verification Screen',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () async {
                      final verified = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FaceSdkVerifyScreen(personList: _personList),
                        ),
                      );
                      if (mounted && verified != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              verified
                                  ? 'Face Verified Successfully!'
                                  : 'Face Verification Failed / Canceled',
                            ),
                            backgroundColor:
                                verified ? Colors.green.shade700 : Colors.red.shade600,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: ColorConst.themeColor),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _accuracyTier {
    if (_identifyThreshold < 0.70) return 'Lenient (Dim/Harsh Light)';
    if (_identifyThreshold < 0.80) return 'Balanced (Recommended)';
    if (_identifyThreshold < 0.88) return 'Strict';
    return 'Maximum';
  }

  Future<void> _showAccuracySettingsDialog() async {
    double tempThreshold = _identifyThreshold;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String accuracyLabel;
            Color accuracyColor;
            String accuracyTip;

            if (tempThreshold < 0.70) {
              accuracyLabel = 'Lenient / Dim Light (60% - 69%)';
              accuracyColor = Colors.orange.shade800;
              accuracyTip =
                  'Best if face scan fails due to bright ceiling lights, glare, or dim shadows. Fast recognition with slightly relaxed matching.';
            } else if (tempThreshold < 0.80) {
              accuracyLabel = 'Balanced / Recommended (70% - 79%)';
              accuracyColor = const Color(0xFF10B981);
              accuracyTip =
                  'Recommended for office environments with varying light conditions (lights ON vs OFF, changing window reflections).';
            } else if (tempThreshold < 0.88) {
              accuracyLabel = 'Strict (80% - 87%)';
              accuracyColor = Colors.blue.shade700;
              accuracyTip =
                  'High security matching. Requires consistent, bright and even frontal lighting without harsh reflections.';
            } else {
              accuracyLabel = 'Maximum Security (88% - 95%)';
              accuracyColor = Colors.purple.shade700;
              accuracyTip =
                  'Very strict matching. May fail if lighting angle, glasses, or facial expression differs from enrollment.';
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorConst.themeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          color: ColorConst.themeColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Face Match Accuracy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accuracyColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accuracyColor.withOpacity(0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                accuracyLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: accuracyColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accuracyColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(tempThreshold * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          accuracyTip,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade800,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Match Sensitivity',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${(tempThreshold * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: accuracyColor,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accuracyColor,
                      thumbColor: accuracyColor,
                      overlayColor: accuracyColor.withOpacity(0.2),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: tempThreshold,
                      min: 0.60,
                      max: 0.95,
                      divisions: 35,
                      onChanged: (val) {
                        setModalState(() {
                          tempThreshold = val;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '60% (Lenient)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      Text(
                        '75% (Recommended)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: ColorConst.themeColor,
                        ),
                      ),
                      Text(
                        '95% (Strict)',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quick Presets:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPresetChip('Dim / Light ON (70%)', 0.70, tempThreshold, (val) {
                        setModalState(() => tempThreshold = val);
                      }),
                      _buildPresetChip('Balanced (75%)', 0.75, tempThreshold, (val) {
                        setModalState(() => tempThreshold = val);
                      }),
                      _buildPresetChip('Standard (80%)', 0.80, tempThreshold, (val) {
                        setModalState(() => tempThreshold = val);
                      }),
                      _buildPresetChip('Strict (85%)', 0.85, tempThreshold, (val) {
                        setModalState(() => tempThreshold = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConst.themeColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'identify_threshold',
                          tempThreshold.toStringAsFixed(2),
                        );
                        if (mounted) {
                          setState(() {
                            _identifyThreshold = tempThreshold;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Recognition threshold updated to ${(tempThreshold * 100).toInt()}%',
                              ),
                              backgroundColor: Colors.green.shade700,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Save & Apply',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip(
    String label,
    double value,
    double currentVal,
    ValueChanged<double> onSelected,
  ) {
    final bool isSelected = (currentVal * 100).round() == (value * 100).round();
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? ColorConst.themeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ColorConst.themeColor : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
