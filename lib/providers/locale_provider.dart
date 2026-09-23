import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  static const String prefsKey = 'craftconnect_selected_locale';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  String get currentLanguageCode => _locale.languageCode;

  LocaleProvider() {
    loadSavedLocale();
  }

  String get currentLanguageName {
    final match = AppLocalizations.supportedLanguages.firstWhere(
      (lang) => lang['code'] == _locale.languageCode,
      orElse: () => {'name': 'English'},
    );
    return match['name'] ?? 'English';
  }

  String get currentLanguageNativeName {
    final match = AppLocalizations.supportedLanguages.firstWhere(
      (lang) => lang['code'] == _locale.languageCode,
      orElse: () => {'nativeName': 'English'},
    );
    return match['nativeName'] ?? 'English';
  }

  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(prefsKey);
      if (savedCode != null &&
          AppLocalizations.supportedLanguages.any((lang) => lang['code'] == savedCode)) {
        _locale = Locale(savedCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!AppLocalizations.supportedLanguages.any((lang) => lang['code'] == newLocale.languageCode)) {
      return;
    }

    if (_locale.languageCode == newLocale.languageCode) return;

    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, newLocale.languageCode);
      debugPrint('Saved locale preference: ${newLocale.languageCode}');
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }
}
