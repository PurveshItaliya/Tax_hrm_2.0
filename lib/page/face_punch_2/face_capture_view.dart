// ignore_for_file: constant_identifier_names, unused_field, must_be_immutable, duplicate_ignore, library_private_types_in_public_api, strict_top_level_inference, curly_braces_in_flow_control_structures, empty_catches

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facesdk_plugin/facedetection_interface.dart';
import 'package:facesdk_plugin/facesdk_plugin.dart';
import 'package:tax_hrm/page/face_punch_2/face_sdk_engine.dart';
import 'package:tax_hrm/page/face_punch_2/face_sdk_verify_screen.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tax_hrm/api/documentapi.dart';
import 'package:tax_hrm/api/employeapi.dart';
import 'package:tax_hrm/api/authapi.dart';
import 'package:tax_hrm/models/authclass/emploginclass.dart';
import 'package:tax_hrm/services/face_registration_sync_service.dart';
import 'package:tax_hrm/services/remote_config_services.dart';
import 'package:tax_hrm/utils/basicdata.dart';

typedef Person = FaceSdkPerson;

enum ViewMode {
  MODE_NONE,
  NO_FACE_PREPARE,
  REPEAT_NO_FACE_PREPARE,
  TO_FACE_CIRCLE,
  FACE_CIRCLE_TO_NO_FACE,
  FACE_CIRCLE,
  FACE_CAPTURE_PREPARE,
  FACE_CAPTURE_DONE,
  FACE_CAPTURE_FINISHED
}

enum FaceCaptureState {
  NO_FACE,
  MULTIPLE_FACES,
  FIT_IN_CIRCLE,
  MOVE_CLOSER,
  NO_FRONT,
  FACE_OCCLUDED,
  EYE_CLOSED,
  MOUTH_OPENED,
  SPOOFED_FACE,
  CAPTURE_OK
}

const double DEFAULT_YAW_THRESHOLD = 20.0;
const double DEFAULT_ROLL_THRESHOLD = 18.0;
const double DEFAULT_PITCH_THRESHOLD = 18.0;
const double DEFAULT_OCCLUSION_THRESHOLD = 0.5;
const double DEFAULT_EYECLOSE_THRESHOLD = 0.65;
const double DEFAULT_MOUTHOPEN_THRESHOLD = 0.5;

Float32List byteArrayToFloatArray(Uint8List byteArray) {
   // Create a Float32List with half the length of the byteArray
   Float32List floatArray = Float32List(byteArray.length ~/ Float32List.bytesPerElement);

   // Iterate over the byteArray and convert each pair of bytes to a float value
   for (int i = 0; i < byteArray.length; i += Float32List.bytesPerElement) {
     // Convert bytes to a 32-bit floating point value
     floatArray[i ~/ Float32List.bytesPerElement] = byteArray.buffer.asFloat32List()[i ~/ Float32List.bytesPerElement];
   }

   return floatArray;
}

Rect getROIRect(Size frameSize) {
  double margin = frameSize.width / 6;
  double rectHeight = (frameSize.width - 2 * margin) * 6 / 5;

  return Rect.fromLTRB(
      margin,
      (frameSize.height - rectHeight) / 2,
      frameSize.width - margin,
      (frameSize.height - rectHeight) / 2 + rectHeight);
}

Rect getROIRect1(Size frameSize) {
  // Define margin and height
  double margin = frameSize.width / 6;
  double rectHeight = frameSize.width - 2 * margin;

  // Create the ROI rectangle
  Rect roiRect = Rect.fromLTRB(
      margin, // left
      (frameSize.height - rectHeight) / 2, // top
      frameSize.width - margin, // right
      (frameSize.height - rectHeight) / 2 + rectHeight // bottom
      );

  return roiRect;
}

Rect scale(Rect rect, double factor) {
  double diffHorizontal = (rect.right - rect.left) * (factor - 1);
  double diffVertical = (rect.bottom - rect.top) * (factor - 1);

  return Rect.fromLTRB(
    rect.left - diffHorizontal / 2,
    rect.top - diffVertical / 2,
    rect.right + diffHorizontal / 2,
    rect.bottom + diffVertical / 2,
  );
}

// ignore: must_be_immutable
class FaceCaptureView extends StatefulWidget {
  final List<Person> personList;
  FaceDetectionViewController? faceDetectionViewController;
  final Function(Person) insertPerson;

  FaceCaptureView(
      {super.key, required this.personList, required this.insertPerson});

  @override
  State<StatefulWidget> createState() => FaceCaptureViewState();
}

class FaceCaptureViewState extends State<FaceCaptureView> {
  dynamic _faces;
  dynamic _currentFace;
  dynamic _capturedFace;
  dynamic _capturedImage;
  double _livenessThreshold = 0;
  double _identifyThreshold = 0;
  bool _recognized = false;

  String _warningTxt = "";
  ViewMode _viewMode = ViewMode.MODE_NONE;

  // ignore: prefer_typing_uninitialized_variables
  var _identifiedFace;
  // ignore: prefer_typing_uninitialized_variables
  var _enrolledFace;
  final _facesdkPlugin = FacesdkPlugin();
  FaceDetectionViewController? faceDetectionViewController;
  VoidCallback? onNativeStopCamera;
  Future<void> Function()? onNativeRestartCamera;
  bool _isSaving = false;
  int _sessionKey = 0;
  bool _showInstructions = false;
  int _stableFrames = 0;
  int _noFaceCounter = 0;

  void rescanFace() {
    setState(() {
      _sessionKey++;
      _warningTxt = "";
      _faces = null;
      _currentFace = null;
      _capturedFace = null;
      _capturedImage = null;
      _recognized = false;
      _isSaving = false;
      _stableFrames = 0;
      _noFaceCounter = 0;
      _showInstructions = false;
      _viewMode = ViewMode.FACE_CIRCLE;
    });
    onNativeRestartCamera?.call();
  }

  @override
  void initState() {
    super.initState();
    RemoteConfigServices.configVersion.addListener(_onRemoteConfigUpdated);
    loadSettings();

    setState(() {
      _viewMode = ViewMode.FACE_CIRCLE;
    });
  }

  @override
  void dispose() {
    RemoteConfigServices.configVersion.removeListener(_onRemoteConfigUpdated);
    super.dispose();
  }

  void _onRemoteConfigUpdated() {
    if (!mounted) return;
    loadSettings();
  }

  void setViewMode(ViewMode viewMode) {
    setState(() {
      _viewMode = viewMode;
    });

    if (viewMode == ViewMode.FACE_CAPTURE_DONE) {
      faceDetectionViewController?.stopCamera();
      // Keep native camera stream active so Re-scan can resume instantly without camera restarts
    }
  }

