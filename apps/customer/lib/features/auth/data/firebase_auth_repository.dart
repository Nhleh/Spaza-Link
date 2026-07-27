import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:spazalink_core/core.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  bool get _isReady {
    try {
      _auth.app;
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── AuthRepository interface ───────────────────────────────────────────────

  @override
  Stream<String?> get userIdStream {
    if (!_isReady) return Stream.value(null);
    return _auth.authStateChanges().map((u) => u?.uid);
  }

  @override
  Future<void> verifyPhone(
    String phoneNumber, {
    required void Function(String verificationId, int? forceResendingToken)
        onCodeSent,
    required void Function(AppException e) onError,
  }) async {
    if (!_isReady) {
      onError(AuthException.networkError());
      return;
    }
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        // Auto-resolved on Android — sign in immediately.
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
      final fbUser = result.user!;

      final existing = await getUser(fbUser.uid);
      if (existing != null) return existing;

      return createUser(UserModel(
        uid: fbUser.uid,
        phoneNumber: fbUser.phoneNumber ?? '',
        role: AppConstants.roleCustomer,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (!_isReady) throw AuthException.networkError();
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = result.user!;
      final existing = await getUser(fbUser.uid);
      if (existing != null) return existing;
      // Auth account exists but the Firestore profile is missing — recreate it.
      return createUser(UserModel(
        uid: fbUser.uid,
        phoneNumber: fbUser.phoneNumber ?? '',
        email: fbUser.email,
        role: AppConstants.roleCustomer,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e.code);
    }
  }

  // ── Email / cellphone + password (Customer sign-up & sign-in) ───────────────

  /// Builds the Firebase Auth credential email for a cellphone login.
  /// e.g. 0821234567 → 27821234567@phone.spazalink.app
  static String syntheticEmailForPhone(String phone) =>
      '${normalizePhone(phone)}@phone.spazalink.app';

  /// Normalises an SA number to digits in 27-prefixed form (no '+').
  static String normalizePhone(String phone) {
    var cleaned = phone.trim().replaceAll(RegExp(r'[\s\-()+]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '27${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('27')) {
      cleaned = '27$cleaned';
    }
    return cleaned;
  }

  /// Registers a new customer account with email/password auth.
  ///
  /// [useEmailLogin] decides the sign-in credential: the real [email] when
  /// true, or a synthetic address derived from [phone] when false. The user's
  /// real name, email and phone are always stored in their Firestore profile.
  Future<UserModel> registerAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool useEmailLogin,
  }) async {
    if (!_isReady) throw AuthException.networkError();
    final authEmail =
        useEmailLogin ? email.trim() : syntheticEmailForPhone(phone);

    fb.User fbUser;
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
      fbUser = result.user!;
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // A previous attempt already created this login. Recover it by signing
        // in with the same password, then continue provisioning the profile.
        try {
          final result = await _auth.signInWithEmailAndPassword(
            email: authEmail,
            password: password,
          );
          fbUser = result.user!;
        } on fb.FirebaseAuthException {
          throw AuthException.phoneAlreadyInUse();
        }
      } else {
        throw AuthException.fromFirebase(e.code);
      }
    }

    // Ensure the Firestore profile exists (idempotent on retry).
    final existing = await getUser(fbUser.uid);
    if (existing != null) return existing;
    return createUser(UserModel(
      uid: fbUser.uid,
      phoneNumber: normalizePhone(phone),
      displayName: name.trim(),
      email: email.trim(),
      role: AppConstants.roleCustomer,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  /// Signs in with either an email or a cellphone number, plus [password].
  Future<UserModel> signInWithIdentifier({
    required String identifier,
    required String password,
    required bool isEmail,
  }) {
    final authEmail =
        isEmail ? identifier.trim() : syntheticEmailForPhone(identifier);
    return signInWithEmailAndPassword(email: authEmail, password: password);
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final ref = _db.collection(FirestoreConstants.colUsers).doc(uid);
    var doc = await ref.get();
    // A profile just written (with offline persistence) may not have synced to
    // the server yet — fall back to the local cache so it's still found.
    if (!doc.exists) {
      try {
        doc = await ref.get(const GetOptions(source: Source.cache));
      } catch (_) {}
    }
    if (!doc.exists || doc.data() == null) return null;
    return _userFromMap(uid, doc.data()!);
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    final now = DateTime.now();
    final updated = user.copyWith(createdAt: now, updatedAt: now);
    await _db
        .collection(FirestoreConstants.colUsers)
        .doc(user.uid)
        .set(_userToMap(updated));
    return updated;
  }

  @override
  Future<ShopModel?> getShopByOwnerId(String ownerId) async {
    final query = _db
        .collection(FirestoreConstants.colShops)
        .where(FirestoreConstants.fldOwnerId, isEqualTo: ownerId)
        .limit(1);
    var q = await query.get();
    // A shop just created (with offline persistence) may not have synced to the
    // server yet; a server query would miss it and bounce the user back to
    // registration. Fall back to the local cache in that case.
    if (q.docs.isEmpty) {
      try {
        q = await query.get(const GetOptions(source: Source.cache));
      } catch (_) {}
    }
    if (q.docs.isEmpty) return null;
    return _shopFromMap(q.docs.first.id, q.docs.first.data());
  }

  @override
  Future<ShopModel> createShop(ShopModel shop) async {
    final now = DateTime.now();
    final ref = _db.collection(FirestoreConstants.colShops).doc();
    final updated = shop.copyWith(
      id: ref.id,
      status: AppConstants.shopStatusPending,
      createdAt: now,
      updatedAt: now,
    );
    await ref.set(_shopToMap(updated));
    return updated;
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

  Map<String, dynamic> _userToMap(UserModel u) => {
        FirestoreConstants.fldUid: u.uid,
        FirestoreConstants.fldPhoneNumber: u.phoneNumber,
        FirestoreConstants.fldDisplayName: u.displayName,
        FirestoreConstants.fldEmail: u.email,
        FirestoreConstants.fldRole: u.role,
        FirestoreConstants.fldIsActive: u.isActive,
        FirestoreConstants.fldFcmTokens: u.fcmTokens,
        FirestoreConstants.fldCreatedAt: Timestamp.fromDate(u.createdAt),
        FirestoreConstants.fldUpdatedAt: Timestamp.fromDate(u.updatedAt),
      };

  ShopModel _shopFromMap(String id, Map<String, dynamic> d) {
    GpsLocation? gps;
    final raw = d['gpsLocation'];
    if (raw is GeoPoint) {
      gps = GpsLocation(latitude: raw.latitude, longitude: raw.longitude);
    } else if (raw is Map) {
      gps = GpsLocation(
        latitude: (raw['latitude'] as num).toDouble(),
        longitude: (raw['longitude'] as num).toDouble(),
      );
    }
    return ShopModel(
      id: id,
      ownerId: (d[FirestoreConstants.fldOwnerId] as String?) ?? '',
      shopName: (d[FirestoreConstants.fldShopName] as String?) ?? '',
      ownerName: (d[FirestoreConstants.fldOwnerName] as String?) ?? '',
      physicalAddress: (d[FirestoreConstants.fldPhysicalAddress] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      province: (d['province'] as String?) ?? '',
      gpsLocation: gps,
      status: (d[FirestoreConstants.fldStatus] as String?) ?? AppConstants.shopStatusPending,
      rejectionReason: d[FirestoreConstants.fldRejectionReason] as String?,
      approvedBy: d[FirestoreConstants.fldApprovedBy] as String?,
      approvedAt: d[FirestoreConstants.fldApprovedAt] is Timestamp
          ? (d[FirestoreConstants.fldApprovedAt] as Timestamp).toDate()
          : null,
      shopPhotoUrl: d[FirestoreConstants.fldShopPhotoUrl] as String?,
      businessRegUrl: d[FirestoreConstants.fldBusinessRegUrl] as String?,
      ownerIdUrl: d[FirestoreConstants.fldOwnerIdUrl] as String?,
      createdAt: _ts(d[FirestoreConstants.fldCreatedAt]),
      updatedAt: _ts(d[FirestoreConstants.fldUpdatedAt]),
    );
  }

  Map<String, dynamic> _shopToMap(ShopModel s) => {
        FirestoreConstants.fldOwnerId: s.ownerId,
        FirestoreConstants.fldShopName: s.shopName,
        FirestoreConstants.fldOwnerName: s.ownerName,
        FirestoreConstants.fldPhysicalAddress: s.physicalAddress,
        'city': s.city,
        'province': s.province,
        'gpsLocation': s.gpsLocation == null
            ? null
            : GeoPoint(s.gpsLocation!.latitude, s.gpsLocation!.longitude),
        FirestoreConstants.fldStatus: s.status,
        FirestoreConstants.fldShopPhotoUrl: s.shopPhotoUrl,
        FirestoreConstants.fldBusinessRegUrl: s.businessRegUrl,
        FirestoreConstants.fldOwnerIdUrl: s.ownerIdUrl,
        FirestoreConstants.fldCreatedAt: Timestamp.fromDate(s.createdAt),
        FirestoreConstants.fldUpdatedAt: Timestamp.fromDate(s.updatedAt),
      };

  DateTime _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.now();
  }
}
