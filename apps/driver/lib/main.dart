import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spazalink_core/core.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait + landscape: drivers mount phones on dashboards in landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  AppConfig.initialise(AppConfig.development);

  await _initHive();
  await _initFirebase();

  runApp(const ProviderScope(child: DriverApp()));
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  // Typed adapters registered here in Phase 4 after code generation.
  await Hive.openBox<dynamic>(AppConstants.hiveBoxOrderQueue);
  await Hive.openBox<dynamic>(AppConstants.hiveBoxSettings);
  await Hive.openBox<dynamic>(AppConstants.hiveBoxUser);
}

Future<void> _initFirebase() async {
  if (!kFirebaseConfigured) {
    debugPrint(
      '[SpazaLink] Firebase not configured. '
      'Set kFirebaseConfigured = true in firebase_options.dart after running '
      'flutterfire configure --project=spazalink-dev (from apps/driver/).',
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