  Future<void> loadSettings() async {
    if (mounted) {
      setState(() {
        _livenessThreshold = RemoteConfigServices.livenessThreshold;
        _identifyThreshold = RemoteConfigServices.identityThreshold;
      });
    } else {
      _livenessThreshold = RemoteConfigServices.livenessThreshold;
      _identifyThreshold = RemoteConfigServices.identityThreshold;
    }
    RemoteConfigServices.instance.fetchLatestConfig();
  }

  Future<void> registerFace(BuildContext context) async {
    if (_isSaving) return;
    if (_capturedFace == null || _capturedFace['faceJpg'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture your face before saving.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String personName = 'Employee';
    if (curentUser != null) {
      final userId = (curentUser?['Id'] ?? '').toString().trim();
      final firstName = (curentUser?['FirstName'] ??
              curentUser?['UserName'] ??
              'User')
          .toString()
          .trim();
      if (userId.isNotEmpty) {
        personName = '${userId}_$firstName';
      } else {
        personName = firstName;
      }
    } else {
      num randomNumber = 10000 + Random().nextInt(10000);
      personName = 'Person$randomNumber';
    }

    final person = FaceSdkPerson(
      name: personName,
      faceJpg: _capturedFace['faceJpg'],
      templates: _capturedFace['templates'],
    );

    // Clean up any stale records for this user to ensure fresh re-registration
    final String currentUserId = curentUser?['Id']?.toString().trim() ?? '';
    if (currentUserId.isNotEmpty) {
      try {
        await FaceSdkDatabase.deleteUserTemplates(currentUserId);
        final db = await FaceSdkDatabase.open();
        await db.delete(
          'person',
          where: 'name = ? OR name LIKE ? OR name = ?',
          whereArgs: [personName, '${currentUserId}_%', 'Employee'],
        );
      } catch (_) {}
    }

    await widget.insertPerson(person);

    String? uploadedImgName;

    // Upload single face registration image to api/Master/EmpFileUploads with category "faceRegisterImg"
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/face_reg_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(person.faceJpg);

      final uploadRes = await DocumentApis().uploadFaceRegisterImage(file: tempFile);
      debugPrint('[FaceCaptureView] uploadFaceRegisterImage response: $uploadRes');

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (uploadRes is Map) {
        uploadedImgName = uploadRes['Filename']?.toString() ??
            uploadRes['FileName']?.toString() ??
            uploadRes['Data']?.toString() ??
            uploadRes['data']?.toString();
      } else if (uploadRes is String) {
        uploadedImgName = uploadRes;
      }

      final userId = curentUser?['Id']?.toString() ?? '';
      if (userId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        if (uploadedImgName != null && uploadedImgName.isNotEmpty) {
          final String cleanName = uploadedImgName.split('/').last.split(r'\').last;
          await prefs.setString('cached_face_register_img_$userId', cleanName);
          if (curentUser != null) {
            curentUser!['FaceRegisterImg'] = cleanName;
            curentUser!['FileName'] = cleanName;
          }

          final String base = apibaseurl.endsWith('/') ? apibaseurl : '$apibaseurl/';
          final String fullCompareUrl = '${base}HRM/Uploads/$userId/$cleanName';
          debugPrint('=================================================================');
          debugPrint('[FaceCaptureView] ================= REGISTERED COMPARE IMAGE FULL URL =================');
          debugPrint('[FaceCaptureView] User ID: $userId');
          debugPrint('[FaceCaptureView] File Name: $cleanName');
          debugPrint('[FaceCaptureView] FULL COMPARE IMAGE URL: $fullCompareUrl');
          debugPrint('=================================================================');
        }
      }
    } catch (e) {
      debugPrint('[FaceCaptureView] uploadFaceRegisterImage error: $e');
    }

    // Save to user profile & backend sync
    // try {
    //   final templateBase64 = base64Encode(person.templates);
    //   if (curentUser != null) {
    //     curentUser!['FaceRegisterId'] = templateBase64;
    //     final String freshJson = jsonEncode(curentUser);
    //     await SaveUser().saveUserData(freshJson);
    //   }
    //
    //   final empId = curentUser?['Id']?.toString() ?? '';
    //   if (empId.isNotEmpty) {
    //     await Employeeclass().updateEmployes(
    //       seteid: empId,
    //       firstname: curentUser?['FirstName'] ?? '',
    //       lastname: curentUser?['LastName'] ?? '',
    //       mobile1: curentUser?['Mobile1'] ?? '',
    //       mobile2: curentUser?['Mobile2'] ?? '',
    //       address1: curentUser?['Add1'] ?? '',
    //       address2: curentUser?['Add2'] ?? '',
    //       address3: curentUser?['Add3'] ?? '',
    //       dob: curentUser?['DOB'] ?? '',
    //       doj: curentUser?['DOJ'] ?? '',
    //       pincode: curentUser?['PincodeId'] ?? '',
    //       cityid: curentUser?['CityId'] ?? '',
    //       statid: curentUser?['StateId'] ?? '',
    //       email: curentUser?['Email'] ?? '',
    //       gender: curentUser?['Gender'] ?? '',
    //       pan: curentUser?['PAN'] ?? '',
    //       marstatus: curentUser?['MaritalStatus'] ?? '',
    //       bankname: curentUser?['BankName'] ?? '',
    //       branchname: curentUser?['BranchName'] ?? '',
    //       accno: curentUser?['AccNo'] ?? '',
    //       accountType: curentUser?['AccType'] ?? '',
    //       salary: curentUser?['SalaryType'] ?? '',
    //       salaryamount: curentUser?['SalaryAmount']?.toString() ?? '',
    //       totalhours: curentUser?['Totalhours']?.toString() ?? '',
    //       username: curentUser?['UserName'] ?? '',
    //       password: curentUser?['Password'] ?? '',
    //       highestDegree: curentUser?['HighestDegree'] ?? '',
    //       degreeName: curentUser?['DegreeName'] ?? '',
    //       universityName: curentUser?['UniversityName'] ?? '',
    //       passingYear: curentUser?['PassingYear'] ?? '',
    //       uanNo: curentUser?['UANNo'] ?? '',
    //       esicNo: curentUser?['ESICNo'] ?? '',
    //       selectedDepartment: curentUser?['DepartmentId'] ?? '',
    //       selectedposition: curentUser?['PositionId'] ?? '',
    //       roletypes: curentUser?['Role'] ?? '',
    //       selectedifsc: curentUser?['IFSC'] ?? '',
    //       userStatus: curentUser?['IsActive'] ?? true,
    //       workType: curentUser?['WorkType'] ?? '',
    //       officeLocation: curentUser?['OfficeLocation'] ?? '',
    //       locationRadius: curentUser?['LocationRadius'] ?? '50',
    //       isFetchLocation: curentUser?['IsFetchLocation'] ?? false,
    //       setCguids: curentUser?['Cguid'] ?? '',
    //       faceRegisterId: templateBase64,
    //       faceRegisterImg: uploadedImgName ?? '',
    //       removeImage: false,
    //       listenRes: (_) {},
    //     );
    //
    //     // 1-TIME EmpLogin call immediately after face registration to fetch latest user details & image from server
    //     final String username =
    //         (curentUser?['UserName'] ?? curentUser?['Username'] ?? '')
    //             .toString()
    //             .trim();
    //     final String password =
    //         (curentUser?['Password'] ?? curentUser?['password'] ?? '')
    //             .toString()
    //             .trim();
    //     if (username.isNotEmpty && password.isNotEmpty) {
    //       try {
    //         final loginVal =
    //             await AuthLoginService().callEmployeLogin(username, password);
    //         if (loginVal is EmpUserLogin && loginVal.success != false) {
    //           final String freshJson = jsonEncode(loginVal.toJson());
    //           await SaveUser().saveUserData(freshJson);
    //           curentUser = jsonDecode(freshJson);
    //           final String? freshFileName =
    //               loginVal.fileName ?? loginVal.faceRegisterImg;
    //           if (freshFileName != null && freshFileName.trim().isNotEmpty) {
    //             final clean =
    //                 freshFileName.trim().split('/').last.split(r'\').last;
    //             final prefs = await SharedPreferences.getInstance();
    //             await prefs.setString('cached_face_register_img_$empId', clean);
    //           }
    //         }
    //       } catch (e) {
    //         debugPrint(
    //           '[FaceCaptureView] Post-registration 1-time EmpLogin refresh error: $e',
    //         );
    //       }
    //     }
    //
    //     // Save persistent local copy of face image in app documents directory for offline resilience
    //     try {
    //       final appDir = await getApplicationDocumentsDirectory();
    //       final localFaceFile = File('${appDir.path}/face_reg_$empId.jpg');
    //       await localFaceFile.writeAsBytes(person.faceJpg);
    //       debugPrint(
    //         '[FaceCaptureView] Saved offline face image to ${localFaceFile.path}',
    //       );
    //     } catch (e) {
    //       debugPrint(
    //         '[FaceCaptureView] Error saving local offline face image: $e',
    //       );
    //     }
    //
    //     final prefs = await SharedPreferences.getInstance();
    //     await prefs.setString(
    //       'face_template_version_$empId',
    //       FaceRegistrationSyncService.currentTemplateVersion,
    //     );
    //   }
    // } catch (_) {}

      if (context.mounted) {
        Navigator.pop(context, 'OK');
      }
    } catch (e) {
      debugPrint('[FaceCaptureView] registerFace error: $e');
      if (context.mounted) {
        Navigator.pop(context, 'OK');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> evaluateAndTrackFaces(List<Map<String, dynamic>> faces) async {
    if (_recognized == true || _capturedFace != null) {
      return false;
    }

    if (!mounted) return false;

    setState(() {
      _faces = faces;
    });

    if (faces.isNotEmpty) {
      setState(() {
        _currentFace = faces[0];
      });
    }

    FaceCaptureState faceCaptureState = checkFace(faces);

    // If starting in NO_FACE_PREPARE or REPEAT, advance to FACE_CIRCLE immediately when face seen
    if (_viewMode == ViewMode.NO_FACE_PREPARE || _viewMode == ViewMode.REPEAT_NO_FACE_PREPARE) {
      if (faceCaptureState != FaceCaptureState.NO_FACE) {
        setViewMode(ViewMode.FACE_CIRCLE);
      }
      return false;
    }

    if (_viewMode == ViewMode.FACE_CIRCLE) {
      if (faceCaptureState == FaceCaptureState.NO_FACE) {
        _noFaceCounter++;
        _stableFrames = 0;
        if (_noFaceCounter >= 8) {
          setState(() {
            _warningTxt = "Position your face inside the circle";
          });
        }
        return false;
      }

      _noFaceCounter = 0;

      if (faceCaptureState == FaceCaptureState.MULTIPLE_FACES) {
        _stableFrames = 0;
        setState(() {
          _warningTxt = "Multiple faces detected - only 1 person allowed!";
        });
        return false;
      } else if (faceCaptureState == FaceCaptureState.FIT_IN_CIRCLE) {
        _stableFrames = 0;
        setState(() {
          _warningTxt = "Center your face inside the circle";
        });
        return false;
      } else if (faceCaptureState == FaceCaptureState.MOVE_CLOSER) {
        _stableFrames = 0;
        setState(() {
          _warningTxt = "Move closer to camera";
        });
        return false;
      } else if (faceCaptureState == FaceCaptureState.NO_FRONT) {
        _stableFrames = 0;
        final double pitch = ((_currentFace?['pitch'] ?? 0.0) as num).toDouble();
        if (pitch > 18.0) {
          setState(() {
            _warningTxt = "Tilt head down slightly";
          });
        } else if (pitch < -18.0) {
          setState(() {
            _warningTxt = "Tilt head up slightly";
          });
        } else {
          setState(() {
            _warningTxt = "Look straight into camera";
          });
        }
        return false;
      } else if (faceCaptureState == FaceCaptureState.FACE_OCCLUDED) {
        _stableFrames = 0;
        setState(() {
          _warningTxt = "Remove face coverings";
        });
        return false;
      } else if (faceCaptureState == FaceCaptureState.EYE_CLOSED) {
        _stableFrames = 0;
        setState(() {
          _warningTxt = "Please keep eyes open";
        });
        return false;
      } else if (faceCaptureState == FaceCaptureState.MOUTH_OPENED) {
        _stableFrames = 0;
        setState(() {
          _warningTxt = "Please close your mouth";
        });
        return false;
      } else if (faceCaptureState == FaceCaptureState.CAPTURE_OK) {
        _stableFrames++;
        if (_stableFrames < 2) {
          setState(() {
            _warningTxt = "Hold steady...";
          });
          return false;
        }

        // Ready to capture!
        setState(() {
          _warningTxt = "Capturing...";
        });
        return true;
      }
    }

    return false;
  }

  Future<void> commitCapturedFace(Map<String, dynamic> faceData) async {
    if (!mounted) return;
    try {
      final Uint8List faceJpg = faceData['faceJpg'] as Uint8List;
      if (faceJpg.isEmpty) return;

      final ui.Image capturedImage = await decodeImageFromList(faceJpg);

      final Rect roiRectSrc = Rect.fromLTWH(
        0,
        0,
        capturedImage.width.toDouble(),
        capturedImage.height.toDouble(),
      );

      final recorder = ui.PictureRecorder();
      final canvas1 = Canvas(recorder, roiRectSrc);

      final path = Path()
        ..addOval(Rect.fromCircle(
          center: Offset(roiRectSrc.width / 2, roiRectSrc.height / 2),
          radius: (roiRectSrc.width < roiRectSrc.height
              ? roiRectSrc.width / 2
              : roiRectSrc.height / 2),
        ));

      canvas1.clipPath(path);

      final paint = Paint();
      canvas1.drawImageRect(
        capturedImage,
        roiRectSrc,
        roiRectSrc,
        paint,
      );

      final picture = recorder.endRecording();
      final ui.Image roiImage = await picture.toImage(
        roiRectSrc.width.toInt(),
        roiRectSrc.height.toInt(),
      );

      setState(() {
        _warningTxt = "";
        _capturedImage = roiImage;
        _capturedFace = faceData;
      });

      setViewMode(ViewMode.FACE_CAPTURE_PREPARE);
    } catch (e) {
      debugPrint('[FaceCaptureView] commitCapturedFace error: $e');
    }
  }

  Future<bool> onFaceDetected(faces) async {
    if (faces is List<Map<String, dynamic>>) {
      return await evaluateAndTrackFaces(faces);
    }
    return false;
  }

  FaceCaptureState checkFace(dynamic rawFaces) {
    if (rawFaces == null || (rawFaces is List && rawFaces.isEmpty)) {
      return FaceCaptureState.NO_FACE;
    }

    final List faces = rawFaces is List ? List.from(rawFaces) : [];
    if (faces.isEmpty) return FaceCaptureState.NO_FACE;

    // Sort by bounding box area descending so primary face is index 0
    faces.sort((a, b) {
      final num areaA = (((a['x2'] as num?) ?? 0) - ((a['x1'] as num?) ?? 0)).abs() *
          (((a['y2'] as num?) ?? 0) - ((a['y1'] as num?) ?? 0)).abs();
      final num areaB = (((b['x2'] as num?) ?? 0) - ((b['x1'] as num?) ?? 0)).abs() *
          (((b['y2'] as num?) ?? 0) - ((b['y1'] as num?) ?? 0)).abs();
      return areaB.compareTo(areaA);
    });

    final primary = faces[0];
    final double primaryWidth = (((primary['x2'] as num?) ?? 0) - ((primary['x1'] as num?) ?? 0)).abs().toDouble();
    final double primaryHeight = (((primary['y2'] as num?) ?? 0) - ((primary['y1'] as num?) ?? 0)).abs().toDouble();
    final double primaryArea = primaryWidth * primaryHeight;


    // Filter out false positive multiple faces (posters, reflections, tiny background people)
    if (faces.length > 1) {
      for (int i = 1; i < faces.length; i++) {
        final other = faces[i];
        final double otherWidth = (((other['x2'] as num?) ?? 0) - ((other['x1'] as num?) ?? 0)).abs().toDouble();
        final double otherHeight = (((other['y2'] as num?) ?? 0) - ((other['y1'] as num?) ?? 0)).abs().toDouble();
        final double otherArea = otherWidth * otherHeight;
        if (otherWidth >= 100 && otherHeight >= 100 && otherArea >= (primaryArea * 0.35)) {
          return FaceCaptureState.MULTIPLE_FACES;
        }
      }
    }

    double faceLeft = ((primary['x1'] as num?) ?? 0).toDouble();
    double faceRight = ((primary['x2'] as num?) ?? 0).toDouble();
    double faceBottom = ((primary['y2'] as num?) ?? 0).toDouble();

    const double sizeRate = 0.20;
    const double interRate = 0.10;
    const Size frameSize = Size(720, 1280);

    final Rect roiRect = getROIRect(frameSize);
    final double centerY = (((primary['y2'] as num?) ?? 0) + ((primary['y1'] as num?) ?? 0)) / 2;
    final double topY = centerY - (((primary['y2'] as num?) ?? 0) - ((primary['y1'] as num?) ?? 0)) * 2 / 3;
    final double interX = (roiRect.left - faceLeft).clamp(0.0, double.infinity) +
        (faceRight - roiRect.right).clamp(0.0, double.infinity);
    final double interY = (roiRect.top - topY).clamp(0.0, double.infinity) +
        (faceBottom - roiRect.bottom).clamp(0.0, double.infinity);

    if (interX / roiRect.width > interRate ||
        interY / roiRect.height > interRate) {
      return FaceCaptureState.FIT_IN_CIRCLE;
    }

    if (primaryArea < roiRect.width * roiRect.height * sizeRate) {
      return FaceCaptureState.MOVE_CLOSER;
    }

    final double yaw = (((primary['yaw'] as num?) ?? 0.0)).toDouble();
    final double pitch = (((primary['pitch'] as num?) ?? 0.0)).toDouble();
    final double roll = (((primary['roll'] as num?) ?? 0.0)).toDouble();

    if (yaw.abs() > DEFAULT_YAW_THRESHOLD ||
        roll.abs() > DEFAULT_ROLL_THRESHOLD ||
        pitch.abs() > DEFAULT_PITCH_THRESHOLD) {
      return FaceCaptureState.NO_FRONT;
    }

    final double leftEyeClosed = (((primary['left_eye_closed'] as num?) ?? 0.0)).toDouble();
    final double rightEyeClosed = (((primary['right_eye_closed'] as num?) ?? 0.0)).toDouble();

    if (leftEyeClosed > DEFAULT_EYECLOSE_THRESHOLD ||
        rightEyeClosed > DEFAULT_EYECLOSE_THRESHOLD) {
      return FaceCaptureState.EYE_CLOSED;
    }

    if (((primary['mouth_opened'] as num?) ?? 0.0) > DEFAULT_MOUTHOPEN_THRESHOLD) {
      return FaceCaptureState.MOUTH_OPENED;
    }

    return FaceCaptureState.CAPTURE_OK;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        faceDetectionViewController?.stopCamera();
        onNativeStopCamera?.call();
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF12121A) : Colors.black,
        appBar: AppBar(
          title: Text(
            'Face Registration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black87,
          ),
          backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          elevation: 0,
          toolbarHeight: 65,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Registration Tips',
              onPressed: () {
                setState(() {
                  _showInstructions = true;
                });
              },
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            FaceCaptureDetectionView(faceRecognitionViewState: this),
            Visibility(
                visible: !_showInstructions && _viewMode == ViewMode.NO_FACE_PREPARE,
                child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CaptureView(
                      key: ValueKey('capture_no_face_$_sessionKey'),
                      animateStart: 1.4,
                      animateEnd: 0.88,
                      duration: 800,
                      repeat: false,
                      viewMode: _viewMode,
                      setViewMode: setViewMode,
                      currentFace: _currentFace,
                    ))),
            Visibility(
                visible: _viewMode == ViewMode.REPEAT_NO_FACE_PREPARE,
                child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CaptureView(
                      key: ValueKey('capture_repeat_$_sessionKey'),
                      animateStart: 0.88,
                      animateEnd: 0.92,
                      duration: 1300,
                      repeat: true,
                      viewMode: _viewMode,
                      setViewMode: setViewMode,
                      currentFace: _currentFace,
                    ))),
            Visibility(
                visible: _viewMode == ViewMode.TO_FACE_CIRCLE,
                child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CaptureView(
                      key: ValueKey('capture_to_circle_$_sessionKey'),
                      animateStart: 1.4,
                      animateEnd: 0,
                      duration: 800,
                      repeat: false,
                      viewMode: _viewMode,
                      setViewMode: setViewMode,
                      currentFace: _currentFace,
                    ))),
            Visibility(
                visible: _viewMode == ViewMode.FACE_CIRCLE,
                child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CaptureView(
                      key: ValueKey('capture_circle_$_sessionKey'),
                      animateStart: 0,
                      animateEnd: 0,
                      duration: 0,
                      repeat: false,
                      viewMode: _viewMode,
                      setViewMode: setViewMode,
                      currentFace: _currentFace,
                    ))),
            Visibility(
                visible: _viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE,
                child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CaptureView(
                      key: ValueKey('capture_circle_to_no_face_$_sessionKey'),
                      animateStart: 0,
                      animateEnd: 1.0,
                      duration: 600,
                      repeat: false,
                      viewMode: _viewMode,
                      setViewMode: setViewMode,
                      currentFace: _currentFace,
                    ))),
            Visibility(
                visible: _viewMode == ViewMode.FACE_CAPTURE_PREPARE,
                child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CaptureView(
                      key: ValueKey('capture_prepare_$_sessionKey'),
                      animateStart: 0,
                      animateEnd: 1.0,
                      duration: 500,
                      repeat: false,
                      viewMode: _viewMode,
                      setViewMode: setViewMode,
                      currentFace: _capturedFace,
                    ))),
            Visibility(
                visible: _viewMode.index >= ViewMode.FACE_CAPTURE_DONE.index,
                child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CaptureView(
                      key: ValueKey('capture_done_$_sessionKey'),
                      animateStart: 0,
                      animateEnd: 1.0,
                      duration: 500,
                      repeat: false,
                      viewMode: _viewMode,
                      setViewMode: setViewMode,
                      currentFace: _capturedImage,
                    ))),
            if (_warningTxt.isNotEmpty &&
                _viewMode.index < ViewMode.FACE_CAPTURE_DONE.index)
              Positioned(
                top: 20,
                left: 24,
                right: 24,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _warningTxt.contains("Hold steady") || _warningTxt.contains("Capturing")
                            ? Colors.greenAccent
                            : Colors.amberAccent.withOpacity(0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _warningTxt.contains("Hold steady") || _warningTxt.contains("Capturing")
                              ? Icons.camera_alt_rounded
                              : Icons.info_outline_rounded,
                          color: _warningTxt.contains("Hold steady") || _warningTxt.contains("Capturing")
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _warningTxt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _warningTxt.contains("Hold steady") || _warningTxt.contains("Capturing")
                                  ? Colors.greenAccent
                                  : Colors.amberAccent,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Visibility(
              visible: _viewMode.index == ViewMode.FACE_CAPTURE_FINISHED.index,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withOpacity(isDark ? 0.45 : 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withOpacity(isDark ? 0.2 : 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Face Captured Successfully',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Review your photo and save to complete registration, or re-scan to capture again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.black87,
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                    width: 1.2,
                                  ),
                                  backgroundColor: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade50,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _isSaving ? null : rescanFace,
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 20),
                                label: const Text(
                                  'Re-scan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorConst.themeColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      ColorConst.themeColor.withOpacity(0.6),
                                  disabledForegroundColor: Colors.white70,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => registerFace(context),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded, size: 20),
                                label: Text(
                                  _isSaving ? 'Saving...' : 'Save',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_showInstructions)
              Container(
                color: Colors.black.withOpacity(0.72),
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.08),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ColorConst.themeColor.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lightbulb_outline_rounded,
                              color: ColorConst.themeColor,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Face Registration Tips',
                            style: TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Please follow these instructions for a fast and accurate scan:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildInstructionTile(
                            isDark: isDark,
                            icon: Icons.wb_sunny_rounded,
                            iconColor: Colors.amber.shade700,
                            title: 'Good Lighting on Face',
                            description:
                                'Make sure your face is well lit. Avoid strong shadows or bright backlights.',
                          ),
                          const SizedBox(height: 10),
                          _buildInstructionTile(
                            isDark: isDark,
                            icon: Icons.visibility_rounded,
                            iconColor: Colors.blueAccent,
                            title: 'Look Straight into Camera',
                            description:
                                'Hold your phone at eye level and face the camera directly without tilting.',
                          ),
                          const SizedBox(height: 10),
                          _buildInstructionTile(
                            isDark: isDark,
                            icon: Icons.crop_free_rounded,
                            iconColor: Colors.teal,
                            title: 'Fit in Circle & Hold Steady',
                            description:
                                'Position your face comfortably in the guide (not too far or too close) and stay still.',
                          ),
                          const SizedBox(height: 10),
                          _buildInstructionTile(
                            isDark: isDark,
                            icon: Icons.face_retouching_off_rounded,
                            iconColor: Colors.redAccent,
                            title: 'No Face Coverings',
                            description:
                                'Remove masks, caps, or dark sunglasses for clear identification.',
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConst.themeColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showInstructions = false;
                                  _sessionKey++;
                                  _stableFrames = 0;
                                  _viewMode = ViewMode.NO_FACE_PREPARE;
                                });
                              },
                              icon: const Icon(Icons.camera_alt_rounded,
                                  size: 20),
                              label: const Text(
                                'Start Scan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FaceCaptureDetectionView extends StatefulWidget
    implements FaceDetectionInterface {
  FaceCaptureViewState faceRecognitionViewState;

  FaceCaptureDetectionView({super.key, required this.faceRecognitionViewState});

  @override
  Future<void> onFaceDetected(faces) async {
    await faceRecognitionViewState.onFaceDetected(faces);
  }

  @override
  State<StatefulWidget> createState() => _FaceCaptureDetectionViewState();
}

class _FaceCaptureDetectionViewState extends State<FaceCaptureDetectionView> {
  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  FaceDetector? _faceDetector;
  bool _isProcessingFrame = false;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initDetector();
    _startCamera();
  }

  void _initDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        enableClassification: true,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<void> _startCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        debugPrint('[FaceCaptureView] Camera permission denied');
        return;
      }

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
        _cameraController = controller;
        _isCameraReady = true;
      });

      widget.faceRecognitionViewState.onNativeStopCamera = () {
        if (_cameraController != null && _cameraController!.value.isStreamingImages) {
          try {
            _cameraController?.stopImageStream();
          } catch (_) {}
        }
      };

      widget.faceRecognitionViewState.onNativeRestartCamera = () async {
        _isProcessingFrame = false;
        if (_cameraController != null &&
            _cameraController!.value.isInitialized &&
            !_cameraController!.value.isStreamingImages) {
          try {
            await _cameraController?.startImageStream(_onCameraFrame);
          } catch (e) {
            debugPrint('[FaceCaptureView] Error restarting camera stream: $e');
          }
        }
      };

      await controller.startImageStream(_onCameraFrame);
    } catch (e) {
      debugPrint('[FaceCaptureView] Error starting camera: $e');
    }
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_isProcessingFrame || !mounted || _faceDetector == null || _frontCamera == null) {
      return;
    }
    if (widget.faceRecognitionViewState._showInstructions) {
      return;
    }
    if (widget.faceRecognitionViewState._viewMode.index >= ViewMode.FACE_CAPTURE_DONE.index) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final inputImage = FaceSdkEngine.instance.convertCameraImage(image, _frontCamera!);
      if (inputImage == null) return;

      final mlFaces = await _faceDetector!.processImage(inputImage);
      if (!mounted || widget.faceRecognitionViewState._viewMode.index >= ViewMode.FACE_CAPTURE_DONE.index) {
        return;
      }

      final int uprightWidth = (_frontCamera!.sensorOrientation == 90 || _frontCamera!.sensorOrientation == 270)
          ? image.height
          : image.width;
      final int uprightHeight = (_frontCamera!.sensorOrientation == 90 || _frontCamera!.sensorOrientation == 270)
          ? image.width
          : image.height;

      // Scale to 720x1280 coordinate system that getROIRect expects
      const double targetWidth = 720.0;
      const double targetHeight = 1280.0;
      final double scaleX = targetWidth / uprightWidth;
      final double scaleY = targetHeight / uprightHeight;

      final List<Map<String, dynamic>> faceList = [];

      for (final face in mlFaces) {
        final box = face.boundingBox;

        // Front camera preview is mirrored horizontally
        final double mirroredLeft = uprightWidth - box.right;
        final double mirroredRight = uprightWidth - box.left;

        final double x1 = (mirroredLeft * scaleX).clamp(0.0, targetWidth);
        final double x2 = (mirroredRight * scaleX).clamp(0.0, targetWidth);
        final double y1 = (box.top * scaleY).clamp(0.0, targetHeight);
        final double y2 = (box.bottom * scaleY).clamp(0.0, targetHeight);

        // Invert yaw so 3D crosshairs follow head movement in mirrored preview
        final double yaw = -(face.headEulerAngleY ?? 0.0);
        final double pitch = face.headEulerAngleX ?? 0.0;
        final double roll = face.headEulerAngleZ ?? 0.0;

        final double leftEyeClosed = 1.0 - (face.leftEyeOpenProbability ?? 1.0);
        final double rightEyeClosed = 1.0 - (face.rightEyeOpenProbability ?? 1.0);

        faceList.add({
          'x1': x1,
          'y1': y1,
          'x2': x2,
          'y2': y2,
          'yaw': yaw,
          'pitch': pitch,
          'roll': roll,
          'face_occlusion': 0.0,
          'left_eye_closed': leftEyeClosed,
          'right_eye_closed': rightEyeClosed,
          'mouth_opened': 0.0,
          'face_quality': 0.88,
          'face_luminance': 0.75,
          'liveness': 1.0,
          'frameWidth': targetWidth,
          'frameHeight': targetHeight,
          'rawFace': face,
        });
      }

      final bool readyToCapture = await widget.faceRecognitionViewState.evaluateAndTrackFaces(faceList);

      if (readyToCapture && faceList.isNotEmpty && mounted) {
        try {
          await _cameraController?.stopImageStream();
        } catch (_) {}

        final primaryFace = faceList.first['rawFace'] as Face;
        final extracted = await FaceSdkEngine.instance.extractFaceFromCameraImage(
          cameraImage: image,
          camera: _frontCamera!,
          boundingBox: primaryFace.boundingBox,
        );

        if (extracted != null && mounted) {
          final faceData = Map<String, dynamic>.from(faceList.first);
          faceData['faceJpg'] = extracted['faceJpg'] ?? Uint8List(0);
          faceData['templates'] = extracted['templates'] ?? Uint8List(0);
          faceData['fullFrameJpg'] = extracted['fullFrameJpg'] ?? Uint8List(0);

          await widget.faceRecognitionViewState.commitCapturedFace(faceData);
        }
      }
    } catch (e) {
      debugPrint('[FaceCaptureView] onCameraFrame error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  @override
  void dispose() {
    widget.faceRecognitionViewState.onNativeStopCamera = null;
    widget.faceRecognitionViewState.onNativeRestartCamera = null;
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      try {
        _cameraController?.stopImageStream();
      } catch (_) {}
    }
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady || _cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }
}

