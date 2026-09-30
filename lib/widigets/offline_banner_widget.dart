// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/internetcheck.dart';

/// A slim horizontal "OFFLINE MODE" strip shown at the top of all
/// non-auth screens when the app is offline.
class OfflineBannerWidget extends StatelessWidget {
  const OfflineBannerWidget({super.key});

  static const Color _bannerColor = Color(0xFFE57373);

  @override
  Widget build(BuildContext context) {
    final bool isOffline =
        context.select<InternetConnectionProvider, bool>(
      (p) => p.connectionType == 0,
    );
    final double topPadding = MediaQuery.paddingOf(context).top;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isOffline ? topPadding + 24.0 : 0.0,
      width: double.infinity,
      color: isOffline ? _bannerColor : Colors.transparent,
      child: isOffline
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: topPadding),
                const SizedBox(
                  height: 24.0,
                  child: Center(
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        'OFFLINE MODE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Screen widget class names for Splash and Auth screens where the offline banner
/// MUST NOT be shown.
const Set<String> _authScreenNames = {
  'ShowSpleshPage',
  'UserloginPage',
  'LoginPage',
  'RegistrationPage',
  'Registration',
  'OtpVerification',
  'ForgotPassword',
  'SelectPackageScreen',
  'SplashPage',
};

const Set<String> _authRoutes = {
  '/',
  '/splash',
  '/login',
  '/otp',
  '/otpVerification',
  '/registration',
  '/forgotPassword',
  '/selectPackage',
  '/userLogin',
};

/// Wraps [child] page with the top offline banner IF it is NOT a splash or auth screen.
class OfflineBannerWrapper extends StatelessWidget {
  final Widget child;
  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String widgetName = child.runtimeType.toString();
    if (_authScreenNames.contains(widgetName)) {
      return child;
    }

    final ModalRoute<Object?>? route = ModalRoute.of(context);
    final String routeName = route?.settings.name ?? '';
    if (_authRoutes.contains(routeName)) {
      return child;
    }

    return Column(
      children: [
        const OfflineBannerWidget(),
        Expanded(child: child),
      ],
    );
  }
}

