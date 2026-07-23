import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialise(AppConfig.development);

  await _initFirebase();

  runApp(const ProviderScope(child: AdminApp()));
}

Future<void> _initFirebase() async {
  if (!kFirebaseConfigured) {
    debugPrint(
      '[SpazaLink] Firebase not configured. '
      'Set kFirebaseConfigured = true in firebase_options.dart after running '
      'flutterfire configure --project=spazalink-dev (from apps/admin/).',
    );
    return;
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (AppConfig.instance.useEmulators) {
    await _connectEmulators();
  }

  if (AppConfig.instance.isProduction) {
    _configureCrashlytics();
  }
}

Future<void> _connectEmulators() async {
  const host = 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  debugPrint('[SpazaLink] Connected to Firebase Emulator Suite on $host');
}

void _configureCrashlytics() {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
