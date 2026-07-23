/// Firestore collection and field name constants.
///
/// Never use raw strings for collection/field names in repository code.
/// Always reference these constants to avoid typos and enable safe refactoring.
abstract final class FirestoreConstants {
  // ── Collections ────────────────────────────────────────────────────────────

  static const String colUsers = 'users';
  static const String colShops = 'shops';
  static const String colProducts = 'products';
  static const String colCategories = 'categories';
  static const String colOrders = 'orders';
  static const String colOrderItems = 'order_items';
  static const String colDrivers = 'drivers';
  static const String colDeliveries = 'deliveries';
  static const String colPayments = 'payments';
  static const String colNotifications = 'notifications';
  static const String colPromotions = 'promotions';
  static const String colDiscounts = 'discounts';
  static const String colBanners = 'banners';
  static const String colSupportTickets = 'support_tickets';
  static const String colAuditLogs = 'audit_logs';
  static const String colSettings = 'settings';
  static const String colBulkAggregations = 'bulk_aggregations';
  static const String colReports = 'reports';

  // ── Settings document IDs ──────────────────────────────────────────────────

  static const String settingMinOrderCents = 'min_order_cents';
  static const String settingDeliveryFeeCents = 'delivery_fee_cents';
  static const String settingFreeDeliveryThreshold = 'free_delivery_threshold';
  static const String settingAppVersion = 'app_version';
  static const String settingMaintenanceMode = 'maintenance_mode';

  // ── Field names: users ─────────────────────────────────────────────────────

  static const String fldUid = 'uid';
  static const String fldEmail = 'email';
  static const String fldPhoneNumber = 'phoneNumber';
  static const String fldDisplayName = 'displayName';
  static const String fldRole = 'role';
  static const String fldFcmTokens = 'fcmTokens';
  static const String fldIsActive = 'isActive';
  static const String fldCreatedAt = 'createdAt';
  static const String fldUpdatedAt = 'updatedAt';

  // ── Field names: shops ─────────────────────────────────────────────────────

  static const String fldShopId = 'shopId';
  static const String fldOwnerId = 'ownerId';
  static const String fldShopName = 'shopName';
  static const String fldOwnerName = 'ownerName';
  static const String fldPhysicalAddress = 'physicalAddress';
  static const String fldGpsLocation = 'gpsLocation';
  static const String fldShopPhotoUrl = 'shopPhotoUrl';
  static const String fldBusinessRegUrl = 'businessRegUrl';
  static const String fldOwnerIdUrl = 'ownerIdUrl';
  static const String fldStatus = 'status';
  static const String fldRejectionReason = 'rejectionReason';
  static const String fldApprovedBy = 'approvedBy';
  static const String fldApprovedAt = 'approvedAt';

  // ── Field names: products ──────────────────────────────────────────────────

  static const String fldProductId = 'productId';
  static const String fldCategoryId = 'categoryId';
  static const String fldName = 'name';
  static const String fldDescription = 'description';
  static const String fldSku = 'sku';
  static const String fldBarcode = 'barcode';
  static const String fldImageUrls = 'imageUrls';
  static const String fldPrice = 'price';
  static const String fldSalePrice = 'salePrice';
  static const String fldPackSize = 'packSize';
  static const String fldStockQuantity = 'stockQuantity';
  static const String fldWeightGrams = 'weightGrams';
  static const String fldSupplier = 'supplier';
  static const String fldIsFeatured = 'isFeatured';
  static const String fldIsAvailable = 'isAvailable';
  static const String fldTags = 'tags';

  // ── Field names: orders ────────────────────────────────────────────────────

  static const String fldOrderId = 'orderId';
  static const String fldLocalUuid = 'localUUID';
  static const String fldOrderNumber = 'orderNumber';
  // fldShopId defined above in shops section — reused in orders
  static const String fldCustomerId = 'customerId';
  static const String fldPaymentMethod = 'paymentMethod';
  static const String fldPaymentStatus = 'paymentStatus';
  static const String fldSubtotal = 'subtotal';
  static const String fldDeliveryFee = 'deliveryFee';
  static const String fldDiscountAmount = 'discountAmount';
  static const String fldTotal = 'total';
  static const String fldSavingsAmount = 'savingsAmount';
  static const String fldDeliveryAddress = 'deliveryAddress';
  static const String fldScheduledDeliveryDate = 'scheduledDeliveryDate';
  static const String fldDriverId = 'driverId';
  static const String fldDeliveryId = 'deliveryId';
  static const String fldNotes = 'notes';
  static const String fldPlacedAt = 'placedAt';

  // ── Field names: drivers ───────────────────────────────────────────────────

  // fldDriverId defined above in orders section — reused in drivers collection
  static const String fldVehicleType = 'vehicleType';
  static const String fldVehicleReg = 'vehicleReg';
  static const String fldPhotoUrl = 'photoUrl';
  static const String fldCurrentLocation = 'currentLocation';
  static const String fldIsAvailableDriver = 'isAvailable';

  // ── Field names: deliveries ────────────────────────────────────────────────

  static const String fldDeliveryStatus = 'status';
  static const String fldEstimatedArrival = 'estimatedArrival';
  static const String fldProofPhotoUrl = 'proofPhotoUrl';
  static const String fldSignatureUrl = 'signatureUrl';
  static const String fldDeliveredAt = 'deliveredAt';
  static const String fldAssignedAt = 'assignedAt';

  // ── Misc ───────────────────────────────────────────────────────────────────

  static const String fldIsRead = 'isRead';
  static const String fldSortOrder = 'sortOrder';
  static const String fldSlug = 'slug';
  static const String fldIconUrl = 'iconUrl';
  static const String fldValue = 'value';
  static const String fldType = 'type';
  static const String fldTitle = 'title';
  static const String fldBody = 'body';
}
