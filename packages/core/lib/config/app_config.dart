/// Application environment enumeration.
enum AppEnvironment { development, staging, production }

/// Runtime configuration for a specific deployment environment.
///
/// Each Flutter flavor (`development`, `staging`, `production`) calls
/// [AppConfig.initialise] with its own values before [runApp].
/// All other code reads from [AppConfig.instance] — never from env vars directly.
class AppConfig {
  AppConfig._({
    required this.environment,
  });

  final AppEnvironment environment;

  static AppConfig? _instance;

  static AppConfig get instance {
    assert(_instance != null, 'AppConfig.initialise() must be called first.');
    return _instance!;
  }

  static void initialise(AppConfig config) {
    assert(_instance == null, 'AppConfig.initialise() must only be called once.');
    _instance = config;
  }

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;

  String get environmentLabel => switch (environment) {
        AppEnvironment.development => 'DEV',
        AppEnvironment.staging => 'STAGING',
        AppEnvironment.production => '',
      };

  // ── Pre-built configurations ───────────────────────────────────────────────

  static AppConfig get development =>
      AppConfig._(environment: AppEnvironment.development);

  static AppConfig get staging =>
      AppConfig._(environment: AppEnvironment.staging);

  static AppConfig get production =>
      AppConfig._(environment: AppEnvironment.production);
}
