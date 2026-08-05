// ignore_for_file: use_super_parameters, strict_top_level_inference

// Only For Exit App and Log Out DialogBox

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tax_hrm/utils/titlesfile.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tax_hrm/utils/colorsfile.dart';
import 'package:tax_hrm/widigets/spacer.dart';

Future<bool> commonDialogBoxDesign({context, size, title, onTapLogOut}) async {
  bool isLoading = false;
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: ColorConst.transparent,
            child: Container(
              padding: EdgeInsets.only(left: size.width*0.03,right: size.width *0.03,bottom: size.width *0.03),
              decoration: BoxDecoration(
                color: ColorConst.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  heightSpacer(size.height * 0.02),
                  Container(
                    width: size.width * 0.25,
                    height: size.width * 0.25,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.logout, color: ColorConst.redDarkColors, size: size.width * 0.1),
                  ),

                  heightSpacer(size.height * 0.02),

                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),

                  heightSpacer(size.height * 0.01),

                  Text('Are you sure you want to $title?', textAlign: TextAlign.center,style: const TextStyle(  fontSize: 14,  color: Colors.grey)),

                  heightSpacer(size.height * 0.05),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(size.width, size.height * 0.06),
                      backgroundColor: ColorConst.redDarkColors,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (onTapLogOut != null) {
                              setDialogState(() {
                                isLoading = true;
                              });
                              try {
                                await onTapLogOut();
                              } catch (e) {
                                if (context.mounted) {
                                  setDialogState(() {
                                    isLoading = false;
                                  });
                                }
                              }
                            } else {
                              SystemNavigator.pop();
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text('Yes, $title' ,style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ColorConst.white)),
                  ),

                  heightSpacer(size.height * 0.015),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: Size(size.width, size.height * 0.06),
                      backgroundColor: const Color(0xFFF2F2F2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text('No',style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  ) ?? false;
}

Future createDataBaseLoaderDesign(context) {
  return showDialog(
     barrierDismissible: false,
     context: context,
     builder: (context) => AlertDialog(
     titlePadding: const EdgeInsets.only(),
     contentPadding: const EdgeInsets.all(0),
     backgroundColor: ColorConst.themeColor,
     content:Container(
       decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(20),
          color: ColorConst.white,
       ),
       height: MediaQuery.of(context).size.height *0.35,
      
       child: Column(
         children: [
           heightSpacer(MediaQuery.of(context).size.height * 0.02),
            Text('Please Wait',style: TextStyle(color: ColorConst.black,fontSize: MediaQuery.of(context).size.height * 0.03,fontWeight: FontWeight.bold  ),textAlign: TextAlign.center,),
            Text(' while createing your Profile',style: TextStyle(color: ColorConst.black,fontSize: MediaQuery.of(context).size.height * 0.022,fontWeight: FontWeight.w400  ),),
            LottieBuilder.asset('assets/images/databaselottie.json',height: MediaQuery.of(context).size.height * 0.2,),
            heightSpacer(MediaQuery.of(context).size.height * 0.02),
         ],
       ),
     ),
    ),
  );
}

// Punch Denied Dialog Box Design
void punchDeniedShowDialog(String msg, context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: ColorConst.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 50, color: Colors.redAccent),
            const SizedBox(height: 15),
            Text(
              "Punch Denied",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorConst.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              msg,
              style: TextStyle(
                fontSize: 16, 
                color: ColorConst.isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(c),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text(
                "OK",
                style: TextStyle(fontSize: 16, color: ColorConst.white),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> showGpsDisabledDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) {
      return const _GpsDialog();
    },
  ) ?? false;
}

class _GpsDialog extends StatefulWidget {
  const _GpsDialog({Key? key}) : super(key: key);

  @override
  State<_GpsDialog> createState() => _GpsDialogState();
}

class _GpsDialogState extends State<_GpsDialog> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.location_off, color: ColorConst.themeColor, size: 28),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Location Services Disabled',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: const Text(
        'Your GPS is currently turned off. Please enable location services to proceed.',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelString),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConst.themeColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            await Geolocator.openLocationSettings();
          },
          child: const Text('Settings', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS Background Location: Step 1 - Explanation dialog (shown BEFORE system prompt)
// Apple requires this to explain WHY you need "Always" background location.
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a pre-permission explanation dialog that explains WHY the app needs
/// background location. This must be shown BEFORE requesting system permission
/// to comply with Apple's guidelines.
///
/// Returns true if user taps "Continue" (allow to proceed with permission request).
/// Returns false if user taps "Not Now" (skip background location).
Future<bool> showIosBackgroundLocationExplanationDialog(BuildContext context) async {
  if (!Platform.isIOS) return true;
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ColorConst.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: ColorConst.themeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: ColorConst.themeColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Background Location Access',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: ColorConst.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'To accurately track your attendance and work location throughout your shift, this app needs to access your location even when running in the background.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, 
                color: ColorConst.isDark ? Colors.white60 : Colors.black54, 
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConst.isDark ? const Color(0xFF1E3A5F) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline, 
                    color: ColorConst.isDark ? Colors.blue.shade300 : Colors.blue.shade700, 
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'On the next screen, please select "Always Allow" to enable background tracking.',
                      style: TextStyle(
                        fontSize: 12, 
                        color: ColorConst.isDark ? Colors.white60 : Colors.black54, 
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConst.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Not Now', 
                  style: TextStyle(
                    fontSize: 14, 
                    color: ColorConst.isDark ? Colors.grey.shade400 : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ) ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS Background Location: Step 2 - Settings redirect dialog
// Shown when the user has denied "Always" and needs to go to Settings manually.
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a dialog directing the user to open iOS Settings to grant "Always"
/// background location access. Returns true if user clicked Open Settings, false if skipped.
Future<bool> showIosBackgroundLocationSettingsDialog(BuildContext context) async {
  if (!Platform.isIOS) return false;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ColorConst.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: ColorConst.isDark ? const Color(0xFF4C3000) : Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_disabled, 
                color: ColorConst.isDark ? Colors.orange.shade300 : Colors.orange.shade700, 
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enable Background Location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: ColorConst.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Background location access was not granted. To enable it:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, 
                color: ColorConst.isDark ? Colors.white60 : Colors.black54, 
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildStep('1', 'Open Settings'),
            _buildStep('2', 'Tap on this App → Location'),
            _buildStep('3', 'Select "Always"'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConst.themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx, true);
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings, color: Colors.white, size: 18),
                label: const Text('Open Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Skip for Now', 
                  style: TextStyle(
                    fontSize: 14, 
                    color: ColorConst.isDark ? Colors.grey.shade400 : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

Widget _buildStep(String number, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: ColorConst.themeColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Text(
          text, 
          style: TextStyle(
            fontSize: 14, 
            color: ColorConst.isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    ),
  );
}