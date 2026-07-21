import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A single tab item for [NativeLiquidGlassBar].
///
/// [symbol] is the SF Symbol name shown when the tab is not selected.
/// [selectedSymbol] is the SF Symbol name shown when the tab is selected.
/// On non-iOS platforms the symbols are ignored and the [label] is used only.
class LiquidTabItem {
  const LiquidTabItem({
    required this.label,
    required this.symbol,
    this.selectedSymbol = '',
  });

  final String label;
  final String symbol;
  final String selectedSymbol;
}

/// On iOS, renders a real native UITabBar that automatically uses
/// Apple's Liquid Glass material on iOS 26+.
///
/// On all other platforms it falls back to [fallback] (or a plain
/// [BottomNavigationBar] if no fallback is supplied).
class NativeLiquidGlassBar extends StatefulWidget {
  const NativeLiquidGlassBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.tintColor = const Color(0xFF007AFF),
    this.fallback,
  });

  final List<LiquidTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Accent colour forwarded to UITabBar.tintColor on iOS.
  final Color tintColor;

  /// Optional widget shown on non-iOS platforms.
  final Widget? fallback;

  @override
  State<NativeLiquidGlassBar> createState() => _NativeLiquidGlassBarState();
}

class _NativeLiquidGlassBarState extends State<NativeLiquidGlassBar> {
  MethodChannel? _channel;

  bool get _isNativeSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Parameters sent to the native side as a creation-params map.
  Map<String, Object> get _params => {
        'labels': widget.items.map((e) => e.label).toList(),
        'symbols': widget.items.map((e) => e.symbol).toList(),
        'selectedSymbols': widget.items
            .map((e) => e.selectedSymbol.isEmpty ? e.symbol : e.selectedSymbol)
            .toList(),
        'selectedIndex': widget.currentIndex,
        'tintColor': widget.tintColor.toARGB32(),
      };

  @override
  void didUpdateWidget(covariant NativeLiquidGlassBar old) {
    super.didUpdateWidget(old);
    if (!_isNativeSupported) return;

    // Sync just the selected index for a smooth native spring animation.
    if (old.currentIndex != widget.currentIndex) {
      _channel?.invokeMethod('setIndex', widget.currentIndex);
    }

    // Sync labels / symbols / tint if anything structural changed.
    if (old.items != widget.items || old.tintColor != widget.tintColor) {
      _channel?.invokeMethod('update', _params);
    }
  }

  Future<void> _onPlatformViewCreated(int viewId) async {
    final ch = MethodChannel('native_liquid_glass_bar/$viewId');
    _channel = ch;

    ch.setMethodCallHandler((call) async {
      if (call.method == 'onSelected') {
        final index = call.arguments as int;
        if (index != widget.currentIndex) {
          widget.onTap(index);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isNativeSupported) {
      return widget.fallback ??
          BottomNavigationBar(
            currentIndex: widget.currentIndex,
            onTap: widget.onTap,
            items: widget.items
                .map(
                  (e) => BottomNavigationBarItem(
                    icon: const Icon(Icons.circle_outlined),
                    activeIcon: const Icon(Icons.circle),
                    label: e.label,
                  ),
                )
                .toList(),
          );
    }

    // Height: 52 visible bar + home-indicator inset.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      width: double.infinity,
      height: 52 + bottomInset,
      child: UiKitView(
        viewType: 'native_liquid_glass_tab_bar',
        creationParams: _params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }
}