class CaptureView extends StatefulWidget {
  final double animateStart;
  final double animateEnd;
  final int duration;
  final bool repeat;
  final ViewMode viewMode;
  final Function(ViewMode) setViewMode;
  final dynamic currentFace;

  const CaptureView(
      {super.key,
      required this.animateStart,
      required this.animateEnd,
      required this.duration,
      required this.repeat,
      required this.viewMode,
      required this.setViewMode,
      required this.currentFace});

  @override
  _CaptureViewState createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController and Tween for scaling the circle
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    );

    _animation =
        Tween<double>(begin: widget.animateStart, end: widget.animateEnd)
            .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ))
          ..addListener(() {
            setState(() {});
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              // Animation has finished
              _handleAnimationEnd();
              // You can add any code to be executed when the animation finishes here
            } else if (status == AnimationStatus.dismissed) {
              // Animation is dismissed (goes back to the starting point)
            }
          });
    // Start the animation
    if (widget.repeat == true)
      _controller.repeat(reverse: widget.repeat);
    else
      _controller.forward();
  }

  void _handleAnimationEnd() {
    if (widget.viewMode == ViewMode.NO_FACE_PREPARE) {
      setState(() {
        widget.setViewMode(ViewMode.REPEAT_NO_FACE_PREPARE);
      });
    } else if (widget.viewMode == ViewMode.TO_FACE_CIRCLE) {
      setState(() {
        widget.setViewMode(ViewMode.FACE_CIRCLE);
      });
    } else if (widget.viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE) {
      setState(() {
        widget.setViewMode(ViewMode.NO_FACE_PREPARE);
      });
    } else if (widget.viewMode == ViewMode.FACE_CAPTURE_PREPARE) {
      setState(() {
        widget.setViewMode(ViewMode.FACE_CAPTURE_DONE);
      });
    } else if (widget.viewMode == ViewMode.FACE_CAPTURE_DONE) {
      widget.setViewMode(ViewMode.FACE_CAPTURE_FINISHED);
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter:
          CapturePainter(_animation.value, widget.viewMode, widget.currentFace),
      child: Container(),
    );
  }
}

