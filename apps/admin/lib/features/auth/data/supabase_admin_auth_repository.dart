import 'package:spazalink_core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Supabase-backed admin auth. Only accounts with role='admin' may sign in.
class SupabaseAdminAuthRepository implements AuthRepository {
  SupabaseAdminAuthRepository({supa.SupabaseClient? client})
      : _sb = client ?? supa.Supabase.instance.client;

  final supa.SupabaseClient _sb;

  @override
  Stream<String?> get userIdStream =>
      _sb.auth.onAuthStateChange.map((s) => s.session?.user.id);

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
      final user = await getUser(u.id);
      if (user == null) {
        await _sb.auth.signOut();
        throw AuthException.networkError();
      }
      if (user.role != AppConstants.roleAdmin) {
        await _sb.auth.signOut();
        throw AuthException.roleNotAllowed();
      }
      return user;
    } on supa.AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login') || m.contains('invalid credentials')) {
        throw AuthException.invalidCredentials();
      }
      throw AuthException(message: e.message, code: 'auth-error');
    }
  }

  @override
  Future<UserModel?> getUser(String uid) async {
    final row =
        await _sb.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return UserModel(
      uid: row['id'] as String,
      phoneNumber: (row['phone_number'] as String?) ?? '',
      displayName: (row['display_name'] as String?) ?? '',
      email: row['email'] as String?,
      role: (row['role'] as String?) ?? AppConstants.roleCustomer,
      isActive: (row['is_active'] as bool?) ?? true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> signOut() => _sb.auth.signOut();

  // ── Unused by the admin dashboard ────────────────────────────────────────────
  @override
  Future<void> verifyPhone(String phoneNumber,
      {required void Function(String, int?) onCodeSent,
      required void Function(AppException e) onError}) async {
    onError(const AuthException(message: 'Not supported', code: 'unsupported'));
  }

  @override
  Future<UserModel> signInWithOtp(
          {required String verificationId, required String otp}) async =>
      throw const AuthException(message: 'Not supported', code: 'unsupported');

  @override
  Future<UserModel> createUser(UserModel user) async => throw const AuthException(
      message: 'Admin users are provisioned server-side.', code: 'unsupported');

  @override
  Future<ShopModel?> getShopByOwnerId(String ownerId) async => null;

  @override
  Future<ShopModel> createShop(ShopModel shop) async => throw const AuthException(
      message: 'Not supported here.', code: 'unsupported');
}
