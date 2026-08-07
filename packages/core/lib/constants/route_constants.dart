/// Route path constants for all SpazaLink applications.
///
/// Centralised here so route paths are never hard-coded as strings elsewhere.
abstract final class RouteConstants {
  // ── Customer App ───────────────────────────────────────────────────────────

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String otpVerify = '/otp-verify';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String pendingApproval = '/pending-approval';
  static const String rejected = '/rejected';

  // Main
  static const String search = '/search';
  static const String home = '/home';
  static const String catalogue = '/catalogue';
  static const String catalogueCategory = '/catalogue/:categoryId';
  static const String productDetail = '/product/:productId';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String checkoutPayment = '/checkout/payment';
  static const String orderSuccess = '/order-success/:orderId';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:orderId';
  static const String orderTracking = '/orders/:orderId/tracking';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String savings = '/savings';
  static const String support = '/support';
  static const String helpCentre = '/help';

  // ── Admin Dashboard ────────────────────────────────────────────────────────

  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminProductCreate = '/admin/products/create';
  static const String adminProductEdit = '/admin/products/:productId/edit';
  static const String adminCategories = '/admin/categories';
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/orders/:orderId';
  static const String adminShops = '/admin/shops';
  static const String adminShopDetail = '/admin/shops/:shopId';
  static const String adminCustomers = '/admin/customers';
  static const String adminDrivers = '/admin/drivers';
  static const String adminDriverCreate = '/admin/drivers/create';
  static const String adminDeliveries = '/admin/deliveries';
  static const String adminBulkAggregation = '/admin/bulk-aggregation';
  static const String adminPromotions = '/admin/promotions';
  static const String adminBanners = '/admin/banners';
  static const String adminReports = '/admin/reports';
  static const String adminAds = '/admin/ads';
  static const String adminSettings = '/admin/settings';
  static const String adminNotifications = '/admin/notifications';

  // ── Driver App ─────────────────────────────────────────────────────────────

  static const String driverSplash = '/driver';
  static const String driverLogin = '/driver/login';
  static const String driverOtpVerify = '/driver/otp-verify';
  static const String driverDeliveries = '/driver/deliveries';
  static const String driverDeliveryDetail = '/driver/deliveries/:deliveryId';
  static const String driverNavigation = '/driver/deliveries/:deliveryId/navigation';
  static const String driverPod = '/driver/deliveries/:deliveryId/proof';
  static const String driverMap = '/driver/map';
  static const String driverHistory = '/driver/history';
  static const String driverEarnings = '/driver/earnings';
  static const String driverProfile = '/driver/profile';

  // ── Shared / Utility ───────────────────────────────────────────────────────

  static const String noInternet = '/no-internet';
  static const String maintenance = '/maintenance';
  static const String error = '/error';
}
