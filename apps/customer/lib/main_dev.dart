import 'package:spazalink_core/core.dart';

import 'bootstrap.dart';

/// Dev flavor entrypoint: `flutter run --flavor dev -t lib/main_dev.dart`.
Future<void> main() => bootstrap(AppConfig.development);
