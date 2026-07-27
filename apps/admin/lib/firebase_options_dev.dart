// Firebase options for the DEV environment — admin app.
// Aligned to the shared dev Firebase project `spazalink-d8a59` (same project
// the customer app uses) so the admin manages the same data.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

const bool kFirebaseConfigured = true;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS:     return ios;
      default: throw UnsupportedError('Platform not supported.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAv5Ei0-rxNwvMqMP865ohcR_vCTFuaPII',
    appId: '1:1082805554542:web:admin-dev',
    messagingSenderId: '1082805554542',
    projectId: 'spazalink-d8a59',
    storageBucket: 'spazalink-d8a59.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAv5Ei0-rxNwvMqMP865ohcR_vCTFuaPII',
    appId: '1:1082805554542:android:a269218eb8efc2c9ec057f',
    messagingSenderId: '1082805554542',
    projectId: 'spazalink-d8a59',
    storageBucket: 'spazalink-d8a59.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDLZRnbzy8YYM9gYbZDYihkckYV4CWKRhE',
    appId: '1:1082805554542:ios:c0ab6a6da25118e8ec057f',
    messagingSenderId: '1082805554542',
    projectId: 'spazalink-d8a59',
    storageBucket: 'spazalink-d8a59.firebasestorage.app',
    iosBundleId: 'com.spazalink.admin.dev',
  );
}
