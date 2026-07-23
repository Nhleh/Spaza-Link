// Firebase options for the STAGING environment — admin app.
// TODO: Run `flutterfire configure --project=spazalink-staging //              --out=lib/firebase_options_staging.dart`
//       from apps/admin/ to populate real credentials.
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

  static const FirebaseOptions web     = FirebaseOptions(apiKey: 'STAGING_WEB_API_KEY',     appId: 'STAGING_WEB_APP_ID',     messagingSenderId: 'STAGING_SENDER_ID', projectId: 'spazalink-staging', storageBucket: 'spazalink-staging.firebasestorage.app');
  static const FirebaseOptions android = FirebaseOptions(apiKey: 'STAGING_ANDROID_API_KEY', appId: 'STAGING_ANDROID_APP_ID', messagingSenderId: 'STAGING_SENDER_ID', projectId: 'spazalink-staging', storageBucket: 'spazalink-staging.firebasestorage.app');
  static const FirebaseOptions ios     = FirebaseOptions(apiKey: 'STAGING_IOS_API_KEY',     appId: 'STAGING_IOS_APP_ID',     messagingSenderId: 'STAGING_SENDER_ID', projectId: 'spazalink-staging', storageBucket: 'spazalink-staging.firebasestorage.app', iosBundleId: 'com.spazalink.admin.staging');
}
