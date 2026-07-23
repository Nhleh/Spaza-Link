import 'package:equatable/equatable.dart';
import 'app_exception.dart';

/// Immutable failure value returned by repositories.
///
/// Repositories never throw — they return [Failure] wrapped in a result type
/// or as part of an [AsyncValue] error so the UI layer can handle them cleanly.
sealed class Failure extends Equatable {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];

  /// Convert an [AppException] to the appropriate [Failure] subtype.
  factory Failure.fromException(AppException e) => switch (e) {
        AuthException() => AuthFailure(message: e.message, code: e.code),
        ShopException() => ShopFailure(message: e.message, code: e.code),
        OrderException() => OrderFailure(message: e.message, code: e.code),
        NetworkException() => NetworkFailure(message: e.message),
        ServerException() => ServerFailure(message: e.message, code: e.code),
        ValidationException() =>
          ValidationFailure(message: e.message, code: e.code),
        PermissionException() =>
          PermissionFailure(message: e.message, code: e.code),
        NotFoundException() =>
          NotFoundFailure(message: e.message, code: e.code),
      };

  /// Generic fallback factory.
  factory Failure.unexpected([String? message]) => ServerFailure(
        message: message ?? 'An unexpected error occurred. Please try again.',
      );
}

final class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

final class ShopFailure extends Failure {
  const ShopFailure({required super.message, super.code});
}

final class OrderFailure extends Failure {
  const OrderFailure({required super.message, super.code});
}

final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message =
        'No internet connection. Your data has been saved and will sync when reconnected.',
  }) : super(code: 'no-connection');
}

final class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

final class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

final class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.code});
}
