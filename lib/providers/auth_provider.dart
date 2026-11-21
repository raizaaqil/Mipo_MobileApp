import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_provider.dart';

/// Hasil dari aksi login/daftar. errorKey adalah kunci di AppStrings.
class AuthResult {
  final String? errorKey;
  final bool needsEmailConfirm;
  const AuthResult.ok()
      : errorKey = null,
        needsEmailConfirm = false;
  const AuthResult.error(String key)
      : errorKey = key,
        needsEmailConfirm = false;
  const AuthResult.needsConfirm()
      : errorKey = null,
        needsEmailConfirm = true;
  bool get isOk => errorKey == null;
}

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._settings) {
    _sub = _client.auth.onAuthStateChange.listen(_onAuthChange);
  }

  final SettingsProvider _settings;
  StreamSubscription<AuthState>? _sub;
  bool _loadingProfile = false;

  Map<String, dynamic>? profile;
  String? profileErrorKey;

  SupabaseClient get _client => Supabase.instance.client;

  bool get isLoggedIn => _client.auth.currentSession != null;
  bool get profileLoaded => profile != null;
  String? get userId => _client.auth.currentUser?.id;

  String get name => (profile?['name'] as String?) ?? '';
  String get email =>
      (profile?['email'] as String?) ?? _client.auth.currentUser?.email ?? '';
  int? get age => profile?['age'] as int?;
  String get education => (profile?['education_level'] as String?) ?? '';
  String get petName => (profile?['pet_name'] as String?) ?? 'Mipo';

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onAuthChange(AuthState state) {
    if (state.session == null) {
      profile = null;
      profileErrorKey = null;
      _loadingProfile = false;
      notifyListeners();
      return;
    }
    if (profile == null) {
      loadProfile();
    } else {
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    if (_loadingProfile) return;
    final user = _client.auth.currentUser;
    if (user == null) return;
    _loadingProfile = true;
    profileErrorKey = null;
    notifyListeners();
    try {
      var row = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      row ??= await _client
          .from('profiles')
          .insert({
            'id': user.id,
            'email': user.email,
            'name': (user.userMetadata?['name'] as String?) ?? '',
          })
          .select()
          .single();
      profile = row;
      _settings.applyRemote(row);
    } catch (e) {
      profileErrorKey = _mapGeneric(e);
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- Auth

  Future<AuthResult> signIn(String email, String password) async {
    try {
      await _client.auth
          .signInWithPassword(email: email.trim(), password: password);
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.error(_mapAuth(e));
    } catch (e) {
      return AuthResult.error(_mapGeneric(e));
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
    required String education,
    required String petName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name.trim(),
          'age': age,
          'education_level': education.trim(),
          'pet_name': petName.trim(),
          'language': _settings.language,
        },
      );
      if (res.session == null) return const AuthResult.needsConfirm();
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.error(_mapAuth(e));
    } catch (e) {
      return AuthResult.error(_mapGeneric(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      await _client.auth.signOut(scope: SignOutScope.local);
    }
  }

  Future<AuthResult> sendResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.error(_mapAuth(e));
    } catch (e) {
      return AuthResult.error(_mapGeneric(e));
    }
  }

  Future<AuthResult> changePassword(String oldPass, String newPass) async {
    final mail = _client.auth.currentUser?.email;
    if (mail == null) return const AuthResult.error('err_generic');
    try {
      await _client.auth.signInWithPassword(email: mail, password: oldPass);
    } on AuthException {
      return const AuthResult.error('err_old_password_wrong');
    } catch (e) {
      return AuthResult.error(_mapGeneric(e));
    }
    try {
      await _client.auth.updateUser(UserAttributes(password: newPass));
      return const AuthResult.ok();
    } on AuthException catch (e) {
      return AuthResult.error(_mapAuth(e));
    } catch (e) {
      return AuthResult.error(_mapGeneric(e));
    }
  }

  Future<AuthResult> updateProfile({
    String? name,
    int? age,
    String? education,
    String? petName,
  }) async {
    final id = userId;
    if (id == null) return const AuthResult.error('err_generic');
    final changes = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (age != null) 'age': age,
      if (education != null) 'education_level': education.trim(),
      if (petName != null) 'pet_name': petName.trim(),
    };
    try {
      final row = await _client
          .from('profiles')
          .update(changes)
          .eq('id', id)
          .select()
          .single();
      profile = row;
      notifyListeners();
      return const AuthResult.ok();
    } catch (e) {
      return AuthResult.error(_mapGeneric(e));
    }
  }

  Future<AuthResult> deleteAccount() async {
    try {
      await _client.rpc('delete_my_account');
      await _client.auth.signOut(scope: SignOutScope.local);
      return const AuthResult.ok();
    } catch (e) {
      return AuthResult.error(_mapGeneric(e));
    }
  }

  // ------------------------------------------------------- Pemetaan error

  String _mapAuth(AuthException e) {
  debugPrint('AUTH ERROR: ${e.message} | code=${e.code} | status=${e.statusCode}');
    final msg = e.message.toLowerCase();
    final code = (e.code ?? '').toLowerCase();
    if (code == 'invalid_credentials' || msg.contains('invalid login')) {
      return 'err_invalid_credentials';
    }
    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return 'err_email_taken';
    }
    if (code == 'email_not_confirmed' || msg.contains('not confirmed')) {
      return 'err_email_not_confirmed';
    }
    if (code == 'weak_password' || msg.contains('at least')) {
      return 'err_password_short';
    }
    if (code == 'same_password' || msg.contains('different from the old')) {
      return 'err_same_password';
    }
    if (code.contains('rate_limit') || msg.contains('rate limit')) {
      return 'err_rate_limit';
    }
    return _mapGeneric(e);
  }

  String _mapGeneric(Object e) {
   debugPrint('GENERIC ERROR: $e');
    final s = e.toString();
    if (e is TimeoutException ||
        s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('ClientException')) {
      return 'err_network';
    }
    return 'err_generic';
  }
}
