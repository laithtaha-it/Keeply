import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static const _storageKey = 'keeply_language';

  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_storageKey);

    if (languageCode == 'en' || languageCode == 'ar') {
      _locale = Locale(languageCode!);
    } else {
      _locale = const Locale('ar');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'ar' && languageCode != 'en') {
      return;
    }

    final nextLocale = Locale(languageCode);

    if (_locale == nextLocale) {
      return;
    }

    _locale = nextLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, languageCode);
  }
}
