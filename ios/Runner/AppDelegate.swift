import Flutter
import UIKit
import flutter_local_notifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
    
    // UNUserNotificationCenter delegate is handled automatically by 
    // flutter_local_notifications and firebase_messaging plugins.
    // Explicitly setting it to `self` here can break their delegate swizzling.
    
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "LocationTimeLines")

    // Register native Liquid Glass tab bar platform view.
    // On iOS 26+ the UITabBar automatically renders the real
    // Liquid Glass material with spring animation and haptics.
    if let registrar = registrar(forPlugin: "NativeLiquidGlassTabBar") {
      let factory = NativeLiquidGlassTabBarFactory(
        messenger: registrar.messenger()
      )
      registrar.register(factory, withId: "native_liquid_glass_tab_bar")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
      if #available(iOS 16.0, *) {
          UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
      } else {
          application.applicationIconBadgeNumber = 0
      }
      super.applicationDidBecomeActive(application)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
