import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tax_hrm/utils/functionsFile.dart';
import 'package:tax_hrm/widigets/toastmessage.dart';
import 'package:tax_hrm/widigets/permission_dialog_widget.dart';
import 'package:tax_hrm/utils/titlesfile.dart';

class VisitCameraScreen extends StatefulWidget {
  const VisitCameraScreen({super.key});

  @override
  State<VisitCameraScreen> createState() => _VisitCameraScreenState();
}

class _VisitCameraScreenState extends State<VisitCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  String _currentAddress = fetchingLocationString;
  String _currentLatitude = '';
  String _currentLongitude = '';
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCameraAndLocation();
  }

  Future<void> _initializeCameraAndLocation() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        CameraDescription frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
        }
      }
    } catch (e) {
      showtoastmessage('$errorInitializingCameraString$e');
    }

    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentAddress = locationServicesDisabledString);
        _showLocationRequiredDialog(locationServicesDisabledTurnOnGpsString, isGps: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentAddress = locationPermissionsDeniedString);
          _showLocationRequiredDialog(locationPermissionRequiredVisitString);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentAddress = locationPermissionsPermanentlyDeniedString);
        _showLocationRequiredDialog(locationPermissionPermanentlyDeniedSettingsString);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _currentLatitude = position.latitude.toString();
      _currentLongitude = position.longitude.toString();
      
      try {
        List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          if (mounted) {
            setState(() {
              _currentAddress = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
            });
          }
        }
      } catch (e) {
        if (mounted) setState(() => _currentAddress = addressNotFoundString);
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = errorGettingLocationString);
      _showLocationRequiredDialog(errorGettingLocationGpsString, isGps: true);
    }
  }

  void _showLocationRequiredDialog(String message, {bool isGps = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialogWidget(
        icon: isGps ? Icons.location_disabled : Icons.lock_outline,
        iconColor: Colors.orange,
        title: locationRequiredString,
        message: message,
        primaryButtonText: isGps ? gpsSettingsString : openSettingsString,
        secondaryButtonText: cancelString,
        onPrimaryPressed: () {
          Navigator.pop(context);
          if (isGps) {
            Geolocator.openLocationSettings();
          } else {
            Geolocator.openAppSettings();
          }
        },
        onSecondaryPressed: () {
          Navigator.pop(context);
          Navigator.pop(context); // Go back from camera screen
        },
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_currentLatitude.isEmpty || _currentLongitude.isEmpty) {
      _showLocationRequiredDialog(locationMandatoryStartVisitString);
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized || _isTakingPicture) {
      return;
    }
    
    setState(() => _isTakingPicture = true);
    try {
      XFile picture = await _cameraController!.takePicture();
      if (mounted) {
        Navigator.pop(context, {
          'file': File(picture.path),
          'latitude': _currentLatitude,
          'longitude': _currentLongitude,
          'address': _currentAddress,
        });
      }
    } catch (e) {
      showtoastmessage('$errorTakingPictureString$e');
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    safeAreaBgAndTextColor(context, safeAreaBgColor: Colors.black, safeAreaBrightness: Brightness.dark);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraReady && _cameraController != null)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Location Info Overlay
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (_currentLatitude.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$latString$_currentLatitude$lngString$_currentLongitude',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Capture Button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: _isTakingPicture ? Colors.grey : Colors.transparent,
                  ),
                  child: Center(
                    child: Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isTakingPicture ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
