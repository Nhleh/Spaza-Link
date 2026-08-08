import 'package:spazalink_core/core.dart';

import 'bootstrap.dart';

/// Default entrypoint (`flutter run` with no target). Boots the development
/// configuration on the Supabase backend.
Future<void> main() => bootstrap(AppConfig.development);
