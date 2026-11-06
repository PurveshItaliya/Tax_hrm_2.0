import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that manages user customization for the Punch Widget across
/// Flutter, Android (Glance), and iOS (WidgetKit).
class PunchWidgetCustomizationService {
  static final PunchWidgetCustomizationService instance =
      PunchWidgetCustomizationService._internal();

  PunchWidgetCustomizationService._internal();

  static const MethodChannel _channel = MethodChannel('punch_widget/open');

  static const String _keyColor = 'punch_widget_color';
  static const String _keyTransparency = 'punch_widget_transparency';
  static const String _keyDarkness = 'punch_widget_darkness';
  static const String _keyBlur = 'punch_widget_blur';

  bool _isSyncing = false;
  bool _hasPendingSync = false;

  // ValueNotifier to trigger reactive UI updates in Flutter in real-time
  final ValueNotifier<PunchWidgetSettings> settingsNotifier =
      ValueNotifier<PunchWidgetSettings>(const PunchWidgetSettings());

  PunchWidgetSettings get currentSettings => settingsNotifier.value;

  /// Initialize and load saved settings from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final color = prefs.getString(_keyColor) ?? 'blue';
      final transparency = prefs.getDouble(_keyTransparency) ?? 0.0;
      final darkness = prefs.getDouble(_keyDarkness) ?? 0.0;
      final blur = prefs.getDouble(_keyBlur) ?? 24.0;

      settingsNotifier.value = PunchWidgetSettings(
        color: color,
        transparency: transparency,
        darkness: darkness,
        blur: blur,
      );

      // Initial sync with native widgets
      await syncWithNative();
    } catch (e) {
      debugPrint("Error initializing PunchWidgetCustomizationService: $e");
    }
  }

  /// Update local memory state immediately for 60fps Flutter preview without spamming native channels
  void setLocalSettings({
    String? color,
    double? transparency,
    double? darkness,
    double? blur,
  }) {
    settingsNotifier.value = currentSettings.copyWith(
      color: color,
      transparency: transparency,
      darkness: darkness,
      blur: blur,
    );
  }

  /// Commit settings to storage and instantly sync with native Android & iOS widgets
  Future<bool> updateAndSyncSettings({
    String? color,
    double? transparency,
    double? darkness,
    double? blur,
  }) async {
    setLocalSettings(
      color: color,
      transparency: transparency,
      darkness: darkness,
      blur: blur,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyColor, currentSettings.color);
      await prefs.setDouble(_keyTransparency, currentSettings.transparency);
      await prefs.setDouble(_keyDarkness, currentSettings.darkness);
      await prefs.setDouble(_keyBlur, currentSettings.blur);
    } catch (e) {
      debugPrint("Error saving PunchWidgetCustomization: $e");
    }

    return await syncWithNative();
  }

  /// Backward-compatible alias for updateAndSyncSettings
  Future<bool> updateSettings({
    String? color,
    double? transparency,
    double? darkness,
    double? blur,
  }) async {
    return updateAndSyncSettings(
      color: color,
      transparency: transparency,
      darkness: darkness,
      blur: blur,
    );
  }

  /// Sync settings with Android Glance and iOS WidgetKit via MethodChannel instantly
  /// Uses a queue loop with a finally block so that it NEVER locks up or drops updates
  Future<bool> syncWithNative() async {
    if (_isSyncing) {
      _hasPendingSync = true;
      return true;
    }
    _isSyncing = true;
    try {
      while (true) {
        _hasPendingSync = false;
        final settingsToSync = currentSettings;
        await _channel.invokeMethod<bool>('update_widget_settings', {
          'color': settingsToSync.color,
          'transparency': settingsToSync.transparency,
          'darkness': settingsToSync.darkness,
          'blur': settingsToSync.blur,
        });

        // If settings changed while the channel call was executing, loop and sync the latest!
        if (!_hasPendingSync) {
          break;
        }
      }
      return true;
    } catch (e) {
      debugPrint("Native widget settings sync error: $e");
      return false;
    } finally {
      _isSyncing = false;
      _hasPendingSync = false;
    }
  }
}

