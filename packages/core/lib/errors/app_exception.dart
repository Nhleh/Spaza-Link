/// Base exception class for SpazaLink.
///
/// All domain exceptions extend [AppException] so they can be caught uniformly
/// and mapped to user-facing error messages without leaking SDK internals.
sealed class AppException implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException[$code]: $message';
}

// ── Auth ───────────────────────────────────────────────────────────────────────

final class AuthException extends AppException {
  const AuthException({required super.message, super.code});

  factory AuthException.invalidCredentials() => const AuthException(
        message: 'Incorrect phone number or password.',
        code: 'invalid-credentials',
      );

  factory AuthException.userDisabled() => const AuthException(
        message: 'Your account has been disabled. Please contact support.',
        code: 'user-disabled',
      );

  factory AuthException.phoneAlreadyInUse() => const AuthException(
        message: 'This phone number is already registered.',
        code: 'phone-already-in-use',
      );

  factory AuthException.networkError() => const AuthException(
        message: 'Network error. Please check your connection and try again.',
        code: 'network-error',
      );

  factory AuthException.invalidOtp() => const AuthException(
        message: 'The OTP you entered is incorrect. Please check and try again.',
        code: 'invalid-otp',
      );

  factory AuthException.otpExpired() => const AuthException(
        message: 'The OTP has expired. Please request a new one.',
        code: 'otp-expired',
      );

  factory AuthException.tooManyRequests() => const AuthException(
        message: 'Too many attempts. Please wait a few minutes before trying again.',
        code: 'too-many-requests',
      );

  factory AuthException.roleNotAllowed() => const AuthException(
        message: 'This account does not have access to this app.',
        code: 'role-not-allowed',
      );

  factory AuthException.fromFirebase(String code) => switch (code) {
        'user-not-found' ||
        'wrong-password' =>
          AuthException.invalidCredentials(),
        'user-disabled' => AuthException.userDisabled(),
        'email-already-in-use' ||
        'phone-number-already-exists' =>
          AuthException.phoneAlreadyInUse(),
        'network-request-failed' => AuthException.networkError(),
        'invalid-verification-code' ||
        'invalid-verification-id' =>
          AuthException.invalidOtp(),
        'session-expired' => AuthException.otpExpired(),
        'too-many-requests' ||
        'quota-exceeded' =>
          AuthException.tooManyRequests(),
        _ => AuthException(
            message: 'Authentication failed. Please try again.',
            code: code,
          ),
      };
}

// ── Shop ───────────────────────────────────────────────────────────────────────

final class ShopException extends AppException {
  const ShopException({required super.message, super.code});

  factory ShopException.pendingApproval() => const ShopException(
        message:
            'Your shop is awaiting approval. You will be notified once approved.',
        code: 'pending-approval',
      );

  factory ShopException.rejected() => const ShopException(
        message: 'Your shop registration was not approved.',
        code: 'rejected',
      );

  factory ShopException.suspended() => const ShopException(
        message:
            'Your shop has been suspended. Please contact support for assistance.',
        code: 'suspended',
      );
}

// ── Order ──────────────────────────────────────────────────────────────────────

final class OrderException extends AppException {
  const OrderException({required super.message, super.code});

  factory OrderException.belowMinimum(int minCents) => OrderException(
        message:
            'Minimum order is R${(minCents / 100).toStringAsFixed(0)}. '
            'Please add more items to your cart.',
        code: 'below-minimum',
      );

  factory OrderException.outOfStock(String productName) => OrderException(
        message: '$productName is out of stock.',
        code: 'out-of-stock',
      );

  factory OrderException.duplicate() => const OrderException(
        message: 'This order has already been submitted.',
        code: 'duplicate-order',
      );
}

// ── Network ────────────────────────────────────────────────────────────────────

final class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Your data has been saved and will sync automatically.',
    super.code = 'no-connection',
  });
}

// ── Server ─────────────────────────────────────────────────────────────────────

final class ServerException extends AppException {
  const ServerException({
    super.message = 'Something went wrong on our end. Please try again shortly.',
    super.code,
  });

  factory ServerException.fromCode(String code) => ServerException(
        message: 'Server error ($code). Please try again.',
        code: code,
      );
}

// ── Validation ─────────────────────────────────────────────────────────────────

final class ValidationException extends AppException {
  const ValidationException({required super.message, super.code = 'validation'});
}

// ── Permission ─────────────────────────────────────────────────────────────────

final class PermissionException extends AppException {
  const PermissionException({required super.message, super.code = 'permission'});

  factory PermissionException.location() => const PermissionException(
        message:
            'Location permission is required to register your shop. '
            'Please enable it in settings.',
        code: 'location-permission',
      );

  factory PermissionException.camera() => const PermissionException(
        message: 'Camera permission is required to take photos.',
        code: 'camera-permission',
      );

  factory PermissionException.notification() => const PermissionException(
        message: 'Notification permission is required to receive order updates.',
        code: 'notification-permission',
      );
}

// ── Not Found ──────────────────────────────────────────────────────────────────

final class NotFoundException extends AppException {
  const NotFoundException({required super.message, super.code = 'not-found'});
}
