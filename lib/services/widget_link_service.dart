import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:tax_hrm/main.dart' show globalPrefs, iosWidgetPunchLaunch;
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
      debugPrint("🟠 [WidgetDebug] MethodChannel received call: ${call.method}");
      if (call.method == 'open_punch') {
        // Clear the UserDefaults flag in case it was set but MethodChannel
        // fired first (warm-start race condition on iOS).
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          debugPrint("🟠 [WidgetDebug] clearing 'widgetPunchPending' from globalPrefs via MethodChannel handler");
          globalPrefs.remove('widgetPunchPending');
        }
        handlePunchWidgetOpen();
      }
    });

    // iOS cold-start: AppDelegate writes "flutter.widgetPunchPending" to UserDefaults
    // when the widget is tapped. If the MethodChannel call arrived before this
    // handler was registered, the flag is still set — consume it now.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint("🟠 [WidgetDebug] WidgetLinkService.initialize() reading globalPrefs for 'widgetPunchPending'");
      final bool pending = globalPrefs.getBool('widgetPunchPending') ?? false;
      debugPrint("🟠 [WidgetDebug] initialize() pending = $pending");
      if (pending) {
        debugPrint("🟠 [WidgetDebug] clearing 'widgetPunchPending' from globalPrefs via initialize()");
        globalPrefs.remove('widgetPunchPending');
        // Delay one frame so the navigator and providers are fully mounted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint("🟠 [WidgetDebug] calling handlePunchWidgetOpen() from initialize() postFrameCallback");
          handlePunchWidgetOpen();
        });
      }
    }
  }

  Future<void> handlePunchWidgetOpen() async {
    if (_isNavigating) {
      debugPrint("🟠 [WidgetDebug] handlePunchWidgetOpen ignored (already navigating)");
      return;
    }
    
    // If we cold-started and already placed WidgetPunchWrapper as the home screen,
    // we don't need to push it again via the MethodChannel!
    if (iosWidgetPunchLaunch) {
      debugPrint("🟠 [WidgetDebug] handlePunchWidgetOpen ignored because iosWidgetPunchLaunch is true (already on screen)");
      return;
    }

    _isNavigating = true;
    Future.delayed(const Duration(seconds: 2), () {
      _isNavigating = false;
    });

    debugPrint("🟠 [WidgetDebug] handlePunchWidgetOpen executing");
    final context = FcmTokenService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint("🟠 [WidgetDebug] ERROR: currentContext is null, cannot navigate");
      return;
    }
    debugPrint("🟠 [WidgetDebug] currentContext is available");

    // Fast path: curentUser already pre-loaded in main() — no async wait needed
    if (curentUser != null) {
      debugPrint("🟠 [WidgetDebug] curentUser is not null, taking fast path to WidgetPunchWrapper");
      nextscreenRemove(context, const WidgetPunchWrapper());
      return;
    }

    // SLOW PATH: App was completely closed (Cold Start)
    debugPrint("🟠 [WidgetDebug] curentUser is null, taking SLOW path. Setting pendingNavigationPage = WidgetPunchWrapper");
    final splashProvider = Provider.of<SplashProvider>(context, listen: false);
    splashProvider.pendingNavigationPage = const WidgetPunchWrapper();
    
    // Using a normal push so that if they press back from Splash, it closes the app cleanly
    debugPrint("🟠 [WidgetDebug] pushing ShowSpleshPage");
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => ShowSpleshPage()),
      (route) => false,
    );
  }
}

/// A thin wrapper that shows the punch screen immediately.
/// Has a back action that exits to the home bottom bar.
class WidgetPunchWrapper extends StatelessWidget {
  const WidgetPunchWrapper({super.key});

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
