import 'package:spazalink_core/core.dart';

import 'bootstrap.dart';

/// Production flavor entrypoint: `flutter build appbundle --flavor prod -t lib/main_prod.dart`.
Future<void> main() => bootstrap(AppConfig.production);
