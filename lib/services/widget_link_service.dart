import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:tax_hrm/models/fixeddat.dart';
import 'package:tax_hrm/page/authpages/loginpage.dart';
import 'package:tax_hrm/page/bottom_bar_screen.dart';
import 'package:tax_hrm/page/home/selfie_punch_screen.dart';
import 'package:tax_hrm/services/fcm_token_service.dart';
import 'package:tax_hrm/utils/navigation.dart';
import 'package:tax_hrm/utils/saveData/savelocaldata.dart';
import 'package:tax_hrm/api/companiapi.dart';
import 'package:tax_hrm/models/company/getallcompany.dart';
import 'package:tax_hrm/provider/home_provider.dart';
import 'package:provider/provider.dart';
import 'package:tax_hrm/provider/splashprovider.dart';
import 'package:tax_hrm/page/splash/splashPage.dart';
class WidgetLinkService {
  static final WidgetLinkService instance = WidgetLinkService._internal();
  WidgetLinkService._internal();

  static const MethodChannel _channel = MethodChannel('punch_widget/open');
  bool _isNavigating = false;

  void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open_punch') {
        handlePunchWidgetOpen();
      }
    });
  }

  Future<void> handlePunchWidgetOpen() async {
    if (_isNavigating) {
      debugPrint("WidgetLinkService: handlePunchWidgetOpen ignored (already navigating)");
      return;
    }
    _isNavigating = true;
    Future.delayed(const Duration(seconds: 2), () {
      _isNavigating = false;
    });

    debugPrint("WidgetLinkService: handlePunchWidgetOpen called");
    final context = FcmTokenService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint("WidgetLinkService ERROR: currentContext is null, cannot navigate");
      return;
    }
    debugPrint("WidgetLinkService: currentContext is available");

    // Fast path: curentUser already pre-loaded in main() — no async wait needed
    if (curentUser != null) {
      debugPrint("WidgetLinkService: curentUser is not null, taking fast path to _WidgetPunchWrapper");
      nextscreenRemove(context, const _WidgetPunchWrapper());
      return;
    }

    // SLOW PATH: App was completely closed (Cold Start)
    // We MUST push the splash screen so that ALL services, tokens, and location configurations
    // are initialized exactly as they are during a normal app launch.
    // The SplashProvider is configured to route to _WidgetPunchWrapper when it finishes.
    debugPrint("WidgetLinkService: curentUser is null, taking SLOW path. Setting pendingNavigationPage = _WidgetPunchWrapper");
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    splashProvider.pendingNavigationPage = const _WidgetPunchWrapper();
    
    // Using a normal push so that if they press back from Splash, it closes the app cleanly
    debugPrint("WidgetLinkService: pushing ShowSpleshPage");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => ShowSpleshPage()),
      (route) => false,
    );
  }
}

/// A thin wrapper that shows the punch screen immediately.
/// Has a back action that exits to the home bottom bar.
class _WidgetPunchWrapper extends StatelessWidget {
  const _WidgetPunchWrapper();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // When user presses back, go to main app shell
        nextscreenRemove(context, const AnimatedBottomBar());
        return false;
      },
      child: const SelfiePunchScreen(isFromWidget: true),
    );
  }
}