class CapturePainter extends CustomPainter {
  final double animateValue;
  final ViewMode viewMode;
  bool scrimInited = false;
  final Paint eraserPaint;
  final dynamic currentFace;
  late ui.Image roiImage;

  CapturePainter(this.animateValue, this.viewMode, this.currentFace)
      : eraserPaint = Paint()
          ..color = Colors.transparent
          ..blendMode = BlendMode.clear;

  @override
  void paint(Canvas canvas, Size size) async {
    final Paint overlayPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Draw a full-screen rectangle with overlay paint
    Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    Paint outSideActiveRoundPaint = Paint()
      ..style = PaintingStyle.stroke // Equivalent to Paint.Style.STROKE in Java
      ..strokeWidth = 4 // Set stroke width
      ..color = const Color(
          0xFFE6E1E5) // Set the color (use the actual color value or from your theme)
      ..isAntiAlias = true; // Equivalent to setAntiAlias(true) in Java

    Size frameSize = const Size(720, 1280);
    Rect roiRect = getROIRect1(frameSize);

    double ratioView = size.width / size.height;
    double ratioFrame = frameSize.width / frameSize.height;

    Rect roiViewRect;

    if (ratioView < ratioFrame) {
      double dx = ((size.height * ratioFrame) - size.width) / 2;
      double dy = 0;
      double ratio = size.height / frameSize.height;

      double x1 = roiRect.left * ratio - dx;
      double y1 = roiRect.top * ratio - dy;
      double x2 = roiRect.right * ratio - dx;
      double y2 = roiRect.bottom * ratio - dy;

      roiViewRect = Rect.fromLTRB(x1, y1, x2, y2);
    } else {
      double dx = 0;
      double dy = ((size.width / ratioFrame) - size.height) / 2;
      double ratio = size.height / frameSize.height;

      double x1 = roiRect.left * ratio - dx;
      double y1 = roiRect.top * ratio - dy;
      double x2 = roiRect.right * ratio - dx;
      double y2 = roiRect.bottom * ratio - dy;

      roiViewRect = Rect.fromLTRB(x1, y1, x2, y2);
    }

    if (viewMode == ViewMode.FACE_CIRCLE ||
        viewMode == ViewMode.FACE_CAPTURE_PREPARE ||
        viewMode.index >= ViewMode.FACE_CAPTURE_DONE.index ||
        (viewMode == ViewMode.TO_FACE_CIRCLE && animateValue < 1.0) ||
        viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE) {
      if (viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE) {
      } else {}

      double startWidth = 0.8 * roiViewRect.width * 0.5 / cos(45 * pi / 180);

      double centerX = roiViewRect.center.dx;
      double centerY = roiViewRect.center.dy;
      double left = centerX -
          (roiViewRect.width / 2 * (1 - animateValue) +
              startWidth * animateValue);
      double top = centerY -
          (roiViewRect.width / 2 * (1 - animateValue) +
              startWidth * animateValue);
      double right = centerX +
          (roiViewRect.width / 2 * (1 - animateValue) +
              startWidth * animateValue);
      double bottom = centerY +
          (roiViewRect.width / 2 * (1 - animateValue) +
              startWidth * animateValue);

      if ((viewMode == ViewMode.TO_FACE_CIRCLE && animateValue < 1.0) ||
          viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE) {}

      if (viewMode != ViewMode.FACE_CAPTURE_PREPARE) {
        Rect eraseRect = Rect.fromLTWH(left, top, right - left, bottom - top);
        Path circlePath = Path()
          ..addOval(
            Rect.fromCircle(
              center: eraseRect.center,
              radius: eraseRect.width / 2,
            ),
          );

        if (viewMode.index < ViewMode.FACE_CAPTURE_DONE.index) {
          overlayPath =
              Path.combine(PathOperation.difference, overlayPath, circlePath);
        }
        canvas.drawPath(overlayPath, overlayPaint);
      } else if (viewMode == ViewMode.FACE_CAPTURE_PREPARE) {
        Rect borderRect = scale(roiViewRect, 1.04);

        // Paint for the border circle
        final borderPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF492532) // Replace with the correct color
          ..isAntiAlias = true;

        // Create a path for the circular shape using borderRect
        Path circlePath = Path()
          ..addOval(Rect.fromCircle(
            center: Offset(borderRect.center.dx, borderRect.center.dy),
            radius: borderRect.width / 2,
          ));

        // Define innerRect and scale it based on animateValue
        Rect innerRect = scale(roiViewRect, 1.0 - animateValue);
        Path circlePath1 = Path()
          ..addOval(
            Rect.fromCircle(
              center: innerRect.center,
              radius: innerRect.width / 2,
            ),
          );

        circlePath =
            Path.combine(PathOperation.difference, circlePath, circlePath1);

        overlayPath =
            Path.combine(PathOperation.difference, overlayPath, circlePath1);

        canvas.drawPath(overlayPath, overlayPaint);
        canvas.drawPath(circlePath, borderPaint);
      }
    }

