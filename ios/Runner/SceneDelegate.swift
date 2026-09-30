import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    private let appGroup = "group.com.hrmnewapp.taxhrm"
    private let punchTapKey = "widgetPunchTap"
    private let TAG = "🟠 [WidgetDebug] [SceneDelegate]"

    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("\(TAG) scene(willConnectTo:) called")
        
        // Cold start check: The URL is passed in connectionOptions when the app is launched from the widget
        if let url = connectionOptions.urlContexts.first?.url {
            print("\(TAG) Cold start URL found: \(url.absoluteString)")
            if url.scheme == "taxhrm" && url.host == "punch" {
                print("\(TAG) URL matches taxhrm://punch! Marking cold start flag.")
                markWidgetPunchTap()
            }
        } else {
            print("\(TAG) No URL found in connectionOptions")
        }
        
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("\(TAG) scene(openURLContexts:) called")
        
        if let url = URLContexts.first?.url {
            print("\(TAG) Warm start URL found: \(url.absoluteString)")
            if url.scheme == "taxhrm" && url.host == "punch" {
                print("\(TAG) URL matches taxhrm://punch! Marking flag and trying MethodChannel.")
                markWidgetPunchTap()
                
                // Warm start: try to invoke MethodChannel directly
                if let windowScene = scene as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let controller = window.rootViewController as? FlutterViewController {
                    let channel = FlutterMethodChannel(name: "punch_widget/open", binaryMessenger: controller.binaryMessenger)
                    channel.invokeMethod("open_punch", arguments: nil)
                    print("\(TAG) MethodChannel invoked directly from SceneDelegate")
                }
            }
        }
        
        super.scene(scene, openURLContexts: URLContexts)
    }
    
    // Also hook into foreground to process any flags just in case
    override func sceneWillEnterForeground(_ scene: UIScene) {
        print("\(TAG) sceneWillEnterForeground called")
        let sharedDefaults = UserDefaults(suiteName: appGroup)
        let wasTapped = sharedDefaults?.bool(forKey: punchTapKey) ?? false
        
        if wasTapped {
            print("\(TAG) Found pending tap flag in App Group on foreground, writing flutter flag")
            sharedDefaults?.removeObject(forKey: punchTapKey)
            sharedDefaults?.synchronize()
            
            UserDefaults.standard.set(true, forKey: "flutter.widgetPunchPending")
            UserDefaults.standard.synchronize()
            
            if let windowScene = scene as? UIWindowScene,
               let window = windowScene.windows.first,
               let controller = window.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(name: "punch_widget/open", binaryMessenger: controller.binaryMessenger)
                channel.invokeMethod("open_punch", arguments: nil)
            }
        }
        super.sceneWillEnterForeground(scene)
    }

    private func markWidgetPunchTap() {
        print("\(TAG) markWidgetPunchTap: writing flags")
        UserDefaults(suiteName: appGroup)?.set(true, forKey: punchTapKey)
        UserDefaults(suiteName: appGroup)?.synchronize()
        UserDefaults.standard.set(true, forKey: "flutter.widgetPunchPending")
        UserDefaults.standard.synchronize()
    }
}
