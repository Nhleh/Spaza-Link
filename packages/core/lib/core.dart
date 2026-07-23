/// SpazaLink Core Package
///
/// Re-exports all public APIs from the core package. Import this file in app
/// code rather than importing individual files directly.
library spazalink_core;

// Config
export 'config/app_config.dart';

// Constants
export 'constants/app_constants.dart';
export 'constants/route_constants.dart';
export 'constants/firestore_constants.dart';

// Theme
export 'theme/app_colors.dart';
export 'theme/app_spacing.dart';
export 'theme/app_theme.dart';
export 'theme/app_typography.dart';

// Utils
export 'utils/currency_formatter.dart';
export 'utils/validators.dart';
export 'utils/extensions.dart';

// Errors
export 'errors/app_exception.dart';
export 'errors/failure.dart';

// Models
export 'models/gps_location.dart';
export 'models/user_model.dart';
export 'models/shop_model.dart';
export 'models/category_model.dart';
export 'models/product_model.dart';
export 'models/cart_item_model.dart';
export 'models/order_item_model.dart';
export 'models/order_model.dart';
export 'models/delivery_model.dart';

// Repositories (interfaces)
export 'repositories/auth_repository.dart';
export 'repositories/category_repository.dart';
export 'repositories/product_repository.dart';
export 'repositories/cart_repository.dart';
export 'repositories/order_repository.dart';
export 'repositories/delivery_repository.dart';

// Services
export 'services/sync_service.dart';

// Providers
export 'providers/connectivity_provider.dart';

// Widgets
export 'widgets/empty_state_widget.dart';
export 'widgets/loading_overlay.dart';
export 'widgets/offline_banner.dart';
export 'widgets/spaza_button.dart';
export 'widgets/spaza_text_field.dart';
