import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  AppConfig.initialise(AppConfig.development);

  await Hive.initFlutter();
  await Hive.openBox<dynamic>(AppConstants.hiveBoxSettings);

  // Live backend — Supabase (auth, database, storage).
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: DriverApp()));
}
