/// Application-wide constants for SpazaLink.
abstract final class AppConstants {
  // ── App identity ───────────────────────────────────────────────────────────

  static const String appName = 'SpazaLink';
  static const String appTagline = 'Stronger Together. Cheaper Together.';
  static const String appVersion = '1.0.0';

  // ── Business rules ─────────────────────────────────────────────────────────

  /// Minimum order value in cents (R500.00).
  static const int minOrderCents = 50000;

  /// Delivery fee in cents for orders below the free delivery threshold (R135.00).
  static const int deliveryFeeCents = 13500;

  /// Orders at or above this amount (cents) qualify for free delivery (R1,750.00).
  static const int freeDeliveryThresholdCents = 175000;

  /// Markup added to the admin's base price to get the customer-facing price.
  /// The admin enters a base price; customers pay base × (1 + markup) and the
  /// markup is the platform's profit. e.g. base R100 → customer pays R115.
  static const double productMarkup = 0.15; // 15%

  /// Marks a base price (cents) up to the customer-facing price (cents).
  static int customerPriceCents(int baseCents) =>
      (baseCents * (1 + productMarkup)).round();

  // ── Order number format ────────────────────────────────────────────────────

  /// Prefix for all SpazaLink order numbers.
  static const String orderNumberPrefix = 'SL';

  // ── Contact ────────────────────────────────────────────────────────────────

  static const String supportPhone = '031 123 4567';
  static const String supportWhatsAppNumber = '+27311234567';
  static const String supportEmail = 'support@spazalink.co.za';

  // ── Locale ─────────────────────────────────────────────────────────────────

  static const String locale = 'en_ZA';
  static const String currencySymbol = 'R';
  static const String currencyCode = 'ZAR';

  // ── Hive box names ─────────────────────────────────────────────────────────

  static const String hiveBoxCart = 'cart_box';
  static const String hiveBoxOrderQueue = 'order_queue_box';
  static const String hiveBoxSettings = 'settings_box';
  static const String hiveBoxUser = 'user_box';

  // ── Hive type adapter IDs ──────────────────────────────────────────────────

  static const int hiveTypeCartItem = 0;
  static const int hiveTypeQueuedOrder = 1;
  static const int hiveTypeSyncStatus = 2;

  // ── Pagination ─────────────────────────────────────────────────────────────

  static const int pageSize = 20;
  static const int productPageSize = 24;
  static const int orderPageSize = 15;

  // ── Timeouts ───────────────────────────────────────────────────────────────

  static const Duration syncDebounce = Duration(seconds: 3);
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const Duration splashDuration = Duration(seconds: 2);

  // ── Notification types ─────────────────────────────────────────────────────

  static const String notifTypeOrderStatus = 'order_status';
  static const String notifTypeShopApproval = 'shop_approval';
  static const String notifTypePromotion = 'promotion';
  static const String notifTypePayment = 'payment';
  static const String notifTypeDelivery = 'delivery';
  static const String notifTypeSystem = 'system';

  // ── Storage paths ──────────────────────────────────────────────────────────

  static const String storageShopPhotos = 'shop_photos';
  static const String storageProductImages = 'product_images';
  static const String storageCategoryIcons = 'category_icons';
  static const String storageDriverPhotos = 'driver_photos';
  static const String storageDeliveryProofs = 'delivery_proofs';
  static const String storageSignatures = 'delivery_signatures';
  static const String storageDocuments = 'documents';
  static const String storageInvoices = 'invoices';
  static const String storageBanners = 'banners';

  // ── Shop status values ─────────────────────────────────────────────────────

  static const String shopStatusPending = 'pending';
  static const String shopStatusApproved = 'approved';
  static const String shopStatusRejected = 'rejected';
  static const String shopStatusSuspended = 'suspended';

  // ── Order status values ────────────────────────────────────────────────────

  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusPacked = 'packed';
  static const String orderStatusAssigned = 'assigned';
  static const String orderStatusOutForDelivery = 'out_for_delivery';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // ── Delivery status values ─────────────────────────────────────────────────

  static const String deliveryStatusAssigned = 'assigned';
  static const String deliveryStatusPickedUp = 'picked_up';
  static const String deliveryStatusEnRoute = 'en_route';
  static const String deliveryStatusDelivered = 'delivered';
  static const String deliveryStatusFailed = 'failed';

  // ── Payment method values ──────────────────────────────────────────────────

  static const String paymentCod = 'cod';
  static const String paymentEft = 'eft';
  static const String paymentPayfast = 'payfast';
  static const String paymentOzow = 'ozow';
  static const String paymentYoco = 'yoco';

  // ── Payment status values ──────────────────────────────────────────────────

  static const String paymentStatusPending = 'pending';
  static const String paymentStatusPaid = 'paid';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';

  // ── User roles ─────────────────────────────────────────────────────────────

  static const String roleCustomer = 'customer';
  static const String roleAdmin = 'admin';
  static const String roleDriver = 'driver';

  // ── Sync status values ─────────────────────────────────────────────────────

  static const String syncStatusPending = 'pending_sync';
  static const String syncStatusSyncing = 'syncing';
  static const String syncStatusSent = 'sent';
  static const String syncStatusFailed = 'failed';
}
