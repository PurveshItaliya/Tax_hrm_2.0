import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../translations/app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  static String currentLanguageCode = 'en';

  String get currentLanguage => currentLanguageCode;

  LanguageProvider() {
    _loadLanguage();
  }

  void changeLanguage(String languageCode) async {
    currentLanguageCode = languageCode;
    Intl.defaultLocale = languageCode;
    await initializeDateFormatting(languageCode, null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    notifyListeners();
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    currentLanguageCode = prefs.getString('languageCode') ?? 'en';
    Intl.defaultLocale = currentLanguageCode;
    await initializeDateFormatting(currentLanguageCode, null);
    notifyListeners();
  }

  static String translate(String key, String defaultValue) {
    return _translations[currentLanguageCode]?[key] ??
        _translations['en']?[key] ??
        defaultValue;
  }

  static final Map<String, Map<String, String>> _translations = appTranslations;
}
