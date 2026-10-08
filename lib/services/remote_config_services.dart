import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigServices {
  RemoteConfigServices._privateConstructor();
  static final RemoteConfigServices instance = RemoteConfigServices._privateConstructor();

  bool faceVerify = false;

  /// Single switch for the complete Face Verification feature
  /// (punch-screen registration dialog, live verification on punch,
  /// and the re-register tile in Settings). Toggle "faceVerify" in
  /// Firebase Remote Config to turn it ON/OFF without an app update.
  static bool get isFaceVerifyEnabled => instance.faceVerify;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First read from local cache so that we have a fallback if offline
    faceVerify = prefs.getBool('faceVerify_cache') ?? false;

    try {
      final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set to 0 so we fetch every time the app opens
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: Duration.zero,
      ));

      await remoteConfig.setDefaults(const {
        "faceVerify": false,
      });

      await remoteConfig.fetchAndActivate();
      
      faceVerify = remoteConfig.getBool("faceVerify");
      
      // Store locally for offline use
      await prefs.setBool('faceVerify_cache', faceVerify);
      debugPrint("[RemoteConfigServices] fetch success, using cached faceVerify=$faceVerify ");

    } catch (e) {
      // In case of error (e.g. offline), we just keep the cached value
      debugPrint("[RemoteConfigServices] fetch failed, using cached faceVerify=$faceVerify : $e");
    }
  }
}
