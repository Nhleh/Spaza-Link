import 'package:spazalink_core/core.dart';

import 'bootstrap.dart';

/// Staging flavor entrypoint: `flutter run --flavor staging -t lib/main_staging.dart`.
Future<void> main() => bootstrap(AppConfig.staging);
