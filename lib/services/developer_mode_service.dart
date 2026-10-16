import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colorsfile.dart';
import '../utils/titlesfile.dart';

class DeveloperModeService {
  static const MethodChannel _channel =
      MethodChannel('com.hrmnewapp.taxhrm/developer_mode');

  /// Detects whether Developer Options (Android) or Developer Mode (iOS) is enabled on the device.
  static Future<bool> isDeveloperModeEnabled() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    try {
      final bool? isEnabled =
          await _channel.invokeMethod<bool>('isDeveloperModeEnabled');
      return isEnabled ?? false;
    } catch (e) {
      debugPrint('[DeveloperModeService] Error checking developer mode: $e');
      return false;
    }
  }

  /// In release builds, blocks Punch In/Out when Developer Options or Developer Mode is enabled.
  /// In debug builds, allows Punch In/Out regardless of Developer Mode status.
  static Future<bool> isDeveloperModeRestricted() async {
    // In debug builds, allow Punch In/Out regardless of Developer Mode status
    if (!kReleaseMode) {
      debugPrint(
        '[DeveloperModeService] Debug build: Developer Mode check bypassed (allowed).',
      );
      return false;
    }

    // In release builds, block Punch In/Out if Developer Mode is enabled
    final bool isDevMode = await isDeveloperModeEnabled();
    debugPrint(
      '[DeveloperModeService] Release build: Developer Mode enabled = $isDevMode',
    );
    return isDevMode;
  }

  /// Opens the device settings screen so the user can turn off Developer Options/Mode.
  static Future<bool> openDeveloperSettings() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    try {
      final bool? success =
          await _channel.invokeMethod<bool>('openDeveloperSettings');
      return success ?? false;
    } catch (e) {
      debugPrint('[DeveloperModeService] Error opening developer settings: $e');
      return false;
    }
  }

  /// Displays a warning dialog alerting the user that Developer Options/Mode must be disabled to punch.
  static Future<void> showDeveloperModeWarningDialog(
    BuildContext context,
  ) async {
    if (!context.mounted) return;

    final bool isAndroid = Platform.isAndroid;
    final String title = isAndroid
        ? developerOptionsDetectedString
        : developerModeDetectedString;
    final String description = isAndroid
        ? developerOptionsDescString
        : developerModeDescString;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.developer_mode_rounded,
                    size: 44,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: ColorConst.themeColor,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            cancelString,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ColorConst.themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConst.themeColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await openDeveloperSettings();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: Flexible(
                            child: Text(
                              openSettingsString,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