/// Immutable data model for widget customization settings
/// Limited to 4 refined themes: 'blue', 'white', 'black', 'transparent'
class PunchWidgetSettings {
  final String color; // 'blue', 'white', 'black', 'transparent'
  final double transparency; // 0.0 (100% Solid / 0 Transparency) to 1.0 (Full Clear Glass)
  final double darkness; // 0.0 (darkness option removed)
  final double blur; // fixed default 24.0 px

  const PunchWidgetSettings({
    this.color = 'blue',
    this.transparency = 0.0, // Default to solid rich dark color (not washed out 0.70 light!)
    this.darkness = 0.0,
    this.blur = 24.0,
  });

  PunchWidgetSettings copyWith({
    String? color,
    double? transparency,
    double? darkness,
    double? blur,
  }) {
    return PunchWidgetSettings(
      color: color ?? this.color,
      transparency: transparency ?? this.transparency,
      darkness: darkness ?? this.darkness,
      blur: blur ?? this.blur,
    );
  }

  /// Dynamic Theme-Wise Font Color for "PUNCH" text:
  /// For 'white' theme, text is dark slate/black so it is completely readable!
  /// For 'black', 'blue', and 'transparent', text is crisp white.
  Color get textColor {
    if (color == 'white') {
      return const Color(0xFF0F172A);
    }
    return Colors.white;
  }

  /// Glass tint color for Flutter LiquidGlassLens preview
  Color get glassTintColor {
    if (color == 'black') {
      return Colors.transparent;
    }
    if (color == 'blue') {
      return const Color(0xFF0F49BB).withOpacity(0.15);
    }
    if (transparency <= 0.04) {
      return Colors.transparent;
    }
    final double op = (1.0 - transparency).clamp(0.05, 0.95);
    switch (color) {
      case 'white':
        return Colors.white.withOpacity(op.clamp(0.05, 0.85));
      case 'transparent':
      default:
        return const Color(0x18FFFFFF);
    }
  }

  /// Inner gradient colors for the widget preview
  /// Accurately produces:
  /// - 'black': Deep Pitch Dark Black (#000000 to #0A0A0A) - NEVER grey!
  /// - 'blue': Rich Dark Primary Blue (#104EC8 to #0A368A) - matching primary theme!
  /// - 'white': Crisp Solid White (#FFFFFF to #F8FAFC)
  /// - 'transparent': Clear Liquid Glass
  List<Color> get innerGradientColors {
    if (color == 'transparent' || transparency >= 0.98) {
      return [
        Colors.white.withOpacity(0.20),
        Colors.white.withOpacity(0.06),
      ];
    }

    Color topColor;
    Color bottomColor;

    switch (color) {
      case 'white':
        topColor = Colors.white;
        bottomColor = const Color(0xFFF8FAFC);
        break;
      case 'black':
        // TRUE DARK BLACK (Deep jet black, never washed out grey)
        topColor = const Color(0xFF000000);
        bottomColor = const Color(0xFF0A0A0A);
        break;
      case 'blue':
      default:
        // RICH DARK PRIMARY THEME BLUE (matching ColorConst.darkGreenColor & themeColor)
        topColor = const Color(0xFF104EC8);
        bottomColor = const Color(0xFF0A368A);
        break;
    }

    if (transparency <= 0.02) {
      return [topColor, bottomColor];
    }

    final double opacity = (1.0 - transparency).clamp(0.15, 1.0);
    return [
      topColor.withOpacity(opacity),
      bottomColor.withOpacity(opacity),
    ];
  }

  /// Blur sigma for LiquidGlassLens
  double get blurSigma => blur.clamp(0.0, 50.0);
}
