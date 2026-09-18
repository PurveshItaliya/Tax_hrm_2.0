import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/location_tracking_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LocationTrackingBannerWidget
///
/// iOS-only slim animated banner that sits below the AppBar on the home screen
/// during an active Punch session. It communicates the real-time state of the
/// Geolocator stream so the user always knows whether location tracking is
/// working correctly.
///
/// States (driven by BackgroundLocationController.iosTrackingStatus):
///   'active'            → Green pill  "Location Tracking Active"
///   'reduced_accuracy'  → Amber pill  "Tracking with Reduced Accuracy"
///   'permission_denied' → Red pill    "Location Permission Required"  + Settings
///   'location_disabled' → Red pill    "Location Services Disabled"    + Settings
///   'inactive'          → Hidden (zero height)
///
/// Android: renders nothing (guarded by Platform.isIOS).
/// ─────────────────────────────────────────────────────────────────────────────
class LocationTrackingBannerWidget extends StatelessWidget {
  const LocationTrackingBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Android: this banner is not needed — a system foreground-service
    // notification already communicates the tracking state to Android users.
    if (!Platform.isIOS) return const SizedBox.shrink();

    return Consumer<LocationTrackingProvider>(
      builder: (context, controller, _) {
        final String status = controller.iosTrackingStatus;

        // When inactive, collapse the banner with an animated height transition
        final bool visible = status != 'inactive';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: visible ? 38.0 : 0.0,
          width: double.infinity,
          child: visible
              ? _BannerContent(status: status)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  final String status;
  const _BannerContent({required this.status});

  @override
  Widget build(BuildContext context) {
    final _BannerTheme theme = _themeFor(status);

    return Container(
      width: double.infinity,
      height: 38,
      color: theme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Leading icon
          Icon(theme.icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),

          // Status text
          Expanded(
            child: Text(
              theme.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          // "Open Settings" action for permission/service issues
          if (theme.showSettingsButton) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await Geolocator.openAppSettings();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: const Text(
                  'Open Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _BannerTheme _themeFor(String status) {
    switch (status) {
      case 'active':
        return _BannerTheme(
          backgroundColor: const Color(0xFF10B981), // emerald green
          icon: Icons.location_on_rounded,
          label: 'Location Tracking Active',
          showSettingsButton: false,
        );
      case 'reduced_accuracy':
        return _BannerTheme(
          backgroundColor: const Color(0xFFF59E0B), // amber
          icon: Icons.location_searching_rounded,
          label: 'Tracking with Reduced Accuracy — Enable Precise Location',
          showSettingsButton: true,
        );
      case 'permission_denied':
        return _BannerTheme(
          backgroundColor: const Color(0xFFEF4444), // red
          icon: Icons.location_disabled_rounded,
          label: 'Location Permission Required for Tracking',
          showSettingsButton: true,
        );
      case 'location_disabled':
        return _BannerTheme(
          backgroundColor: const Color(0xFFEF4444), // red
          icon: Icons.location_off_rounded,
          label: 'Location Services Disabled — Tracking Paused',
          showSettingsButton: true,
        );
      default: // 'inactive' or unknown
        return _BannerTheme(
          backgroundColor: Colors.transparent,
          icon: Icons.location_off,
          label: '',
          showSettingsButton: false,
        );
    }
  }
}

class _BannerTheme {
  final Color backgroundColor;
  final IconData icon;
  final String label;
  final bool showSettingsButton;

  const _BannerTheme({
    required this.backgroundColor,
    required this.icon,
    required this.label,
    required this.showSettingsButton,
  });
}