    if (viewMode == ViewMode.NO_FACE_PREPARE ||
        viewMode == ViewMode.REPEAT_NO_FACE_PREPARE ||
        viewMode == ViewMode.TO_FACE_CIRCLE ||
        viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE) {
      Rect scaleRect = roiViewRect;
      if (viewMode == ViewMode.NO_FACE_PREPARE ||
          viewMode == ViewMode.REPEAT_NO_FACE_PREPARE ||
          (viewMode == ViewMode.TO_FACE_CIRCLE && animateValue > 1.0)) {
        scaleRect = scale(roiViewRect, animateValue);
      }

      double lineWidth1 = scaleRect.width / 5;
      double lineWidthOffset1 = 0;
      if (viewMode == ViewMode.FACE_CIRCLE ||
          (viewMode == ViewMode.TO_FACE_CIRCLE && animateValue < 1.0) ||
          viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE) {
        lineWidth1 = lineWidth1 * animateValue;
        lineWidthOffset1 = scaleRect.width / 2 * (1 - animateValue);
      }

      double lineHeight1 = scaleRect.height / 5;
      double lineHeightOffset1 = 0;
      if (viewMode == ViewMode.FACE_CIRCLE ||
          (viewMode == ViewMode.TO_FACE_CIRCLE && animateValue < 1.0) ||
          viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE) {
        lineHeight1 = lineHeight1 * animateValue;
        lineHeightOffset1 = scaleRect.height / 2 * (1 - animateValue);
      }

      double quadR1 = scaleRect.width / 12;
      if (viewMode == ViewMode.FACE_CIRCLE ||
          (viewMode == ViewMode.TO_FACE_CIRCLE && animateValue < 1.0) ||
          viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE) {
        quadR1 = scaleRect.width / 12 +
            (scaleRect.width / 2 - scaleRect.width / 12) * (1 - animateValue) -
            20;
      }

      Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = const Color(0xFFEADDFF)
        ..isAntiAlias = true;

      if (viewMode == ViewMode.NO_FACE_PREPARE ||
          (viewMode == ViewMode.TO_FACE_CIRCLE && animateValue > 1.0)) {
        int alpha = (min(255, ((1.4 - animateValue) / 0.4 * 255))).toInt();
        paint.color = paint.color.withAlpha(alpha);
      } else {
        paint.color = paint.color.withAlpha(255);
      }

      if (viewMode == ViewMode.NO_FACE_PREPARE ||
          viewMode == ViewMode.REPEAT_NO_FACE_PREPARE ||
          viewMode == ViewMode.TO_FACE_CIRCLE ||
          viewMode == ViewMode.FACE_CIRCLE_TO_NO_FACE) {
        Path path1 = Path();
        path1.moveTo(
            scaleRect.left, scaleRect.top + lineHeight1 + lineHeightOffset1);
        path1.lineTo(scaleRect.left, scaleRect.top + quadR1);
        path1.arcTo(
            Rect.fromLTWH(
                scaleRect.left, scaleRect.top, quadR1 * 2, quadR1 * 2),
            pi,
            pi / 2,
            false);
        path1.lineTo(
            scaleRect.left + lineWidth1 + lineWidthOffset1, scaleRect.top);
        canvas.drawPath(path1, paint);

        Path path2 = Path();
        path2.moveTo(
            scaleRect.right, scaleRect.top + lineHeight1 + lineHeightOffset1);
        path2.lineTo(scaleRect.right, scaleRect.top + quadR1);
        path2.arcTo(
            Rect.fromLTWH(scaleRect.right - quadR1 * 2, scaleRect.top,
                quadR1 * 2, quadR1 * 2),
            0,
            -pi / 2,
            false);
        path2.lineTo(
            scaleRect.right - lineWidth1 - lineWidthOffset1, scaleRect.top);
        canvas.drawPath(path2, paint);

        Path path3 = Path();
        path3.moveTo(scaleRect.right,
            scaleRect.bottom - lineHeight1 - lineHeightOffset1);
        path3.lineTo(scaleRect.right, scaleRect.bottom - quadR1);
        path3.arcTo(
            Rect.fromLTWH(scaleRect.right - quadR1 * 2,
                scaleRect.bottom - quadR1 * 2, quadR1 * 2, quadR1 * 2),
            0,
            pi / 2,
            false);
        path3.lineTo(
            scaleRect.right - lineWidth1 - lineWidthOffset1, scaleRect.bottom);
        canvas.drawPath(path3, paint);

        Path path4 = Path();
        path4.moveTo(
            scaleRect.left, scaleRect.bottom - lineHeight1 - lineHeightOffset1);
        path4.lineTo(scaleRect.left, scaleRect.bottom - quadR1);
        path4.arcTo(
            Rect.fromLTWH(scaleRect.left, scaleRect.bottom - quadR1 * 2,
                quadR1 * 2, quadR1 * 2),
            pi,
            -pi / 2,
            false);
        path4.lineTo(
            scaleRect.left + lineWidth1 + lineWidthOffset1, scaleRect.bottom);
        canvas.drawPath(path4, paint);
      }
    }

