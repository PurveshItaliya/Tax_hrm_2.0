import Flutter
import UIKit

// MARK: - Factory

final class NativeLiquidGlassTabBarFactory:
    NSObject,
    FlutterPlatformViewFactory {

    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        NativeLiquidGlassTabBarView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            arguments: args
        )
    }
}

// MARK: - Platform View

final class NativeLiquidGlassTabBarView:
    NSObject,
    FlutterPlatformView,
    UITabBarDelegate {

    private let containerView: UIView
    private let tabBar: UITabBar
    private let channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewId: Int64,
        messenger: FlutterBinaryMessenger,
        arguments: Any?
    ) {
        containerView = UIView(frame: frame)
        tabBar = UITabBar(frame: .zero)

        channel = FlutterMethodChannel(
            name: "native_liquid_glass_bar/\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        configureView()
        apply(arguments)

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(nil)
                return
            }

            switch call.method {
            case "setIndex":
                if let index = call.arguments as? Int {
                    self.select(index: index)
                }
                result(nil)

            case "update":
                self.apply(call.arguments)
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func view() -> UIView {
        containerView
    }

    // MARK: - Setup

    private func configureView() {
        containerView.backgroundColor = .clear
        containerView.isOpaque = false

        // Transparent so iOS 26 Liquid Glass material shows through
        tabBar.backgroundColor = .clear
        tabBar.isTranslucent = true
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(tabBar)

        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tabBar.topAnchor.constraint(equalTo: containerView.topAnchor),
            tabBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        /*
         Do NOT add a custom blur, backgroundImage or backgroundEffect here.
         On iOS 26+, UITabBar automatically renders the genuine
         Liquid Glass material, smooth spring-animated selector pill,
         native haptics, dark-mode adaptation and SF Symbol morphing.
         Any additional visual layer placed on top will obscure it.
        */
    }

    // MARK: - Apply Parameters

    private func apply(_ arguments: Any?) {
        guard let params = arguments as? [String: Any] else { return }

        let labels          = params["labels"]          as? [String] ?? []
        let symbols         = params["symbols"]         as? [String] ?? []
        let selectedSymbols = params["selectedSymbols"] as? [String] ?? symbols

        var tabItems: [UITabBarItem] = []

        for index in labels.indices {
            let normalSymbol   = index < symbols.count         ? symbols[index]         : "circle"
            let selectedSymbol = index < selectedSymbols.count ? selectedSymbols[index] : normalSymbol

            let item = UITabBarItem(
                title: labels[index],
                image: UIImage(systemName: normalSymbol),
                selectedImage: UIImage(systemName: selectedSymbol)
            )
            item.tag = index
            tabItems.append(item)
        }

        tabBar.setItems(tabItems, animated: false)

        if let colorNumber = params["tintColor"] as? NSNumber {
            tabBar.tintColor = uiColor(fromARGB: colorNumber.uint32Value)
        }

        select(index: params["selectedIndex"] as? Int ?? 0)
    }

    // MARK: - Selection

    private func select(index: Int) {
        guard
            let items = tabBar.items,
            items.indices.contains(index)
        else { return }
        tabBar.selectedItem = items[index]
    }

    // MARK: - UITabBarDelegate

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        UISelectionFeedbackGenerator().selectionChanged()
        channel.invokeMethod("onSelected", arguments: item.tag)
    }

    // MARK: - Helpers

    private func uiColor(fromARGB argb: UInt32) -> UIColor {
        let a = CGFloat((argb >> 24) & 0xFF) / 255
        let r = CGFloat((argb >> 16) & 0xFF) / 255
        let g = CGFloat((argb >>  8) & 0xFF) / 255
        let b = CGFloat( argb        & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
