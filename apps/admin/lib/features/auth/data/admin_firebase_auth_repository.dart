import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:spazalink_core/core.dart';

import '../../../firebase_options.dart';

class AdminFirebaseAuthRepository implements AuthRepository {
  AdminFirebaseAuthRepository({
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
    // Admin uses email+password — phone OTP not supported.
    onError(const AuthException(
      message: 'Phone auth is not supported on the admin dashboard.',
      code: 'unsupported',
    ));
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String otp,
  }) async {
    throw const AuthException(
      message: 'OTP sign-in is not supported on the admin dashboard.',
      code: 'unsupported',
    );
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!_isReady) throw AuthException.networkError();
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = result.user!.uid;
      final user = await getUser(uid);
      if (user == null) {
        await _auth.signOut();
        throw AuthException.networkError();
      }
      if (user.role != AppConstants.roleAdmin) {
        await _auth.signOut();
        throw AuthException.roleNotAllowed();
      }
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
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
    // Admin users are created via Cloud Functions, not directly.
    throw const AuthException(
      message: 'Admin users cannot be created via the app.',
      code: 'unsupported',
    );
  }

  @override
  Future<ShopModel?> getShopByOwnerId(String ownerId) async => null;

  @override
  Future<ShopModel> createShop(ShopModel shop) async {
    throw const AuthException(
      message: 'Shops cannot be created from the admin auth flow.',
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
        role: (d[FirestoreConstants.fldRole] as String?) ?? AppConstants.roleCustomer,
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
