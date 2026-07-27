import 'dart:io';
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
import 'firebase_options_dev.dart';
import 'features/cart/data/hive_cart_repository.dart';
import 'features/cart/providers/cart_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  AppConfig.initialise(AppConfig.development);

  final cartRepo = await _initHive();
  await _initFirebase();

  runApp(ProviderScope(
    overrides: [
      cartRepositoryProvider.overrideWithValue(cartRepo),
    ],
    child: const CustomerApp(),
  ));
}

Future<HiveCartRepository> _initHive() async {
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(AppConstants.hiveBoxSettings);
  await Hive.openBox<dynamic>(AppConstants.hiveBoxUser);
  return HiveCartRepository.create();
}

/// Master switch for the backend.
///   true  → local Firebase Emulator Suite (see run-emulators.ps1)
///   false → LIVE Firebase cloud (project spazalink-d8a59)
const bool kUseEmulators = true;

Future<void> _initFirebase() async {
  if (!kFirebaseConfigured) {
    debugPrint('[SpazaLink-DEV] Firebase not configured — running offline.');
    return;
  }

  // On Android the native FirebaseInitProvider auto-initialises the [DEFAULT]
  // app from google-services.json before Dart runs. Calling initializeApp from
  // Dart then throws [core/duplicate-app]. The Dart-side Firebase.apps list is
  // empty until we initialise, so it can't guard this — catch the duplicate
  // instead and carry on with the already-initialised default app.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    debugPrint('[SpazaLink-DEV] Firebase already initialised natively — reusing [DEFAULT].');
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kUseEmulators) {
    await _connectEmulators();
  }
}

Future<void> _connectEmulators() async {
  // Android emulators reach the host machine via 10.0.2.2, not localhost
  // (localhost on the device points at the device itself). iOS simulators
  // and desktop can use localhost directly.
  final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
  try {
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    debugPrint('[SpazaLink-DEV] Connected to Firebase Emulator Suite on $host');
  } catch (e) {
    // Don't let an unreachable emulator suite block app startup.
    debugPrint('[SpazaLink-DEV] Could not connect to Firebase emulators: $e');
  }
}
