import '../errors/app_exception.dart';
import '../models/shop_model.dart';
import '../models/user_model.dart';

/// Contract for all authentication and user-data operations.
///
/// The Firebase implementation lives in each app's `features/auth/data/`
/// directory — keeping Firebase imports out of this core package.
abstract interface class AuthRepository {
  /// Stream of the authenticated user's UID. Emits [null] when signed out.
  Stream<String?> get userIdStream;

  /// Sends an SMS OTP to [phoneNumber].
  ///
  /// [onCodeSent] is called with the [verificationId] once Firebase dispatches
  /// the SMS. [forceResendingToken] is non-null when resending.
  /// [onError] receives an [AppException] on failure.
  Future<void> verifyPhone(
    String phoneNumber, {
    required void Function(
      String verificationId,
      int? forceResendingToken,
    ) onCodeSent,
    required void Function(AppException e) onError,
  });

  /// Verifies [otp] against [verificationId] and signs the user in.
  ///
  /// Returns the [UserModel] fetched or created for the authenticated user.
  /// Throws [AuthException] on failure.
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String otp,
  });

  /// Signs in with email and password (used by the Admin Dashboard).
  /// Throws [AuthException] on failure.
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Fetches the [UserModel] for [uid] from Firestore.
  /// Returns [null] if the document does not exist yet.
  Future<UserModel?> getUser(String uid);

  /// Creates the `users/{uid}` document in Firestore.
  Future<UserModel> createUser(UserModel user);

  /// Fetches the [ShopModel] whose `ownerId` matches [ownerId].
  /// Returns [null] if the owner has not yet registered a shop.
  Future<ShopModel?> getShopByOwnerId(String ownerId);

  /// Creates a new shop document in Firestore.
  /// The returned [ShopModel] has the auto-generated Firestore ID and
  /// `status = 'pending'` set by the server.
  Future<ShopModel> createShop(ShopModel shop);

  /// Signs the current user out.
  Future<void> signOut();
}
