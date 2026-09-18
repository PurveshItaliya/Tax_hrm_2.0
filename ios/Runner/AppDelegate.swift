import Flutter
import UIKit
import flutter_local_notifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var widgetMethodChannel: FlutterMethodChannel?
  private let appGroup = "group.com.hrmnewapp.taxhrm"
  private let punchTapKey = "widgetPunchTap"
  private let TAG = "🟠 [WidgetDebug]"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("\(TAG) didFinishLaunchingWithOptions called")
    print("\(TAG) launchOptions keys: \(launchOptions?.keys.map { $0.rawValue } ?? [])")

    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "LocationTimeLines")

    // Register native Liquid Glass tab bar platform view.
    if let registrar = registrar(forPlugin: "NativeLiquidGlassTabBar") {
      let factory = NativeLiquidGlassTabBarFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "native_liquid_glass_tab_bar")
      let cleanupChannel = FlutterMethodChannel(name: "native_liquid_glass_bar/cleanup", binaryMessenger: registrar.messenger())
      cleanupChannel.setMethodCallHandler { (call, result) in
        if call.method == "cleanup" { result(nil) } else { result(FlutterMethodNotImplemented) }
      }
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      widgetMethodChannel = FlutterMethodChannel(name: "punch_widget/open", binaryMessenger: controller.binaryMessenger)
      print("\(TAG) widgetMethodChannel set up successfully")
    } else {
      print("\(TAG) ERROR: could not get FlutterViewController from window")
    }

    // Cold-start check via launchOptions URL
    if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
      print("\(TAG) launchOptions URL found: \(url.absoluteString)")
      if url.scheme == "taxhrm" && url.host == "punch" {
        print("\(TAG) launchOptions URL matches taxhrm://punch → marking widget tap")
        markWidgetPunchTap()
      }
    } else {
      print("\(TAG) launchOptions has NO URL key")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    print("\(TAG) applicationDidBecomeActive called")
    if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    } else {
        application.applicationIconBadgeNumber = 0
    }
    super.applicationDidBecomeActive(application)

    // Check shared App Group for widget tap flag
    let sharedDefaults = UserDefaults(suiteName: appGroup)
    let wasTapped = sharedDefaults?.bool(forKey: punchTapKey) ?? false
    print("\(TAG) applicationDidBecomeActive: appGroup[\(punchTapKey)] = \(wasTapped)")
    if wasTapped {
        sharedDefaults?.removeObject(forKey: punchTapKey)
        sharedDefaults?.synchronize()
        print("\(TAG) appGroup flag cleared, writing flutter.widgetPunchPending and invoking MethodChannel")
        UserDefaults.standard.set(true, forKey: "flutter.widgetPunchPending")
        UserDefaults.standard.synchronize()
        widgetMethodChannel?.invokeMethod("open_punch", arguments: nil)
    }

    // Also check standard UserDefaults flutter prefix
    let stdPending = UserDefaults.standard.bool(forKey: "flutter.widgetPunchPending")
    print("\(TAG) applicationDidBecomeActive: standard UserDefaults[flutter.widgetPunchPending] = \(stdPending)")
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    print("\(TAG) application(_:open:url:) called with URL: \(url.absoluteString)")
    print("\(TAG)   scheme='\(url.scheme ?? "nil")'  host='\(url.host ?? "nil")'")
    if url.scheme == "taxhrm" && url.host == "punch" {
      print("\(TAG) URL matches taxhrm://punch → marking tap and invoking MethodChannel")
      markWidgetPunchTap()
      widgetMethodChannel?.invokeMethod("open_punch", arguments: nil)
      print("\(TAG) MethodChannel invokeMethod('open_punch') called (widgetMethodChannel nil? \(widgetMethodChannel == nil))")
      return true
    }
    print("\(TAG) URL did NOT match taxhrm://punch — forwarding to super")
    return super.application(app, open: url, options: options)
  }

  private func markWidgetPunchTap() {
    print("\(TAG) markWidgetPunchTap: writing flags to appGroup + standard UserDefaults")
    UserDefaults(suiteName: appGroup)?.set(true, forKey: punchTapKey)
    UserDefaults(suiteName: appGroup)?.synchronize()
    UserDefaults.standard.set(true, forKey: "flutter.widgetPunchPending")
    UserDefaults.standard.synchronize()
    print("\(TAG) markWidgetPunchTap: done")
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
