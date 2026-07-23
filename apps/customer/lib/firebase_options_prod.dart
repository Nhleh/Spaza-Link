// Firebase options for the PRODUCTION environment.
// TODO: Run `flutterfire configure --project=spazalink-prod \
//              --out=lib/firebase_options_prod.dart`
//       from apps/customer/ to replace these placeholders.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

const bool kFirebaseConfigured = false;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  // Replace ALL values below after running flutterfire configure for prod.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PROD_WEB_API_KEY',
    appId: 'PROD_WEB_APP_ID',
    messagingSenderId: 'PROD_SENDER_ID',
    projectId: 'spazalink-prod',
    storageBucket: 'spazalink-prod.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PROD_ANDROID_API_KEY',
    appId: 'PROD_ANDROID_APP_ID',
    messagingSenderId: 'PROD_SENDER_ID',
    projectId: 'spazalink-prod',
    storageBucket: 'spazalink-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PROD_IOS_API_KEY',
    appId: 'PROD_IOS_APP_ID',
    messagingSenderId: 'PROD_SENDER_ID',
    projectId: 'spazalink-prod',
    storageBucket: 'spazalink-prod.firebasestorage.app',
    iosBundleId: 'com.spazalink.customer',
  );
}