    if (viewMode == ViewMode.FACE_CIRCLE) {
      double centerX = roiViewRect.center.dx;
      double centerY = roiViewRect.center.dy;

      // Loop to draw lines
      for (int i = 0; i < 360; i += 5) {
        double a1 = roiViewRect.width / 2 + 4;
        double b1 = roiViewRect.height / 2 + 4;
        double a2 = roiViewRect.width / 2 + 16;
        double b2 = roiViewRect.height / 2 + 16;

        double th = i * pi / 180;
        double x1 = a1 * b1 / sqrt(pow(b1, 2) + pow(a1, 2) * tan(th) * tan(th));
        double x2 = a2 * b2 / sqrt(pow(b2, 2) + pow(a2, 2) * tan(th) * tan(th));
        double y1 = sqrt(1 - (x1 / a1) * (x1 / a1)) * b1;
        double y2 = sqrt(1 - (x1 / a1) * (x1 / a1)) * b2;

        // Adjust x1, x2 for angles between 90° and 270°
        if ((i % 360) > 90 && (i % 360) < 270) {
          x1 = -x1;
          x2 = -x2;
        }

        // Adjust y1, y2 for angles between 180° and 360°
        if ((i % 360) > 180 && (i % 360) < 360) {
          y1 = -y1;
          y2 = -y2;
        }
        // Draw the lines
        canvas.drawLine(Offset(centerX + x1, centerY - y1),
            Offset(centerX + x2, centerY - y2), outSideActiveRoundPaint);
      }

      if (currentFace != null) {
        final Paint paint1 = Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 6
          ..color = const Color(
              0x80EADDFF) // Replace with actual color value or use a theme color
          ..isAntiAlias = true;

        var yaw = currentFace['yaw'];
        var pitch = currentFace['pitch'];

        // Create Path1
        final Path path1 = Path()
          ..moveTo(roiViewRect.center.dx, roiViewRect.top)
          ..quadraticBezierTo(
            roiViewRect.center.dx - roiViewRect.width * (sin(yaw * pi / 180)),
            roiViewRect.center.dy,
            roiViewRect.center.dx,
            roiViewRect.bottom,
          )
          ..quadraticBezierTo(
            roiViewRect.center.dx -
                roiViewRect.width * (sin(yaw * pi / 180)) / 3,
            roiViewRect.center.dy,
            roiViewRect.center.dx,
            roiViewRect.top,
          );
        canvas.drawPath(path1, paint1);

        // Create Path2
        final Path path2 = Path()
          ..moveTo(roiViewRect.left, roiViewRect.center.dy)
          ..quadraticBezierTo(
            roiViewRect.center.dx,
            roiViewRect.center.dy + roiViewRect.width * (sin(pitch * pi / 180)),
            roiViewRect.right,
            roiViewRect.center.dy,
          )
          ..quadraticBezierTo(
            roiViewRect.center.dx,
            roiViewRect.center.dy +
                roiViewRect.width * (sin(pitch * pi / 180)) / 3,
            roiViewRect.left,
            roiViewRect.center.dy,
          );
        canvas.drawPath(path2, paint1);
      }
    } else if (viewMode.index >= ViewMode.FACE_CAPTURE_DONE.index) {
      if (currentFace != null) {
        Rect borderRect = scale(roiViewRect, 0.8);

        // Paint for drawing the circle
        final Paint paint1 = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.tealAccent // Replace with your actual color
          ..strokeWidth = 7
          ..isAntiAlias = true;

        // Translate canvas based on animateValue
        canvas.translate(0, (size.width / 5 - roiViewRect.top) * animateValue);

        //   final ui.Image capturedImage =
        //       await decodeImageFromList(currentFace['faceJpg']);
        // //Draw the bitmap (roiBitmap)
        canvas.drawImageRect(
          currentFace,
          Rect.fromLTWH(0, 0, currentFace.width.toDouble(),
              currentFace.height.toDouble()),
          borderRect,
          Paint(),
        );

        // Draw the circle in the center of the borderRect
        canvas.drawCircle(
          Offset(borderRect.center.dx, borderRect.center.dy),
          borderRect.width / 2,
          paint1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // Repaint whenever animation updates
  }
}
