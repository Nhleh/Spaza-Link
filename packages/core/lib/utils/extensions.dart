import 'package:flutter/material.dart';
import 'currency_formatter.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';

// ── int (cents) ────────────────────────────────────────────────────────────────

extension CentsExtension on int {
  /// Format as ZAR currency string: 2450 → 'R24.50'
  String get toZar => CurrencyFormatter.format(this);

  /// Format as delivery fee string — 'FREE' if zero.
  String get toDeliveryFee => CurrencyFormatter.formatDeliveryFee(this);

  /// Convert cents to rand double: 2450 → 24.5
  double get toRands => CurrencyFormatter.centsToRands(this);

  /// Calculate delivery fee based on order total.
  int get deliveryFee => this >= AppConstants.freeDeliveryThresholdCents
      ? 0
      : AppConstants.deliveryFeeCents;

  /// Whether this amount qualifies for free delivery.
  bool get isFreeDelivery => this >= AppConstants.freeDeliveryThresholdCents;

  /// Whether this amount meets the minimum order requirement.
  bool get meetsMinimumOrder => this >= AppConstants.minOrderCents;
}

// ── String ─────────────────────────────────────────────────────────────────────

extension StringExtension on String {
  /// Capitalise the first letter of the string.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Convert 'out_for_delivery' → 'Out for delivery'.
  String get fromSnakeCase => replaceAll('_', ' ').capitalised;

  /// Convert to SA phone number format: 0821234567 → +27821234567
  String get toInternationalPhone {
    final cleaned = replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('0')) return '+27${cleaned.substring(1)}';
    if (cleaned.startsWith('27')) return '+$cleaned';
    return cleaned;
  }

  /// Truncate string with ellipsis.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';

  /// Mask email for display: john@example.com → j***@example.com
  String get maskedEmail {
    final parts = split('@');
    if (parts.length != 2 || parts[0].isEmpty) return this;
    return '${parts[0][0]}***@${parts[1]}';
  }
}

// ── DateTime ───────────────────────────────────────────────────────────────────

extension DateTimeExtension on DateTime {
  /// Format as 'Friday, 24 May 2024'
  String get displayDateFull {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[weekday - 1]}, $day ${months[month - 1]} $year';
  }

  /// Format as '24 May 2024'
  String get displayDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$day ${months[month - 1]} $year';
  }

  /// Format as '08:00 – 12:00'
  String get displayTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Format as '22 May 2024 – 07:45'
  String get displayDateTime => '$displayDate – $displayTime';

  /// Relative time string: 'Just now', '5 min ago', '2 hours ago', etc.
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return displayDate;
  }

  /// Whether this date is today.
  bool get isToday {
    final now = DateTime.now();
    return day == now.day && month == now.month && year == now.year;
  }
}

// ── Order status ───────────────────────────────────────────────────────────────

extension OrderStatusExtension on String {
  /// Map order status string to a display label.
  String get orderStatusLabel => switch (this) {
        AppConstants.orderStatusPending => 'Pending',
        AppConstants.orderStatusConfirmed => 'Confirmed',
        AppConstants.orderStatusPacked => 'Being Packed',
        AppConstants.orderStatusAssigned => 'Driver Assigned',
        AppConstants.orderStatusOutForDelivery => 'Out for Delivery',
        AppConstants.orderStatusDelivered => 'Delivered',
        AppConstants.orderStatusCancelled => 'Cancelled',
        _ => fromSnakeCase,
      };

  /// Map order status to semantic colour.
  Color get orderStatusColor => switch (this) {
        AppConstants.orderStatusPending => AppColors.statusPending,
        AppConstants.orderStatusConfirmed => AppColors.statusConfirmed,
        AppConstants.orderStatusPacked => AppColors.statusPacked,
        AppConstants.orderStatusAssigned => AppColors.statusOutForDelivery,
        AppConstants.orderStatusOutForDelivery => AppColors.statusOutForDelivery,
        AppConstants.orderStatusDelivered => AppColors.statusDelivered,
        AppConstants.orderStatusCancelled => AppColors.statusCancelled,
        _ => AppColors.statusPending,
      };

  /// Map shop status to a display label.
  String get shopStatusLabel => switch (this) {
        AppConstants.shopStatusPending => 'Pending Approval',
        AppConstants.shopStatusApproved => 'Active',
        AppConstants.shopStatusRejected => 'Rejected',
        AppConstants.shopStatusSuspended => 'Suspended',
        _ => fromSnakeCase,
      };

  /// Map shop status to semantic colour.
  Color get shopStatusColor => switch (this) {
        AppConstants.shopStatusPending => AppColors.shopPending,
        AppConstants.shopStatusApproved => AppColors.shopApproved,
        AppConstants.shopStatusRejected => AppColors.shopRejected,
        AppConstants.shopStatusSuspended => AppColors.shopSuspended,
        _ => AppColors.statusPending,
      };
}

// ── BuildContext ───────────────────────────────────────────────────────────────

extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  EdgeInsets get padding => mediaQuery.padding;
  bool get isTablet => screenWidth >= 600;
  bool get isDesktop => screenWidth >= 1024;

  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.brandGreenPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showErrorSnack(String message) => showSnack(message, isError: true);
  void showSuccessSnack(String message) => showSnack(message);
}
