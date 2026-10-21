import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/face_punch_2/face_capture_view.dart';
import 'package:tax_hrm/page/face_punch_2/face_sdk_engine.dart';
import 'package:tax_hrm/page/face_punch_2/face_sdk_verify_screen.dart';
import 'package:tax_hrm/utils/basicdata.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/api/documentapi.dart';
import 'package:tax_hrm/models/documentsclass/showdocuments.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

class FaceRegistrationSyncService {
  FaceRegistrationSyncService._();
  static final FaceRegistrationSyncService instance =
      FaceRegistrationSyncService._();

  static const String currentTemplateVersion = 'v3';

  static Future<bool>? _inFlightSync;
  static String? _inFlightUserId;

  void resetSyncState() {
    _inFlightSync = null;
    _inFlightUserId = null;
  }

  /// Checks whether [fileName] represents a valid image file/URL/format.
  /// Returns false if null, empty, whitespace, 'null', 'undefined', 'none', '0', 'false',
  /// or lacking a valid image extension / valid URL / base64 format.
  bool isValidFaceImage(String? fileName) {
    if (fileName == null) return false;
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    if (lower == 'null' ||
        lower == 'undefined' ||
        lower == 'none' ||
        lower == '0' ||
        lower == 'false' ||
        lower == 'empty') {
      return false;
    }

    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('data:image/')) {
      return true;
    }

