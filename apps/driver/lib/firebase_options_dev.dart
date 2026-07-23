// Firebase options for the DEV environment — driver app.
// TODO: Run `flutterfire configure --project=spazalink-dev //              --out=lib/firebase_options_dev.dart`
//       from apps/driver/ to populate real credentials.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

const bool kFirebaseConfigured = false;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default: throw UnsupportedError('Platform not supported.');
    }
  }

  static const FirebaseOptions web     = FirebaseOptions(apiKey: 'DEV_WEB_API_KEY',     appId: 'DEV_WEB_APP_ID',     messagingSenderId: 'DEV_SENDER_ID', projectId: 'spazalink-dev', storageBucket: 'spazalink-dev.firebasestorage.app');
  static const FirebaseOptions android = FirebaseOptions(apiKey: 'DEV_ANDROID_API_KEY', appId: 'DEV_ANDROID_APP_ID', messagingSenderId: 'DEV_SENDER_ID', projectId: 'spazalink-dev', storageBucket: 'spazalink-dev.firebasestorage.app');
  static const FirebaseOptions ios     = FirebaseOptions(apiKey: 'DEV_IOS_API_KEY',     appId: 'DEV_IOS_APP_ID',     messagingSenderId: 'DEV_SENDER_ID', projectId: 'spazalink-dev', storageBucket: 'spazalink-dev.firebasestorage.app', iosBundleId: 'com.spazalink.driver.dev');
}
