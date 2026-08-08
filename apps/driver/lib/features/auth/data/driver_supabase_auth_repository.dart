import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Supabase-backed implementation of [AuthRepository] for the Customer app.
/// Drop-in replacement for the old FirebaseAuthRepository — same interface, so
/// the providers, screens and models are unchanged.
class DriverSupabaseAuthRepository implements AuthRepository {
  DriverSupabaseAuthRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  // ── Auth state ──────────────────────────────────────────────────────────────
  @override
  Stream<String?> get userIdStream =>
      _sb.auth.onAuthStateChange.map((s) => s.session?.user.id);

  // ── Register (account + profile) ─────────────────────────────────────────────
  /// Creates the auth user and fills in their profile. Supabase always signs in
  /// with the real email; [useEmailLogin] is kept for interface compatibility.
  Future<UserModel> registerAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool useEmailLogin,
  }) async {
    try {
      final normalized = normalizePhone(phone);

      // A cellphone can belong to only one account (phone-login resolves
      // phone -> email), so reject a number that's already taken *before*
      // creating the auth user. Uses a SECURITY DEFINER RPC; if that function
      // isn't deployed yet we skip the check rather than block registration.
      if (normalized.isNotEmpty) {
        try {
          final taken =
              await _sb.rpc('phone_in_use', params: {'p_phone': normalized});
          if (taken == true) throw AuthException.phoneAlreadyInUse();
        } on supa.PostgrestException {
          // RPC not deployed — fall through and let signup proceed.
        }
      }

      final res = await _sb.auth.signUp(email: email.trim(), password: password);
      final user = res.user;
      if (user == null) throw AuthException.networkError();

      // A DB trigger created a bare profile row; populate it.
      final row = await _sb
          .from('profiles')
          .update({
            'display_name': name.trim(),
            'email': email.trim(),
            'phone_number': normalized,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id)
          .select()
          .maybeSingle();

      return row != null
          ? _userFromRow(row)
          : UserModel(
              uid: user.id,
              phoneNumber: normalized,
              displayName: name.trim(),
              email: email.trim(),
              role: AppConstants.roleCustomer,
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
    } on supa.AuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  /// Sign in with an email OR a cellphone number, plus [password].
  Future<UserModel> signInWithIdentifier({
    required String identifier,
    required String password,
    required bool isEmail,
  }) async {
    var email = identifier.trim();
    if (!isEmail) {
      // Resolve the cellphone to its account email via a SECURITY DEFINER RPC.
      final resolved = await _sb.rpc(
        'email_for_phone',
        params: {'p_phone': normalizePhone(identifier)},
      );
      if (resolved is String && resolved.isNotEmpty) {
        email = resolved;
      } else {
        throw AuthException.accountNotFound();
      }
    }
    return signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _sb.auth
          .signInWithPassword(email: email.trim(), password: password);
      final u = res.user;
      if (u == null) throw AuthException.invalidCredentials();
      final existing = await getUser(u.id);
      return existing ??
          await createUser(UserModel(
            uid: u.id,
            phoneNumber: '',
            email: u.email,
            role: AppConstants.roleCustomer,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
    } on supa.AuthException catch (e) {
      final mapped = _mapAuthError(e);
      // Supabase returns the same "invalid credentials" for a missing account
      // and a wrong password. Ask the DB whether the account exists so we can
      // show the right message.
      if (mapped is AuthException && mapped.code == 'invalid-credentials') {
        if (!await _emailExists(email.trim())) {
          throw AuthException.accountNotFound();
        }
      }
      throw mapped;
    }
  }

  /// True if an auth account exists for [email] (via the email_exists RPC).
  Future<bool> _emailExists(String email) async {
    try {
      final r = await _sb.rpc('email_exists', params: {'p_email': email});
      return r == true;
    } catch (_) {
      return true; // fail-safe: never wrongly claim "no account"
    }
  }

  // ── Profiles ─────────────────────────────────────────────────────────────────
  @override
  Future<UserModel?> getUser(String uid) async {
    final row =
        await _sb.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : _userFromRow(row);
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    final row =
        await _sb.from('profiles').upsert(_userToRow(user)).select().single();
    return _userFromRow(row);
  }

  // ── Shops ────────────────────────────────────────────────────────────────────
  @override
  Future<ShopModel?> getShopByOwnerId(String ownerId) async {
    final row = await _sb
        .from('shops')
        .select()
        .eq('owner_id', ownerId)
        .limit(1)
        .maybeSingle();
    return row == null ? null : _shopFromRow(row);
  }

  @override
  Future<ShopModel> createShop(ShopModel shop) async {
    final row =
        await _sb.from('shops').insert(_shopToRow(shop)).select().single();
    return _shopFromRow(row);
  }

  @override
  Future<void> signOut() => _sb.auth.signOut();

  // ── OTP (not used with Supabase email/password) ──────────────────────────────
  @override
  Future<void> verifyPhone(
    String phoneNumber, {
    required void Function(String verificationId, int? forceResendingToken)
        onCodeSent,
    required void Function(AppException e) onError,
  }) async {
    onError(const AuthException(
        message: 'Phone OTP is not used.', code: 'unsupported'));
  }

  @override
  Future<UserModel> signInWithOtp({
    required String verificationId,
    required String otp,
  }) async =>
      throw const AuthException(
          message: 'Phone OTP is not used.', code: 'unsupported');

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static String normalizePhone(String phone) {
    var c = phone.trim().replaceAll(RegExp(r'[\s\-()+]'), '');
    if (c.startsWith('0')) {
      c = '27${c.substring(1)}';
    } else if (!c.startsWith('27')) {
      c = '27$c';
    }
    return c;
  }

  AppException _mapAuthError(supa.AuthException e) {
    final m = e.message.toLowerCase();
    // Supabase signUp returns "User already registered" when the EMAIL exists.
    if (m.contains('already registered') ||
        m.contains('already been registered') ||
        (m.contains('email') && m.contains('exists'))) {
      return AuthException.emailAlreadyInUse();
    }
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return AuthException.invalidCredentials();
    }
    return AuthException(message: e.message, code: 'auth-error');
  }

  UserModel _userFromRow(Map<String, dynamic> d) => UserModel(
        uid: d['id'] as String,
        phoneNumber: (d['phone_number'] as String?) ?? '',
        displayName: (d['display_name'] as String?) ?? '',
        email: d['email'] as String?,
        role: (d['role'] as String?) ?? AppConstants.roleCustomer,
        isActive: (d['is_active'] as bool?) ?? true,
        fcmTokens: (d['fcm_tokens'] as List?)?.cast<String>() ?? const [],
        createdAt: _dt(d['created_at']),
        updatedAt: _dt(d['updated_at']),
      );

  Map<String, dynamic> _userToRow(UserModel u) => {
        'id': u.uid,
        'display_name': u.displayName,
        'email': u.email,
        'phone_number': u.phoneNumber,
        'role': u.role,
        'is_active': u.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

  ShopModel _shopFromRow(Map<String, dynamic> d) => ShopModel(
        id: d['id'] as String,
        ownerId: (d['owner_id'] as String?) ?? '',
        shopName: (d['shop_name'] as String?) ?? '',
        ownerName: (d['owner_name'] as String?) ?? '',
        physicalAddress: (d['physical_address'] as String?) ?? '',
        city: (d['city'] as String?) ?? '',
        province: (d['province'] as String?) ?? '',
        gpsLocation: (d['gps_lat'] != null && d['gps_lng'] != null)
            ? GpsLocation(
                latitude: (d['gps_lat'] as num).toDouble(),
                longitude: (d['gps_lng'] as num).toDouble())
            : null,
        status: (d['status'] as String?) ?? AppConstants.shopStatusPending,
        rejectionReason: d['rejection_reason'] as String?,
        approvedBy: d['approved_by'] as String?,
        approvedAt:
            d['approved_at'] != null ? DateTime.tryParse(d['approved_at']) : null,
        shopPhotoUrl: d['shop_photo_url'] as String?,
        businessRegUrl: d['business_reg_url'] as String?,
        ownerIdUrl: d['owner_id_url'] as String?,
        createdAt: _dt(d['created_at']),
        updatedAt: _dt(d['updated_at']),
      );

  Map<String, dynamic> _shopToRow(ShopModel s) => {
        'owner_id': s.ownerId,
        'shop_name': s.shopName,
        'owner_name': s.ownerName,
        'physical_address': s.physicalAddress,
        'city': s.city,
        'province': s.province,
        'gps_lat': s.gpsLocation?.latitude,
        'gps_lng': s.gpsLocation?.longitude,
        'shop_photo_url': s.shopPhotoUrl,
        'status': AppConstants.shopStatusPending,
      };

  DateTime _dt(dynamic v) =>
      v is String ? (DateTime.tryParse(v) ?? DateTime.now()) : DateTime.now();
}
