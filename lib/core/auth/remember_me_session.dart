// Dosya Adı: remember_me_session.dart
// Açıklama: Beni hatırla oturum modeli (token + kullanıcı + kiracı)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template remember_me_session}
/// Otomatik giriş için saklanan oturum özeti.
/// PostgREST JWT yoksa [sessionToken] yerel `session_id`’dir.
///
/// Kullanım örneği:
/// ```dart
/// const s = RememberMeSession(
///   sessionToken: 'sid',
///   username: 'admin',
///   userId: '1',
///   role: 'admin',
///   email: '',
///   fullName: 'Admin',
///   tenantCode: 'lovan',
/// );
/// print(s.isValid);
/// ```
/// {@endtemplate}
class RememberMeSession {
  /// [sessionToken]: Yerel oturum / session_id
  final String sessionToken;

  /// [username]: Kullanıcı adı
  final String username;

  /// [userId]: Kullanıcı id
  final String userId;

  /// [role]: Rol claim
  final String role;

  /// [email]: E-posta
  final String email;

  /// [fullName]: Görünen ad
  final String fullName;

  /// [tenantCode]: Kiracı kodu
  final String tenantCode;

  /// {@macro remember_me_session}
  const RememberMeSession({
    required this.sessionToken,
    required this.username,
    required this.userId,
    required this.role,
    required this.email,
    required this.fullName,
    required this.tenantCode,
  });

  /// Otomatik giriş için yeterli mi?
  bool get isValid =>
      sessionToken.trim().isNotEmpty && username.trim().isNotEmpty;

  /// Dashboard / session map uyumlu kullanıcı özeti.
  Map<String, dynamic> toUserSessionMap() {
    return {
      'id': userId,
      'user_id': userId,
      'username': username,
      'role': role,
      'email': email,
      'full_name': fullName,
      'session_id': sessionToken,
    };
  }
}
