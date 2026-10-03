// ignore_for_file: empty_catches, library_private_types_in_public_api

import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/face_registation/face_punch_state.dart';
import 'package:tax_hrm/provider/face_verification_provider.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:tax_hrm/api/employeapi.dart';
import 'dart:convert';
import 'package:tax_hrm/api/authapi.dart';
import 'package:tax_hrm/models/authclass/emploginclass.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  _FaceRegistrationScreenState createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  late FaceVerificationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<FaceVerificationProvider>(context, listen: false);
    _provider.addListener(_onProviderStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.initCamera(forEnrollment: true);
    });
  }

  bool _isSyncing = false;

  void _onProviderStateChanged() {
    if (!mounted) return;

    if (_provider.currentState == FaceProcessState.success && !_isSyncing) {
      _isSyncing = true;
      _runPostSync();
    }
  }

  Future<void> _runPostSync() async {
    final faceTemplate = _provider.registeredFaceTemplate;
    if (faceTemplate == null || faceTemplate.isEmpty) {
      if (mounted) Navigator.pop(context, false);
      return;
    }

    try {
      final empId = curentUser?['Id']?.toString() ?? '';
      if (empId.isNotEmpty) {
        // Update local user instantly
        if (curentUser != null) {
          curentUser!['FaceRegisterId'] = faceTemplate;
          final String freshJson = jsonEncode(curentUser);
          await SaveUser().saveUserData(freshJson);
        }

        await Employeeclass().updateEmployes(
          seteid: empId,
          firstname: curentUser?['FirstName'] ?? '',
          lastname: curentUser?['LastName'] ?? '',
          mobile1: curentUser?['Mobile1'] ?? '',
          mobile2: curentUser?['Mobile2'] ?? '',
          address1: curentUser?['Add1'] ?? '',
          address2: curentUser?['Add2'] ?? '',
          address3: curentUser?['Add3'] ?? '',
          dob: curentUser?['DOB'] ?? '',
          doj: curentUser?['DOJ'] ?? '',
          pincode: curentUser?['PincodeId'] ?? '',
          cityid: curentUser?['CityId'] ?? '',
          statid: curentUser?['StateId'] ?? '',
          email: curentUser?['Email'] ?? '',
          gender: curentUser?['Gender'] ?? '',
          pan: curentUser?['PAN'] ?? '',
          marstatus: curentUser?['MaritalStatus'] ?? '',
          bankname: curentUser?['BankName'] ?? '',
          branchname: curentUser?['BranchName'] ?? '',
          accno: curentUser?['AccNo'] ?? '',
          accountType: curentUser?['AccType'] ?? '',
          salary: curentUser?['SalaryType'] ?? '',
          salaryamount: curentUser?['SalaryAmount']?.toString() ?? '',
          totalhours: curentUser?['Totalhours']?.toString() ?? '',
          username: curentUser?['UserName'] ?? '',
          password: curentUser?['Password'] ?? '',
          highestDegree: curentUser?['HighestDegree'] ?? '',
          degreeName: curentUser?['DegreeName'] ?? '',
          universityName: curentUser?['UniversityName'] ?? '',
          passingYear: curentUser?['PassingYear'] ?? '',
          uanNo: curentUser?['UANNo'] ?? '',
          esicNo: curentUser?['ESICNo'] ?? '',
          selectedDepartment: curentUser?['DepartmentId'] ?? '',
          selectedposition: curentUser?['PositionId'] ?? '',
          roletypes: curentUser?['Role'] ?? '',
          selectedifsc: curentUser?['IFSC'] ?? '',
          userStatus: curentUser?['IsActive'] ?? true,
          workType: curentUser?['WorkType'] ?? '',
          officeLocation: curentUser?['OfficeLocation'] ?? '',
          locationRadius: curentUser?['LocationRadius'] ?? '50',
          isFetchLocation: curentUser?['IsFetchLocation'] ?? false,
          setCguids: curentUser?['Cguid'] ?? '',
          faceRegisterId: faceTemplate,
          removeImage: true,
          listenRes: (_) {},
        );

        final username = curentUser?['UserName'] ?? '';
        final password = curentUser?['Password'] ?? '';
        if (username.isNotEmpty && password.isNotEmpty) {
          final dynamic loginResult = await AuthLoginService().callEmployeLogin(
            username,
            password,
          );
          if (loginResult is EmpUserLogin && loginResult.success != false) {
            final String freshJson = jsonEncode(loginResult.toJson());
            await SaveUser().saveUserData(freshJson);
            curentUser = jsonDecode(freshJson);
          }
        }
      }
    } catch (e) {
      // Ignored
    }
    if (mounted) {
      Navigator.pop(context, _provider.registeredFaceTemplate ?? true);
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderStateChanged);
    super.dispose();
  }

  @override
  void deactivate() {
    final provider = Provider.of<FaceVerificationProvider>(
      context,
      listen: false,
    );
    Future.microtask(() => provider.stopCamera());
    super.deactivate();
  }

  String _getErrorMessage(FaceErrorReason reason) {
    switch (reason) {
      case FaceErrorReason.noFace:
        return noFaceDetectedString;
      case FaceErrorReason.multipleFaces:
        return multipleFacesDetectedString;
      case FaceErrorReason.moveCloser:
        return moveCloserString;
      case FaceErrorReason.moveBack:
        return moveBackString;
      case FaceErrorReason.straightenFace:
        return straightenFaceString;
      case FaceErrorReason.alignFace:
        return "Please align your face within the circular frame";
      case FaceErrorReason.cameraDenied:
        return cameraPermissionDeniedString;
      case FaceErrorReason.cameraUnavailable:
        return cameraUnavailableString;
      case FaceErrorReason.modelInitFailed:
        return modelInitFailedString;
      case FaceErrorReason.spoofDetected:
      case FaceErrorReason.livenessFailed:
        return "Fake or non-live face detected";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          faceRegistrationString,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
          ),
        ),
      ),
      body: Consumer<FaceVerificationProvider>(
        builder: (context, provider, child) {
          // ── Initializing ─────────────────────────────────────────────
          if (provider.currentState == FaceProcessState.initializing) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ColorConst.themeColor),
                  const SizedBox(height: 16),
                  Text(
                    initializingCameraString,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // ── Success + syncing loader ──────────────────────────────────
          if (provider.currentState == FaceProcessState.success) {
            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Green check icon
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.greenAccent,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    registrationCompleteString,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    faceRegisteredString,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 28),

                  // ── Syncing loader (fades in/out) ───────────────────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: provider.isSyncing
                        ? Column(
                            key: const ValueKey('syncing'),
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    ColorConst.themeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Saving face data...',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('done')),
                  ),
                ],
              ),
            );
          }

          // ── Camera scanning view ──────────────────────────────────────
          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera Preview
              if (provider.cameraController != null &&
                  provider.cameraController!.value.isInitialized)
                ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: provider
                            .cameraController!
                            .value
                            .previewSize!
                            .height,
                        height:
                            provider.cameraController!.value.previewSize!.width,
                        child: CameraPreview(provider.cameraController!),
                      ),
                    ),
                  ),
                ),

              // Overlay Circular Cutout
              CustomPaint(
                painter: _HolePainter(),
                child: const SizedBox.expand(),
              ),

              // Animated Circular Progress Indicator
              if (provider.currentState == FaceProcessState.recognizing ||
                  provider.currentState == FaceProcessState.faceDetected ||
                  provider.enrollmentStep > 0)
                Center(
                  child: Container(
                    height: 310,
                    width: 310,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ColorConst.themeColor.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0.0,
                        end: provider.enrollmentStep / 3.0,
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorConst.themeColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Status Text Card (Glassmorphism)
              Positioned(
                bottom: 80,
                left: 24,
                right: 24,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            provider.currentError != FaceErrorReason.none
                                ? Icons.warning_amber_rounded
                                : Icons.face_retouching_natural_rounded,
                            color: provider.currentError != FaceErrorReason.none
                                ? Colors.redAccent
                                : Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.currentError != FaceErrorReason.none
                                ? _getErrorMessage(provider.currentError)
                                : (provider.currentState ==
                                          FaceProcessState.detectingFace
                                      ? lookingForFaceString
                                      : (provider.currentState ==
                                                    FaceProcessState
                                                        .recognizing ||
                                                provider.currentState ==
                                                    FaceProcessState
                                                        .faceDetected
                                            ? (provider.enrollmentStep == 0
                                                  ? step1FaceString
                                                  : provider.enrollmentStep == 1
                                                  ? step2FaceString
                                                  : step3FaceString)
                                            : positionFaceString)),
                            style: TextStyle(
                              color:
                                  provider.currentError != FaceErrorReason.none
                                  ? Colors.redAccent
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Retry Button for failures
              if (provider.currentState == FaceProcessState.failed)
                Positioned(
                  bottom: 30,
                  left: 40,
                  right: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConst.themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: ColorConst.themeColor.withOpacity(0.4),
                    ),
                    onPressed: () {
                      provider.retry();
                      provider.initCamera(forEnrollment: true);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      "Try Again",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.75);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addOval(
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: 150,
            ),
          )
          ..close(),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) {
    return false;
  }
}
