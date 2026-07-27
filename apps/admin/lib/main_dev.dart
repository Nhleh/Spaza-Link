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
import 'firebase_options_dev.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialise(AppConfig.development);

  // Never let a Firebase/emulator hiccup blank the whole app — always run it.
  try {
    await _initFirebase();
  } catch (e) {
    debugPrint('[SpazaLink-Admin-DEV] Firebase init failed: $e');
  }

  runApp(const ProviderScope(child: AdminApp()));
}

/// Master switch for the backend.
///   true  → local Firebase Emulator Suite (see run-emulators.ps1)
///   false → LIVE Firebase cloud (project spazalink-d8a59)
const bool kUseEmulators = true;

Future<void> _initFirebase() async {
  if (!kFirebaseConfigured) {
    debugPrint('[SpazaLink-Admin-DEV] Firebase not configured — running offline.');
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kUseEmulators) {
    await _connectEmulators();
  }
}

Future<void> _connectEmulators() async {
  const host = 'localhost';
  // Timeouts so an unreachable emulator can never hang startup (and blank the UI).
  await FirebaseAuth.instance
      .useAuthEmulator(host, 9099)
      .timeout(const Duration(seconds: 5), onTimeout: () {});
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseStorage.instance
      .useStorageEmulator(host, 9199)
      .timeout(const Duration(seconds: 5), onTimeout: () {});
  debugPrint('[SpazaLink-Admin-DEV] Connected to Firebase Emulator Suite on $host');
}
