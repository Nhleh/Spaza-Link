import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:spazalink_core/core.dart';

import '../../../firebase_options.dart';

class DriverFirebaseAuthRepository implements AuthRepository {
  DriverFirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  bool get _isReady {
    try {
      _auth.app;
      return kFirebaseConfigured;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<String?> get userIdStream {
    if (!_isReady) return Stream.value(null);
    return _auth.authStateChanges().map((u) => u?.uid);
  }

  @override
  Future<void> verifyPhone(
    String phoneNumber, {
    required void Function(String verificationId, int? forceResendingToken) onCodeSent,
    required void Function(AppException e) onError,
  }) async {
    if (!_isReady) {
      onError(AuthException.networkError());
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {}
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        onError(AuthException.fromFirebase(e.code));
      },
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      final result = await _auth.signInWithCredential(credential);
      final uid = result.user!.uid;

      final user = await getUser(uid);
      if (user == null) {
        // Drivers must be pre-registered by an admin — no auto-create.
        await _auth.signOut();
        throw const AuthException(
          message:
              'This number is not registered as a SpazaLink driver. Please contact your supervisor.',
          code: 'driver-not-registered',
        );
      }
      if (user.role != AppConstants.roleDriver) {
        await _auth.signOut();
        throw AuthException.roleNotAllowed();
      }
      return user;
    } on AuthException {
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw const AuthException(
      message: 'Email sign-in is not supported in the Driver App.',
      code: 'unsupported',
    );
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final doc = await _db
        .collection(FirestoreConstants.colUsers)
        .doc(uid)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return _userFromMap(uid, doc.data()!);
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    throw const AuthException(
      message: 'Driver accounts are created by an admin.',
      code: 'unsupported',
    );
  }

  @override
  Future<ShopModel?> getShopByOwnerId(String ownerId) async => null;

  @override
  Future<ShopModel> createShop(ShopModel shop) async {
    throw const AuthException(
      message: 'Shops cannot be created from the driver auth flow.',
      code: 'unsupported',
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  // ── Mapping helpers ────────────────────────────────────────────────────────

  UserModel _userFromMap(String uid, Map<String, dynamic> d) => UserModel(
        uid: (d[FirestoreConstants.fldUid] as String?) ?? uid,
        phoneNumber: (d[FirestoreConstants.fldPhoneNumber] as String?) ?? '',
        displayName: (d[FirestoreConstants.fldDisplayName] as String?) ?? '',
        email: d[FirestoreConstants.fldEmail] as String?,
        role: (d[FirestoreConstants.fldRole] as String?) ?? AppConstants.roleDriver,
        isActive: (d[FirestoreConstants.fldIsActive] as bool?) ?? true,
        fcmTokens: List<String>.from(d[FirestoreConstants.fldFcmTokens] ?? []),
        createdAt: _ts(d[FirestoreConstants.fldCreatedAt]),
        updatedAt: _ts(d[FirestoreConstants.fldUpdatedAt]),
      );

  DateTime _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.now();
  }
}
