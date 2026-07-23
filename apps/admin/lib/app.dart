import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';
import 'core/router/app_router.dart';

/// Root widget for the SpazaLink Admin Dashboard.
///
/// Uses [AppTheme.dark] — the admin dashboard has a dark navy theme
/// as per the official UI mockup (screens 13–16).
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: '${AppConstants.appName} Admin',
      debugShowCheckedModeBanner: AppConfig.instance.isDevelopment,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
