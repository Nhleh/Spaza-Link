import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spazalink_core/core.dart';
import 'core/router/app_router.dart';

/// Root widget for the SpazaLink Driver App.
///
/// Uses [AppTheme.light] — green header/accents on white, same
/// brand family as the Customer App but with delivery-focused navigation.
class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(driverRouterProvider);

    return MaterialApp.router(
      title: '${AppConstants.appName} Driver',
      debugShowCheckedModeBanner: AppConfig.instance.isDevelopment,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
