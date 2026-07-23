import '../constants/app_constants.dart';

/// Form field validators for SpazaLink.
///
/// All validators return null on success and an error string on failure,
/// matching Flutter's [FormField.validator] signature.
abstract final class Validators {
  // ── Phone ──────────────────────────────────────────────────────────────────

  /// Validates a South African mobile phone number.
  /// Accepts: 0821234567, +27821234567, 27821234567
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final saPhone = RegExp(r'^(\+27|27|0)[6-8][0-9]{8}$');
    if (!saPhone.hasMatch(cleaned)) {
      return 'Enter a valid South African mobile number';
    }
    return null;
  }

  // ── Password ───────────────────────────────────────────────────────────────

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    final baseError = password(value);
    if (baseError != null) return baseError;
    if (value != original) return 'Passwords do not match';
    return null;
  }

  // ── Email ──────────────────────────────────────────────────────────────────

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Email is optional
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? requiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email address is required';
    return email(value);
  }

  // ── Required text ──────────────────────────────────────────────────────────

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? shopName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Shop name is required';
    if (value.trim().length < 3) return 'Shop name must be at least 3 characters';
    if (value.trim().length > 100) return 'Shop name must be under 100 characters';
    return null;
  }

  static String? ownerName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Owner name is required';
    if (value.trim().length < 2) return 'Enter full name';
    return null;
  }

  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) return 'Address is required';
    if (value.trim().length < 10) return 'Enter a complete street address';
    return null;
  }

  // ── Product ────────────────────────────────────────────────────────────────

  static String? productName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Product name is required';
    if (value.trim().length < 2) return 'Name too short';
    return null;
  }

  static String? productPrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final price = double.tryParse(value.replaceAll(',', '.'));
    if (price == null) return 'Enter a valid price';
    if (price <= 0) return 'Price must be greater than 0';
    return null;
  }

  static String? sku(String? value) {
    if (value == null || value.trim().isEmpty) return 'SKU is required';
    if (value.trim().length < 3) return 'SKU too short';
    return null;
  }

  // ── Order ──────────────────────────────────────────────────────────────────

  /// Returns an error if [totalCents] is below the minimum order amount.
  static String? minimumOrder(int totalCents) {
    if (totalCents < AppConstants.minOrderCents) {
      final remaining = AppConstants.minOrderCents - totalCents;
      final rands = (remaining / 100).toStringAsFixed(2);
      return 'Add R$rands more to reach the minimum order of R${(AppConstants.minOrderCents / 100).toStringAsFixed(0)}';
    }
    return null;
  }

  // ── OTP ────────────────────────────────────────────────────────────────────

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    if (value.trim().length != 6) return 'Enter the 6-digit OTP';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must contain digits only';
    }
    return null;
  }
}
