import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fixeddat.dart';
import '../utils/colorsfile.dart';
import '../utils/saveData/savelocaldata.dart';
import '../utils/titlesfile.dart';

class DeveloperModeService {
  static const MethodChannel _channel =
      MethodChannel('com.hrmnewapp.taxhrm/developer_mode');

  /// Whitelisted Developer EmpIds that bypass Developer Mode restriction:
  /// - 1210: Purvesh Developer
  /// - 361918: Dhrumil Developer
  /// - 391938: Umang Developer
  static const Set<int> whitelistedEmpIds = {1210, 361918, 391938};

  /// Whitelisted CompanyIds that bypass Developer Mode restriction:
  /// - 1092: Swift for testing company
  static const Set<int> whitelistedCompanyIds = {1092};

  /// Checks if the given employee or company matches the developer whitelist.
  static Future<bool> isWhitelistedDeveloper({
    dynamic empId,
    dynamic companyId,
  }) async {
    // 1. Check explicit empId
    if (empId != null) {
      final parsed = int.tryParse(empId.toString());
      if (parsed != null && whitelistedEmpIds.contains(parsed)) {
        return true;
      }
    }

    // 2. Check explicit companyId
    if (companyId != null) {
      final parsed = int.tryParse(companyId.toString());
      if (parsed != null && whitelistedCompanyIds.contains(parsed)) {
        return true;
      }
    }

    // 3. Check curentUser global variable
    try {
      if (curentUser != null) {
        final currentEmpId = int.tryParse(
          (curentUser['Id'] ?? curentUser['EmpId'] ?? '').toString(),
        );
        if (currentEmpId != null && whitelistedEmpIds.contains(currentEmpId)) {
          return true;
        }

        final currentCompId = int.tryParse(
          (curentUser['CompanyId'] ?? '').toString(),
        );
        if (currentCompId != null &&
            whitelistedCompanyIds.contains(currentCompId)) {
          return true;
        }
      }
    } catch (_) {}

    // 4. Check selectedcurentcompany global variable
    try {
      if (selectedcurentcompany != null) {
        final compId = selectedcurentcompany!.companyId;
        if (whitelistedCompanyIds.contains(compId)) {
          return true;
        }
      }
    } catch (_) {}

    // 5. Fallback: Check persistent storage
    try {
      final String rawUser = await SaveUser().getUserDatas();
      if (rawUser.isNotEmpty) {
        final dynamic decoded = jsonDecode(rawUser);
        if (decoded is Map) {
          final savedEmpId = int.tryParse(
            (decoded['Id'] ?? decoded['EmpId'] ?? '').toString(),
          );
          if (savedEmpId != null && whitelistedEmpIds.contains(savedEmpId)) {
            return true;
          }
          final savedCompId = int.tryParse(
            (decoded['CompanyId'] ?? '').toString(),
          );
          if (savedCompId != null &&
              whitelistedCompanyIds.contains(savedCompId)) {
            return true;
          }
        }
      }
    } catch (_) {}

    try {
      final String rawCompany = await SaveUser().getselectedcompany();
      if (rawCompany.isNotEmpty) {
        final dynamic decoded = jsonDecode(rawCompany);
        if (decoded is Map) {
          final savedCompId = int.tryParse(
            (decoded['CompanyId'] ?? decoded['companyId'] ?? '').toString(),
          );
          if (savedCompId != null &&
              whitelistedCompanyIds.contains(savedCompId)) {
            return true;
          }
        }
      }
    } catch (_) {}

    return false;
  }

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
  /// Whitelisted developers (1210, 361918, 391938) and company (1092) are never restricted.
  static Future<bool> isDeveloperModeRestricted([
    dynamic empId,
    dynamic companyId,
  ]) async {
    // In debug builds, allow Punch In/Out regardless of Developer Mode status
    if (!kReleaseMode) {
      debugPrint(
        '[DeveloperModeService] Debug build: Developer Mode check bypassed (allowed).',
      );
      return false;
    }

    // Check if user or company is in developer whitelist
    if (await isWhitelistedDeveloper(empId: empId, companyId: companyId)) {
      debugPrint(
        '[DeveloperModeService] Whitelisted developer detected ($empId / $companyId). Developer Mode check bypassed.',
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
    BuildContext context, [
    dynamic empId,
    dynamic companyId,
  ]) async {
    if (!context.mounted) return;

    // Suppress warning dialog for whitelisted developers
    if (await isWhitelistedDeveloper(empId: empId, companyId: companyId)) {
      debugPrint(
        '[DeveloperModeService] Warning dialog suppressed for whitelisted developer.',
      );
      return;
    }

    final bool isAndroid = Platform.isAndroid;
    final String title = isAndroid
        ? developerOptionsDetectedString
        : developerModeDetectedString;
    final String description = isAndroid
        ? developerOptionsShortDescString
        : developerModeShortDescString;

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
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.developer_mode_rounded,
                    size: 30,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            foregroundColor: const Color(0xFF475569),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              cancelString,
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConst.themeColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await openDeveloperSettings();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.settings_outlined,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  openSettingsString,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
