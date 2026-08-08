import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/security/inactivity_guard.dart';
import 'supabase_config.dart';
import 'features/cart/data/hive_cart_repository.dart';
import 'features/cart/providers/cart_provider.dart';

/// Shared bootstrap for every flavor. Each `main_*.dart` calls this with its
/// own [AppConfig]. The backend is Supabase (auth, database, storage).
Future<void> bootstrap(AppConfig config) async {
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

  AppConfig.initialise(config);

  // Live backend — Supabase (auth, database, storage).
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final cartRepo = await _initHive();

  // Security: drop a restored-but-stale session so reopening the app after a
  // period of inactivity requires a fresh login (spec #1).
  await enforceFreshSessionOnStartup();

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
