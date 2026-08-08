import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'supabase_config.dart';

/// Shared bootstrap for every flavor. Each `main_*.dart` calls this with its
/// own [AppConfig]. The backend is Supabase (auth, database, storage).
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialise(config);

  // Live backend — Supabase (auth, database, storage).
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const ProviderScope(child: AdminApp()));
}