    const validExts = ['.jpg', '.jpeg', '.png', '.webp', '.bmp'];
    return validExts.any((ext) => lower.endsWith(ext) || lower.contains('$ext?'));
  }

  /// Returns whether any enrolled person in [allPersons] matches the current user.
  /// Validates that the stored template is a genuine native FaceSDK template (>200 bytes).
  bool isUserEnrolledInList(
    List<FaceSdkPerson> allPersons,
    Map<String, dynamic>? user,
  ) {
    if (allPersons.isEmpty) return false;

    final String userId = (user?['Id'] ?? '').toString().trim();
    final String userName =
        (user?['UserName'] ?? user?['Name'] ?? '').toString().trim().toLowerCase();

    final hasUserMatch = allPersons.any((p) {
      final pName = p.name.trim().toLowerCase();
      if (pName == 'employee') return false;

      final bool matchesUser = (userId.isNotEmpty &&
              (pName == userId ||
                  pName.startsWith('${userId}_') ||
                  pName.contains(userId))) ||
          (userName.isNotEmpty &&
              (pName == userName || pName.startsWith('${userName}_')));

      final bool hasValidTemplate = p.templates.isNotEmpty && p.templates.length >= 200;

      return matchesUser && hasValidTemplate;
    });

    if (hasUserMatch) return true;

    // Fallback: If exactly 1 person is enrolled on this device with valid templates
    if (allPersons.length == 1) {
      final p = allPersons.first;
      final pName = p.name.trim().toLowerCase();
      if (pName != 'employee' && p.templates.isNotEmpty && p.templates.length >= 200) {
        return true;
      }
    }

    return false;
  }

  /// Checks if current user has face templates saved locally in SQLite DB.
  Future<bool> isFaceEnrolledLocally() async {
    try {
      final allPersons = await FaceSdkDatabase.loadAll();
      return isUserEnrolledInList(allPersons, curentUser);
    } catch (_) {
      return false;
    }
  }

  /// Master method to check face availability and manage face enrollment:
  /// - Checks local SQLite database FIRST (Offline First & Instant UI).
  /// - If already enrolled locally: returns true immediately without hitting server.
  /// - If not enrolled locally: checks if valid face image exists on server (via GetEmpListById or Document API, NEVER EmpLogin).
  ///   - If image is null, empty, or invalid format: returns false (triggers face registration prompt).
  ///   - If valid image exists: downloads once, enrolls into local SQLite, and caches locally.
  /// - If network / API error occurs: falls back to local SQLite enrollment (never shows registration if enrolled locally).
  Future<bool> checkFaceAvailabilityAndSync({
    String? faceRegisterImgHint,
    bool forceServerCheck = false,
  }) async {
    if (curentUser == null) return false;
    final String userId = (curentUser?['Id'] ?? '').toString().trim();
    if (userId.isEmpty) return false;

    // 1. FAST PATH: Check local SQLite enrollment FIRST (Offline First & Instant UI)
    final bool locallyEnrolled = await isFaceEnrolledLocally();
    if (locallyEnrolled && !forceServerCheck) {
      debugPrint('[FaceRegistrationSyncService] User $userId is already enrolled locally in SQLite.');
      return true;
    }

    final String firstName = (curentUser?['FirstName'] ??
            curentUser?['UserName'] ??
            curentUser?['Name'] ??
            'User')
        .toString()
        .trim();
    final String userTag = '${userId}_$firstName';

    if (_inFlightSync != null && _inFlightUserId == userId && !forceServerCheck) {
      debugPrint('[FaceRegistrationSyncService] Sync already in-flight for user $userId, awaiting...');
      return await _inFlightSync!;
    }
    final future = _executeFaceSync(
      userId: userId,
      userTag: userTag,
      faceRegisterImgHint: faceRegisterImgHint,
      forceServerCheck: forceServerCheck,
    );
    _inFlightSync = future;
    _inFlightUserId = userId;

    try {
      return await future;
    } finally {
      if (_inFlightUserId == userId) {
        _inFlightSync = null;
        _inFlightUserId = null;
      }
    }
  }

  Future<bool> _executeFaceSync({
    required String userId,
    required String userTag,
    String? faceRegisterImgHint,
    bool forceServerCheck = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool locallyEnrolled = await isFaceEnrolledLocally();
      String? faceImg = faceRegisterImgHint;

      // 1. Check in-memory curentUser (check FileName as returned by profile/EmpLogin)
      if (faceImg == null || faceImg.trim().isEmpty) {
        faceImg = curentUser?['FileName']?.toString() ??
            curentUser?['filename']?.toString() ??
            curentUser?['Filename']?.toString() ??
            curentUser?['FaceRegisterImg']?.toString() ??
            curentUser?['faceRegisterImg']?.toString();
      }

      // Check SharedPreferences cache
      if (faceImg == null || faceImg.trim().isEmpty) {
        faceImg = prefs.getString('cached_face_register_img_$userId');
      }

      // 2. Fetch directly from Server ONLY if needed (NO EmpLogin! Only GetEmpListById or Document API)
      if (forceServerCheck || faceImg == null || !isValidFaceImage(faceImg)) {
        // 2a. Check Employee Master API: /api/Master/GetEmpListById
        try {
          final url =
              Uri.parse('$apibaseurl/api/Master/GetEmpListById?Id=$userId');
          final token = curentUser?['token'] ?? '';
          final resp = await http.get(
            url,
            headers: {
              if (token.toString().isNotEmpty) 'Authorization': 'bearer $token',
            },
          ).timeout(const Duration(seconds: 8));

          if (resp.statusCode == 200 && resp.body.isNotEmpty) {
            final dynamic decoded = jsonDecode(resp.body);
            if (decoded is Map) {
              faceImg = decoded['FileName']?.toString() ??
                  decoded['filename']?.toString() ??
                  decoded['Filename']?.toString() ??
                  decoded['FaceRegisterImg']?.toString() ??
                  decoded['faceRegisterImg']?.toString() ??
                  decoded['FaceRegisterImage']?.toString();
            } else if (decoded is List &&
                decoded.isNotEmpty &&
                decoded.first is Map) {
              faceImg = decoded.first['FileName']?.toString() ??
                  decoded.first['filename']?.toString() ??
                  decoded.first['FaceRegisterImg']?.toString() ??
                  decoded.first['faceRegisterImg']?.toString();
            }
          }
        } catch (e) {
          debugPrint('[FaceRegistrationSyncService] GetEmpListById error: $e');
        }

        // 2b. If still invalid, check Document API: /api/Master/EmpGetFileList
        if (faceImg == null || !isValidFaceImage(faceImg)) {
          try {
            final docList = await DocumentApis().getDocuments();
            if (docList is List<DocumentViews>) {
              final faceDoc = docList.firstWhere(
                (d) =>
                    (d.category?.toLowerCase() == 'facereg' ||
                        d.filename?.toLowerCase().contains('face_reg') == true) &&
                    (d.filename?.isNotEmpty == true),
                orElse: () => DocumentViews(),
              );
              if (faceDoc.filename != null && faceDoc.filename!.isNotEmpty) {
                faceImg = faceDoc.filename;
                debugPrint(
                  '[FaceRegistrationSyncService] Found face image in EmpGetFileList: $faceImg',
                );
              }
            }
          } catch (e) {
            debugPrint('[FaceRegistrationSyncService] EmpGetFileList error: $e');
          }
        }
      }

      // Fallback: SharedPreferences cache if network was offline
      if (faceImg == null || !isValidFaceImage(faceImg)) {
        faceImg = prefs.getString('cached_face_register_img_$userId');
      }

      // 3. VALIDATION: Check if face image is null, empty, or invalid format:
      if (!isValidFaceImage(faceImg)) {
        if (locallyEnrolled) {
          debugPrint(
            '[FaceRegistrationSyncService] Preserving locally enrolled face templates in SQLite for user $userId (image format is $faceImg)',
          );
          return true;
        }

        debugPrint(
          '[FaceRegistrationSyncService] Face image is NOT available or invalid format ($faceImg) and no local SQLite enrollment for user $userId',
        );
        return false;
      }

      // 4. FACE IMAGE IS VALID:
      final String trimmedImg = faceImg!.trim();
      final String? cachedImg =
          prefs.getString('cached_face_register_img_$userId');

      final String base =
          apibaseurl.endsWith('/') ? apibaseurl : '$apibaseurl/';
      String cleanPath = trimmedImg;
      if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
      final String simpleFileName = cleanPath.split('/').last.split(r'\').last;
      final String primaryCompareUrl = '${base}HRM/Uploads/$userId/$simpleFileName';

      debugPrint('=================================================================');
      debugPrint('[FaceRegistrationSyncService] ================= COMPARE IMAGE FULL URL =================');
      debugPrint('[FaceRegistrationSyncService] User ID: $userId');
      debugPrint('[FaceRegistrationSyncService] Name: ${curentUser?['UserName']} / ${curentUser?['FirstName']}');
      debugPrint('[FaceRegistrationSyncService] Enrolled File Name: $simpleFileName');
      debugPrint('[FaceRegistrationSyncService] FULL COMPARE IMAGE URL: $primaryCompareUrl');
      debugPrint('=================================================================');

      // Fast path: If already locally enrolled, preserve local templates and avoid re-download
      if (locallyEnrolled && (cachedImg == trimmedImg || cachedImg == simpleFileName || !forceServerCheck)) {
        debugPrint(
          '[FaceRegistrationSyncService] Face is already enrolled locally in SQLite for user $userId (file=$trimmedImg)',
        );
        if (curentUser != null) {
          curentUser!['FaceRegisterImg'] = trimmedImg;
          curentUser!['FileName'] = trimmedImg;
        }
        await prefs.setString('cached_face_register_img_$userId', simpleFileName);
        return true;
      }

      // 5. Download image from server, extract facial templates, and store in SQLite
      final token = curentUser?['token'] ?? '';
      final headers = {
        if (token.toString().isNotEmpty) 'Authorization': 'bearer $token',
      };

      final companyId = curentUser?['CompanyId']?.toString() ?? '';

      List<String> candidateUrls = [];
      if (trimmedImg.startsWith('http://') || trimmedImg.startsWith('https://')) {
        candidateUrls.add(trimmedImg);
      } else {
        // TOP PRIORITY 1: Exact URL provided and verified on server:
        // https://taxcrmtesting.taxfile.co.in/HRM/Uploads/{$userId}/$simpleFileName
        if (userId.isNotEmpty) {
          candidateUrls.add(primaryCompareUrl);
          candidateUrls.add('${base}hrm/uploads/$userId/$simpleFileName');
          if (cleanPath != simpleFileName) {
            candidateUrls.add('${base}HRM/Uploads/$userId/$cleanPath');
            candidateUrls.add(Uri.parse(apibaseurl).resolve(cleanPath).toString());
          }
        }

        // First: Check Document API for the exact server FilePath for this filename
        try {
          final docList = await DocumentApis().getDocuments();
          if (docList is List<DocumentViews>) {
            for (final doc in docList) {
              if (doc.filename != null && doc.filename!.isNotEmpty) {
                final dName = doc.filename!.toLowerCase();
                final tName = cleanPath.toLowerCase();
                if (dName == tName ||
                    dName.contains('face_reg') ||
                    doc.category?.toLowerCase() == 'facereg') {
                  final serverPath = doc.filePath ?? '';
                  if (serverPath.isNotEmpty) {
                    final fullUrl = serverPath.endsWith('/')
                        ? '$serverPath${doc.filename}'
                        : '$serverPath/${doc.filename}';
                    candidateUrls.add(fullUrl);
                    debugPrint(
                      '[FaceRegistrationSyncService] Found server FilePath from EmpGetFileList: $fullUrl',
                    );
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint(
            '[FaceRegistrationSyncService] EmpGetFileList search error: $e',
          );
        }

        if (cleanPath.startsWith('UploadFiles/')) {
          candidateUrls.add(Uri.parse(apibaseurl).resolve(cleanPath).toString());
          final sub = cleanPath.replaceFirst('UploadFiles/', '');
          candidateUrls.add(
            Uri.parse(apibaseurl).resolve('UploadFiles/Emp/$sub').toString(),
          );
          candidateUrls.add(
            Uri.parse(apibaseurl).resolve('UploadFiles/faceReg/$sub').toString(),
          );
          candidateUrls.add(
            Uri.parse(apibaseurl).resolve('UploadFiles/FaceReg/$sub').toString(),
          );
        } else {
          // Standard upload folders
          candidateUrls.add(
            Uri.parse(apibaseurl).resolve('UploadFiles/Emp/$cleanPath').toString(),
          );
          candidateUrls.add(
            Uri.parse(apibaseurl)
                .resolve('UploadFiles/faceReg/$cleanPath')
                .toString(),
          );
          candidateUrls.add(
            Uri.parse(apibaseurl)
                .resolve('UploadFiles/FaceReg/$cleanPath')
                .toString(),
          );
          candidateUrls.add(
            Uri.parse(apibaseurl).resolve('UploadFiles/$cleanPath').toString(),
          );

          // Company & User specific subdirectories
          if (companyId.isNotEmpty && userId.isNotEmpty) {
            candidateUrls.add(
              Uri.parse(apibaseurl)
                  .resolve('UploadFiles/Emp/$companyId/$userId/$cleanPath')
                  .toString(),
            );
            candidateUrls.add(
              Uri.parse(apibaseurl)
                  .resolve('UploadFiles/faceReg/$companyId/$userId/$cleanPath')
                  .toString(),
            );
            candidateUrls.add(
              Uri.parse(apibaseurl)
                  .resolve('UploadFiles/$companyId/$userId/$cleanPath')
                  .toString(),
            );
          }
          if (userId.isNotEmpty) {
            candidateUrls.add(
              Uri.parse(apibaseurl)
                  .resolve('UploadFiles/Emp/$userId/$cleanPath')
                  .toString(),
            );
            candidateUrls.add(
              Uri.parse(apibaseurl)
                  .resolve('UploadFiles/faceReg/$userId/$cleanPath')
                  .toString(),
            );
          }
        }
      }

      // Deduplicate candidate URLs while preserving order
      candidateUrls = candidateUrls.toSet().toList();

      http.Response? successfulResponse;
      String? successfulDownloadUrl;
      for (final url in candidateUrls) {
        try {
          debugPrint(
            '[FaceRegistrationSyncService] Trying download from: $url',
          );
          http.Response resp = await http
              .get(Uri.parse(url), headers: headers)
              .timeout(const Duration(seconds: 8));

          // If IIS or server returned 401/403 or non-200 with headers, retry immediately without headers
          if (resp.statusCode != 200 && headers.isNotEmpty) {
            debugPrint(
              '[FaceRegistrationSyncService] Retrying without headers for: $url (was status ${resp.statusCode})',
            );
            resp = await http
                .get(Uri.parse(url))
                .timeout(const Duration(seconds: 8));
          }

          if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
            successfulResponse = resp;
            successfulDownloadUrl = url;
            debugPrint('=================================================================');
            debugPrint(
              '[FaceRegistrationSyncService] Successfully downloaded face compare image from: $url (${resp.bodyBytes.length} bytes)',
            );
            debugPrint('=================================================================');
            break;
          } else {
            debugPrint(
              '[FaceRegistrationSyncService] Status ${resp.statusCode} for $url',
            );
          }
        } catch (e) {
          debugPrint('[FaceRegistrationSyncService] Download attempt error: $e');
        }
      }

      if (successfulResponse == null || successfulResponse.bodyBytes.isEmpty) {
        debugPrint(
          '[FaceRegistrationSyncService] All download attempts failed for $trimmedImg',
        );

        // Fallback: If FaceRegisterId has base64 template stored in curentUser, use it directly!
        final templateB64 = curentUser?['FaceRegisterId']?.toString() ?? '';
        if (templateB64.isNotEmpty && templateB64.length > 200) {
          try {
            final templateBytes = base64Decode(templateB64);
            if (templateBytes.length >= 768) {
              final person = FaceSdkPerson(
                name: userTag,
                faceJpg: Uint8List(0),
                templates: templateBytes,
              );
              await FaceSdkDatabase.deleteUserTemplates(userId);
              await FaceSdkDatabase.deletePerson(userTag);
              await FaceSdkDatabase.insertPerson(person);
              await prefs.setString('cached_face_register_img_$userId', trimmedImg);
              debugPrint(
                '[FaceRegistrationSyncService] Restored facial template from curentUser FaceRegisterId base64!',
              );
              return true;
            }
          } catch (e) {
            debugPrint('[FaceRegistrationSyncService] Error decoding template: $e');
          }
        }

        return locallyEnrolled;
      }

            final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/face_sync_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(successfulResponse.bodyBytes);

      try {
        await FaceSdkEngine.instance.init();

        // Ensure correct EXIF orientation is applied before face feature extraction
        String imagePathToExtract = tempFile.path;
        try {
          final rotatedImage = await FlutterExifRotation.rotateImage(path: tempFile.path);
          imagePathToExtract = rotatedImage.path;
          debugPrint('[FaceRegistrationSyncService] Applied EXIF rotation: $imagePathToExtract');
        } catch (e) {
          debugPrint('[FaceRegistrationSyncService] FlutterExifRotation note: $e');
        }

        final faces = await FaceSdkEngine.instance.extractFaces(imagePathToExtract);
        Uint8List templates;
        Uint8List faceJpg;

        if (faces.isNotEmpty) {
          final face = faces.first;
          templates = face['templates'] as Uint8List;
          faceJpg = face['faceJpg'] as Uint8List;
        } else {
          debugPrint(
            '[FaceRegistrationSyncService] 0 faces detected in downloaded image ($trimmedImg). Checking curentUser FaceRegisterId base64...',
          );
          final templateB64 = curentUser?['FaceRegisterId']?.toString() ?? '';
          if (templateB64.isNotEmpty && templateB64.length > 200) {
            try {
              final templateBytes = base64Decode(templateB64);
              if (templateBytes.length >= 768) {
                templates = templateBytes;
                faceJpg = successfulResponse.bodyBytes;
                debugPrint(
                  '[FaceRegistrationSyncService] ✅ Recovered valid 768B template from curentUser FaceRegisterId base64!',
                );
              } else {
                return locallyEnrolled;
              }
            } catch (e) {
              debugPrint('[FaceRegistrationSyncService] Error decoding FaceRegisterId base64: $e');
              return locallyEnrolled;
            }
          } else {
            return locallyEnrolled;
          }
        }

        debugPrint('=================================================================');
        debugPrint('[FaceRegistrationSyncService] Extracted Face Info:');
        debugPrint('[FaceRegistrationSyncService]   - User Tag: $userTag');
        debugPrint('[FaceRegistrationSyncService]   - Template size: ${templates.length} bytes');
        debugPrint('[FaceRegistrationSyncService]   - Thumbnail JPG size: ${faceJpg.length} bytes');
        debugPrint('=================================================================');

        final person = FaceSdkPerson(
          name: userTag,
          faceJpg: faceJpg,
          templates: templates,
        );

        await FaceSdkDatabase.deleteUserTemplates(userId);
        await FaceSdkDatabase.deletePerson(userTag);
        await FaceSdkDatabase.deletePerson(userId);

        await FaceSdkDatabase.insertPerson(person);
        await prefs.setString('cached_face_register_img_$userId', trimmedImg);
        await prefs.setString('face_template_version_$userId', currentTemplateVersion);
        if (curentUser != null) {
          curentUser!['FaceRegisterImg'] = trimmedImg;
          curentUser!['FileName'] = trimmedImg;
          await SaveUser().saveUserData(jsonEncode(curentUser));
        }

        debugPrint('=================================================================');
        debugPrint(
          '[FaceRegistrationSyncService] Successfully enrolled face locally from server image ($trimmedImg)!',
        );
        debugPrint('[FaceRegistrationSyncService] Download Source URL: $successfulDownloadUrl');
        debugPrint('=================================================================');
        return true;
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    } catch (e) {
      debugPrint('[FaceRegistrationSyncService] checkFaceAvailability error: $e');
      return await isFaceEnrolledLocally();
    }
  }

  /// Backward-compatible alias for checkFaceAvailabilityAndSync
  Future<bool> syncFaceFromEmployeeMaster({String? faceRegisterImgHint}) async {
    return checkFaceAvailabilityAndSync(
      faceRegisterImgHint: faceRegisterImgHint,
    );
  }

  /// Opens the live FaceCaptureView to register face.
  Future<bool> openFaceRegistrationScreen(BuildContext context) async {
    final allPersons = await FaceSdkDatabase.loadAll();
    if (!context.mounted) return false;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FaceCaptureView(
          personList: allPersons,
          insertPerson: (person) async {
            await FaceSdkDatabase.insertPerson(person);
          },
        ),
      ),
    );

    return result == 'OK' || result == true;
  }

  /// Global flag indicating if the face registration required dialog is currently active.
  static bool isDialogShowing = false;

  /// Shows prompt dialog to ask the user to register their face.
  Future<bool> showFaceRegistrationRequiredDialog(BuildContext context) async {
    if (isDialogShowing || !context.mounted) return false;
    isDialogShowing = true;
    bool? registered = false;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorConst.themeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.face_retouching_natural_rounded,
                    color: ColorConst.themeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Face Registration",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: const Text(
              "Your face is not registered yet. Please register your face to continue with attendance punch.",
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  cancelString,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConst.themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx, true);
                  registered = await openFaceRegistrationScreen(context);
                },
                child: const Text(
                  "Register Face",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      isDialogShowing = false;
    }

    return registered ?? false;
  }
}
