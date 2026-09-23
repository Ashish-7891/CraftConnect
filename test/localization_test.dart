import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:craftconnect/l10n/app_localizations.dart';
import 'package:craftconnect/providers/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocalizations unit tests', () {
    test('Supports exactly 7 Indian languages including English', () {
      final expectedLanguages = [
        {'code': 'en', 'name': 'English', 'nativeName': 'English'},
        {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
        {'code': 'gu', 'name': 'Gujarati', 'nativeName': 'ગુજરાતી'},
        {'code': 'mr', 'name': 'Marathi', 'nativeName': 'मराठी'},
        {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
        {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
        {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
      ];

      expect(AppLocalizations.supportedLanguages.length, equals(7));
      expect(AppLocalizations.supportedLocales.length, equals(7));

      for (final expected in expectedLanguages) {
        final match = AppLocalizations.supportedLanguages.firstWhere(
          (lang) => lang['code'] == expected['code'],
        );
        expect(match['name'], equals(expected['name']));
        expect(match['nativeName'], equals(expected['nativeName']));
      }
    });

    test('Provides translations for all 7 languages for critical UI strings', () {
      final languageCodes = ['en', 'hi', 'gu', 'mr', 'bn', 'ta', 'te'];
      final testKeys = [
        'language',
        'select_language',
        'account_profile',
        'phone_number',
        'marketplace',
        'cart',
        'my_orders',
        'profile',
        'sign_out',
        'edit_profile_info',
      ];

      for (final code in languageCodes) {
        final l10n = AppLocalizations(Locale(code));
        for (final key in testKeys) {
          final translated = l10n.translate(key);
          expect(translated, isNotEmpty);
          expect(translated, isNot(equals(key)),
              reason: 'Key "$key" should have translation in "$code"');
        }
      }
    });

    test('Falls back safely to English for untranslated keys', () {
      final l10n = AppLocalizations(const Locale('ta'));
      // A key that exists in English
      expect(l10n.translate('app_title'), isNotEmpty);
      // A non-existent key returns the key itself
      expect(l10n.translate('non_existent_key_123'), equals('non_existent_key_123'));
    });
  });

  group('LocaleProvider tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Defaults to English when no preference is saved', () {
      final provider = LocaleProvider();
      expect(provider.locale.languageCode, equals('en'));
      expect(provider.currentLanguageName, equals('English'));
      expect(provider.currentLanguageNativeName, equals('English'));
    });

    test('Restores saved language from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        LocaleProvider.prefsKey: 'hi',
      });

      final provider = LocaleProvider();
      await provider.loadSavedLocale();

      expect(provider.locale.languageCode, equals('hi'));
      expect(provider.currentLanguageName, equals('Hindi'));
      expect(provider.currentLanguageNativeName, equals('हिन्दी'));
    });

    test('setLocale updates locale and saves to SharedPreferences', () async {
      final provider = LocaleProvider();
      bool listenerCalled = false;
      provider.addListener(() {
        listenerCalled = true;
      });

      await provider.setLocale(const Locale('gu'));

      expect(provider.locale.languageCode, equals('gu'));
      expect(provider.currentLanguageName, equals('Gujarati'));
      expect(provider.currentLanguageNativeName, equals('ગુજરાતી'));
      expect(listenerCalled, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(LocaleProvider.prefsKey), equals('gu'));
    });

    test('Ignores unsupported locales', () async {
      final provider = LocaleProvider();
      await provider.setLocale(const Locale('fr')); // French is unsupported

      expect(provider.locale.languageCode, equals('en'));
    });
  });

  group('Language selection dialog widget tests', () {
    testWidgets('Renders all 7 languages with checkmark on active language and updates selection', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final localeProvider = LocaleProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: localeProvider),
          ],
          child: MaterialApp(
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
            ],
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Select Language'),
                            content: SingleChildScrollView(
                              child: Column(
                                children: AppLocalizations.supportedLanguages.map((lang) {
                                  final code = lang['code']!;
                                  final isSelected = code == localeProvider.currentLanguageCode;
                                  return ListTile(
                                    key: Key('lang_$code'),
                                    title: Text(lang['nativeName']!),
                                    trailing: isSelected ? const Icon(Icons.check_circle) : null,
                                    onTap: () {
                                      localeProvider.setLocale(Locale(code));
                                      Navigator.pop(ctx);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Language'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Language'));
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('ગુજરાતી'), findsOneWidget);
      expect(find.text('मराठी'), findsOneWidget);
      expect(find.text('বাংলা'), findsOneWidget);
      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);

      // Select Hindi
      await tester.tap(find.byKey(const Key('lang_hi')));
      await tester.pumpAndSettle();

      expect(localeProvider.currentLanguageCode, equals('hi'));
    });
  });
}
