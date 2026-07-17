import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_hrm/main.dart';
import 'package:tax_hrm/utils/colorsfile.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isDarkMode = false;
  bool _hasManualSetting = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    if (globalPrefs.containsKey('isDarkMode')) {
      _isDarkMode = globalPrefs.getBool('isDarkMode') ?? false;
      _hasManualSetting = true;
    } else {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
      _hasManualSetting = false;
    }
    ColorConst.isDark = _isDarkMode;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    if (!_hasManualSetting) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
      ColorConst.isDark = _isDarkMode;
      notifyListeners();
    }
  }

  void toggleTheme(bool value) async {
    _isDarkMode = value;
    _hasManualSetting = true;
    ColorConst.isDark = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  // _loadTheme removed since it is now synchronous in constructor
}
