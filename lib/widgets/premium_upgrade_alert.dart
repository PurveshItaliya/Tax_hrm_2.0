// ignore_for_file: use_super_parameters

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:tax_hrm/services/fcm_token_service.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

class AppUpgradeWrapper extends StatelessWidget {
  final Widget child;
  const AppUpgradeWrapper({Key? key, required this.child}) : super(key: key);

  static final upgraderInstance = Upgrader(
    durationUntilAlertAgain: const Duration(seconds: 0),
    debugDisplayAlways: false,
    debugLogging: true,
  );

  @override
  Widget build(BuildContext context) {
    return PremiumUpgradeAlert(
      showIgnore: false,
      showLater: false,
      barrierDismissible: false,
      upgrader: upgraderInstance,
      child: child,
    );
  }
}

// ─── Custom Upgrade Alert ─────────────────────────────────────────────────────
class PremiumUpgradeAlert extends UpgradeAlert {
  PremiumUpgradeAlert({
    super.key,
    super.upgrader,
    super.child,
    super.showIgnore,
    super.showLater,
    super.barrierDismissible,
  });

  @override
  UpgradeAlertState createState() => _PremiumUpgradeAlertState();
}

class _PremiumUpgradeAlertState extends UpgradeAlertState {
  @override
  void showTheDialog({
    Key? key,
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool barrierDismissible,
    required UpgraderMessages messages,
  }) {
    if (!mounted) return;

    // Save the last alerted date (required by upgrader internals)
    widget.upgrader.saveLastAlerted();

    final navContext = FcmTokenService.navigatorKey.currentContext;
    if (navContext == null) return;

    showDialog(
      context: navContext,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.zero,
            child: _buildDialogContent(context),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    // Fetch app version properly platform-wise
    String newVersion = '';
    if (Platform.isAndroid) {
      newVersion = widget.upgrader.currentAppStoreVersion ?? '';
    } else if (Platform.isIOS) {
      // On iOS, App Store version can be null if not live yet or due to region.
      // Fallback to extracting from message or using installed version.
      newVersion = widget.upgrader.currentAppStoreVersion ?? widget.upgrader.currentInstalledVersion ?? '';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Gradient Header ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorConst.themeColor,
                  ColorConst.darkGreenColor,
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Update Available',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                if (newVersion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Version $newVersion',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── Body ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A new version of TAX HRM is ready for you.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please update the app to continue. This update includes important improvements and bug fixes.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Feature highlights
                _buildFeatureRow(
                    Icons.speed_rounded, 'Better performance and stability'),
                const SizedBox(height: 10),
                _buildFeatureRow(
                    Icons.security_rounded, 'Security and data improvements'),
                const SizedBox(height: 10),
                _buildFeatureRow(
                    Icons.auto_fix_high_rounded, 'Bug fixes and refinements'),
                const SizedBox(height: 24),

                // Full-width Update button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConst.themeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      if (Platform.isAndroid) {
                        widget.upgrader.sendUserToAppStore();
                      } else if (Platform.isIOS) {
                        widget.upgrader.sendUserToAppStore();
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Update Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Mandatory note
                Center(
                  child: Text(
                    'This update is required to continue using the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: ColorConst.themeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ColorConst.themeColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF3A3A3A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
