// File generated for CraftConnect (Smart India Hackathon)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for CraftConnect.
/// Configured for project `craftconnect-3cd55`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCZ8QYqrZB--UXaILgfn0YiIcQLj3U3Sfw',
    appId: '1:1044742355627:web:craftconnectweb001',
    messagingSenderId: '1044742355627',
    projectId: 'craftconnect-3cd55',
    authDomain: 'craftconnect-3cd55.firebaseapp.com',
    storageBucket: 'craftconnect-3cd55.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZ8QYqrZB--UXaILgfn0YiIcQLj3U3Sfw',
    appId: '1:1044742355627:android:dd2607b42e8370afc815ee',
    messagingSenderId: '1044742355627',
    projectId: 'craftconnect-3cd55',
    storageBucket: 'craftconnect-3cd55.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCZ8QYqrZB--UXaILgfn0YiIcQLj3U3Sfw',
    appId: '1:1044742355627:ios:craftconnectios001',
    messagingSenderId: '1044742355627',
    projectId: 'craftconnect-3cd55',
    storageBucket: 'craftconnect-3cd55.firebasestorage.app',
    iosBundleId: 'com.sih.craftconnect.craftconnect',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCZ8QYqrZB--UXaILgfn0YiIcQLj3U3Sfw',
    appId: '1:1044742355627:windows:craftconnectwin001',
    messagingSenderId: '1044742355627',
    projectId: 'craftconnect-3cd55',
    storageBucket: 'craftconnect-3cd55.firebasestorage.app',
  );
}
