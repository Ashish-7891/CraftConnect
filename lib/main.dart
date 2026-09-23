import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/cart_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/firebase_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInitialized = false;
  String? firebaseInitError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('Firebase successfully initialized for CraftConnect');
  } catch (e) {
    debugPrint('Firebase initialization warning/error: $e');
    firebaseInitError = e.toString();
  }

  runApp(
    CraftConnectApp(
      firebaseInitialized: firebaseInitialized,
      initError: firebaseInitError,
    ),
  );
}

class CraftConnectApp extends StatefulWidget {
  final bool firebaseInitialized;
  final String? initError;

  const CraftConnectApp({
    super.key,
    required this.firebaseInitialized,
    this.initError,
  });

  @override
  State<CraftConnectApp> createState() => _CraftConnectAppState();
}

class _CraftConnectAppState extends State<CraftConnectApp> {
  late bool _isFirebaseReady;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isFirebaseReady = widget.firebaseInitialized;
    _error = widget.initError;
  }

  Future<void> _retryFirebaseInit() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      setState(() {
        _isFirebaseReady = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'CraftConnect',
            theme: AppTheme.lightTheme,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: _isFirebaseReady
                ? const SplashScreen()
                : FirebaseSetupScreen(
                    errorMessage: _error,
                    onRetry: _retryFirebaseInit,
                  ),
          );
        },
      ),
    );
  }
}
