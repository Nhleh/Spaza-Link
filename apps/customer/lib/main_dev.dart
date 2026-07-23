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

Future<void> _initFirebase() async {
  if (!kFirebaseConfigured) {
    debugPrint('[SpazaLink-DEV] Firebase not configured — running offline.');
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await _connectEmulators();
}

Future<void> _connectEmulators() async {
  const host = 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  debugPrint('[SpazaLink-DEV] Connected to Firebase Emulator Suite on $host');
}
