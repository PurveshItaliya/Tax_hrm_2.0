// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:tax_hrm/services/permission_flow_service.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

/// Reusable custom permission dialog.
///
/// Used for:
///   - Pre-permission explanation (before every system dialog).
///   - Permanent-denial settings redirect.
///   - Legacy background-location flows (kept for backward compatibility).
class PermissionDialogWidget extends StatelessWidget {
  final String title;
  final String message;
  final String primaryButtonText;
  final String? secondaryButtonText; // null = no secondary button
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final IconData icon;
  final Color? iconColor;

  const PermissionDialogWidget({
    super.key,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.secondaryButtonText,
    required this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.icon = Icons.lock_outline,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedIconColor = iconColor ?? ColorConst.themeColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: ColorConst.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: resolvedIconColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: resolvedIconColor, size: 36),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConst.black,
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ColorConst.isDark ? Colors.white60 : Colors.black54,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),

            // Primary button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: resolvedIconColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onPrimaryPressed,
                child: Text(
                  primaryButtonText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Secondary / dismiss button
            if (secondaryButtonText != null && onSecondaryPressed != null) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onSecondaryPressed,
                  child: Text(
                    secondaryButtonText!,
                    style: TextStyle(
                      fontSize: 14, 
                      color: ColorConst.isDark ? Colors.grey.shade400 : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ── Pre-permission explanation dialogs ──────────────────────────────────────
  // Each shows BEFORE the corresponding system permission dialog.
  // Returns true  → user tapped "Continue" (proceed to system dialog).
  // Returns false → user tapped "Not Now"  (skip this permission).
  // ===========================================================================

  /// Pre-notification explanation dialog.
  static Future<bool> showNotificationExplanationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PermissionDialogWidget(
        icon: Icons.notifications_active_outlined,
        title: 'Enable Notifications',
        message:
            'Allow notifications to receive Punch In, Punch Out, attendance '
            'reminders, and important work updates.',
        primaryButtonText: 'Continue',
        secondaryButtonText: 'Not Now',
        onPrimaryPressed: () => Navigator.pop(ctx, true),
        onSecondaryPressed: () => Navigator.pop(ctx, false),
      ),
    );
    return result ?? false;
  }

  /// Pre-camera explanation dialog.
  static Future<bool> showCameraExplanationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PermissionDialogWidget(
        icon: Icons.camera_alt_outlined,
        title: 'Camera Access Required',
        message:
            'Allow camera access to capture your attendance selfie and '
            'complete punch-in / punch-out verification.',
        primaryButtonText: 'Continue',
        onPrimaryPressed: () => Navigator.pop(ctx, true),
      ),
    );
    return result ?? false;
  }

  /// Pre-foreground-location explanation dialog (Android & iOS).
  static Future<bool> showForegroundLocationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PermissionDialogWidget(
        icon: Icons.location_on_outlined,
        title: 'Location Access Required',
        message:
            'Allow location access while using the app to verify your Punch In '
            'and Punch Out location accurately.',
        primaryButtonText: 'Continue',
        onPrimaryPressed: () => Navigator.pop(ctx, true),
      ),
    );
    return result ?? false;
  }

  /// Pre-background-location explanation dialog (Android only).
  static Future<bool> showBackgroundLocationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PermissionDialogWidget(
        icon: Icons.my_location,
        title: 'Background Location',
        message:
            'Your organisation tracks your work location during office hours '
            '(Punch In to Punch Out). Background location ensures attendance '
            'and movement are recorded even when the app is minimised or closed.',
        primaryButtonText: 'Continue',
        onPrimaryPressed: () => Navigator.pop(ctx, true),
      ),
    );
    return result ?? false;
  }

  // ===========================================================================
  // ── Combined Pre-permission explanation dialog ──────────────────────────────
  // Shown ONCE listing all pending permissions before system dialogs.
  // ===========================================================================

  static Future<bool> showCombinedExplanationDialog(
      BuildContext context, List<PermissionType> types) async {
      
    // Filter display list: if both foreground and background are pending, only show background in the UI.
    List<PermissionType> displayTypes = List.from(types);
    if (displayTypes.contains(PermissionType.foregroundLocation) &&
        displayTypes.contains(PermissionType.backgroundLocation)) {
      displayTypes.remove(PermissionType.foregroundLocation);
    }

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: ColorConst.white,
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: ColorConst.themeColor, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Permissions Required',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        color: ColorConst.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'The following permissions are required to use the selfie punch feature:',
                style: TextStyle(
                  fontSize: 14, 
                  color: ColorConst.isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ...displayTypes.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPermissionItem(type),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConst.themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  static Widget _buildPermissionItem(PermissionType type) {
    IconData icon;
    String title;
    String desc;
    switch (type) {
      case PermissionType.notification:
        icon = Icons.notifications_active_outlined;
        title = 'Notifications';
        desc = 'To receive Punch In, Punch Out and attendance reminders.';
        break;
      case PermissionType.camera:
        icon = Icons.camera_alt_outlined;
        title = 'Camera';
        desc = 'To capture your photo for attendance verification.';
        break;
      case PermissionType.foregroundLocation:
        icon = Icons.location_on_outlined;
        title = 'Location';
        desc = 'To verify your work location for attendance.';
        break;
      case PermissionType.backgroundLocation:
        icon = Icons.my_location;
        title = 'Background Location';
        desc = 'To ensure attendance and movement are recorded during office hours.';
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorConst.themeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: ColorConst.themeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 14,
                  color: ColorConst.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc, 
                style: TextStyle(
                  fontSize: 12, 
                  color: ColorConst.isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ── Permanently-denied dialog ───────────────────────────────────────────────
  // Shown ONLY when a permission is permanently disabled.
  // App Settings are opened ONLY from here — never on a first request.
  // ===========================================================================

  /// Returns true if the user tapped "Open Settings", false if "Cancel".
  static Future<bool> showPermanentlyDeniedDialog(
      BuildContext context, PermissionType type) async {
    final String label = _permissionLabel(type);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PermissionDialogWidget(
        icon: Icons.lock_open_outlined,
        iconColor: Colors.orange,
        title: '$label Disabled',
        message:
            'This permission has been permanently disabled. Please enable '
            '"$label" from App Settings to continue using attendance features.',
        primaryButtonText: 'Open Settings',
        secondaryButtonText: 'Cancel',
        onPrimaryPressed: () => Navigator.pop(ctx, true),
        onSecondaryPressed: () => Navigator.pop(ctx, false),
      ),
    );
    return result ?? false;
  }

  static String _permissionLabel(PermissionType type) {
    switch (type) {
      case PermissionType.notification:
        return 'Notifications';
      case PermissionType.camera:
        return 'Camera';
      case PermissionType.foregroundLocation:
        return 'Location';
      case PermissionType.backgroundLocation:
        return 'Background Location';
    }
  }

  // ===========================================================================
  // ── Legacy helpers (kept for backward compatibility) ────────────────────────
  // ===========================================================================

  /// Pre-permission explanation dialog for background location (legacy).
  static Future<bool> showPrePermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PermissionDialogWidget(
        icon: Icons.my_location,
        title: 'Allow Background Location',
        message:
            'To accurately record your attendance and automatically detect '
            'arrival and departure at assigned work locations, this app requires '
            'access to your location even when the app is running in the '
            'background. Your location is used only for attendance, travel '
            'history, and customer visit verification during working hours.',
        primaryButtonText: 'Continue',
        secondaryButtonText: 'Not Now',
        onPrimaryPressed: () => Navigator.pop(ctx, true),
        onSecondaryPressed: () => Navigator.pop(ctx, false),
      ),
    );
    return result ?? false;
  }

  /// Settings-upgrade dialog when iOS user selected "Keep Only While Using".
  static Future<bool> showEnableAlwaysDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PermissionDialogWidget(
        icon: Icons.settings_backup_restore,
        title: 'Enable Background Location',
        message:
            "Background attendance tracking requires 'Always' location access. "
            "Without it, automatic check-in/out won't work while the app is in "
            "the background.\n\nTap 'Open Settings' → Location → Always.",
        primaryButtonText: 'Open Settings',
        secondaryButtonText: 'Not Now',
        onPrimaryPressed: () => Navigator.pop(ctx, true),
        onSecondaryPressed: () => Navigator.pop(ctx, false),
      ),
    );
    return result ?? false;
  }

  /// Denied dialog for legacy location flows.
  static Future<bool> showPermissionDeniedDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PermissionDialogWidget(
        icon: Icons.location_disabled,
        title: 'Location Permission Required',
        message:
            'Without location permission, attendance tracking and punch '
            'verification will not work properly. Please open Settings to grant '
            'location access.',
        primaryButtonText: 'Open Settings',
        secondaryButtonText: 'Cancel',
        onPrimaryPressed: () => Navigator.pop(ctx, true),
        onSecondaryPressed: () => Navigator.pop(ctx, false),
      ),
    );
    return result ?? false;
  }

  /// Custom foreground-location dialog (legacy — used by provider directly).
  static Future<bool> showCustomLocationForegroundDialog(BuildContext context) async {
    return showForegroundLocationDialog(context);
  }

  /// Custom background-location Always dialog (legacy — used by provider directly).
  static Future<bool> showCustomLocationAlwaysDialog(BuildContext context) async {
    return showBackgroundLocationDialog(context);
  }
}
