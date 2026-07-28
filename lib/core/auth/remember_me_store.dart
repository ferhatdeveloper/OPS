// Dosya Adı: remember_me_store.dart
// Açıklama: Beni hatırla oturumunu SharedPreferences ile kalıcı tutar
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:shared_preferences/shared_preferences.dart';

import 'remember_me_crypto.dart';
import 'remember_me_session.dart';

/// {@template remember_me_store}
/// “Beni hatırla” oturum token + obfuscate şifre saklama.
///
/// Kullanım örneği:
/// ```dart
/// const store = RememberMeStore();
/// if (await store.canAutoLogin()) {
///   final s = await store.load();
/// }
/// ```
/// {@endtemplate}
class RememberMeStore {
  /// [prefsEnabled]: Beni hatırla açık mı
  static const String prefsEnabled = 'ops_remember_me_enabled';

  /// [prefsSessionToken]: session_id
  static const String prefsSessionToken = 'ops_remember_session_token';

  /// [prefsUsername]: kullanıcı adı
  static const String prefsUsername = 'ops_remember_username';

  /// [prefsUserId]: kullanıcı id
  static const String prefsUserId = 'ops_remember_user_id';

  /// [prefsRole]: rol
  static const String prefsRole = 'ops_remember_role';

  /// [prefsEmail]: e-posta
  static const String prefsEmail = 'ops_remember_email';

  /// [prefsFullName]: ad soyad
  static const String prefsFullName = 'ops_remember_full_name';

  /// [prefsTenantCode]: kiracı
  static const String prefsTenantCode = 'ops_remember_tenant_code';

  /// [prefsPasswordCipher]: obfuscate şifre (yedek)
  static const String prefsPasswordCipher = 'ops_remember_password_cipher';

  /// [prefsKeyMaterial]: XOR tohumu (cihazda üretilir)
  static const String prefsKeyMaterial = 'ops_remember_key_material';

  /// {@macro remember_me_store}
  const RememberMeStore();

  /// {@template remember_me_store_is_enabled}
  /// Beni hatırla bayrağı.
  /// {@endtemplate}
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsEnabled) ?? false;
  }

  /// {@template remember_me_store_set_enabled}
  /// Yalnızca bayrağı ayarlar (oturum verisini silmez).
  /// {@endtemplate}
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsEnabled, enabled);
  }

  /// {@template remember_me_store_can_auto_login}
  /// Açık + geçerli session token → splash’te login atlanabilir.
  /// {@endtemplate}
  Future<bool> canAutoLogin() async {
    if (!await isEnabled()) return false;
    final session = await load();
    return session != null && session.isValid;
  }

  /// {@template remember_me_store_save}
  /// Oturumu kaydeder; [plainPassword] varsa obfuscate edilir.
  ///
  /// Parametreler:
  /// - [session]: Oturum özeti
  /// - [plainPassword]: Opsiyonel düz şifre (JWT yoksa yedek)
  /// {@endtemplate}
  Future<void> save(
    RememberMeSession session, {
    String? plainPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _ensureKeyMaterial(prefs);
    await prefs.setBool(prefsEnabled, true);
    await prefs.setString(prefsSessionToken, session.sessionToken);
    await prefs.setString(prefsUsername, session.username);
    await prefs.setString(prefsUserId, session.userId);
    await prefs.setString(prefsRole, session.role);
    await prefs.setString(prefsEmail, session.email);
    await prefs.setString(prefsFullName, session.fullName);
    await prefs.setString(prefsTenantCode, session.tenantCode);
    if (plainPassword != null && plainPassword.isNotEmpty) {
      await prefs.setString(
        prefsPasswordCipher,
        RememberMeCrypto.encrypt(plainPassword, keyMaterial: key),
      );
    } else {
      await prefs.remove(prefsPasswordCipher);
    }
  }

  /// {@template remember_me_store_load}
  /// Kayıtlı oturumu okur; yoksa null.
  /// {@endtemplate}
  Future<RememberMeSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(prefsEnabled) ?? false)) return null;
    final token = (prefs.getString(prefsSessionToken) ?? '').trim();
    final username = (prefs.getString(prefsUsername) ?? '').trim();
    if (token.isEmpty && username.isEmpty) return null;
    return RememberMeSession(
      sessionToken: token,
      username: username,
      userId: prefs.getString(prefsUserId) ?? '',
      role: prefs.getString(prefsRole) ?? '',
      email: prefs.getString(prefsEmail) ?? '',
      fullName: prefs.getString(prefsFullName) ?? '',
      tenantCode: prefs.getString(prefsTenantCode) ?? '',
    );
  }

  /// {@template remember_me_store_load_plain_password}
  /// Obfuscate şifreyi çözer; yoksa null.
  /// {@endtemplate}
  Future<String?> loadPlainPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final cipher = prefs.getString(prefsPasswordCipher);
    if (cipher == null || cipher.isEmpty) return null;
    final key = await _ensureKeyMaterial(prefs);
    final plain = RememberMeCrypto.decrypt(cipher, keyMaterial: key);
    if (plain.isEmpty) return null;
    return plain;
  }

  /// {@template remember_me_store_clear}
  /// Logout / beni hatırla kapalı: tüm remember-me verisini siler.
  /// {@endtemplate}
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsEnabled);
    await prefs.remove(prefsSessionToken);
    await prefs.remove(prefsUsername);
    await prefs.remove(prefsUserId);
    await prefs.remove(prefsRole);
    await prefs.remove(prefsEmail);
    await prefs.remove(prefsFullName);
    await prefs.remove(prefsTenantCode);
    await prefs.remove(prefsPasswordCipher);
    // key material cihazda kalabilir; yeni kayıtta yeniden kullanılır
  }

  Future<String> _ensureKeyMaterial(SharedPreferences prefs) async {
    final existing = prefs.getString(prefsKeyMaterial);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated =
        'rm-${DateTime.now().microsecondsSinceEpoch}-${prefs.hashCode}';
    await prefs.setString(prefsKeyMaterial, generated);
    return generated;
  }
}
