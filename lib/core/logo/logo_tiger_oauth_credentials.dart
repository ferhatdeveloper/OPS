// Dosya Adı: logo_tiger_oauth_credentials.dart
// Açıklama: Logo panel OAuth client_id/secret format yardımcısı
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'dart:convert';

/// {@template logo_tiger_oauth_credentials}
/// Logo Objects REST OAuth alanları.
///
/// Token isteği (`POST /token`) form-urlencoded gövdede `client_id` ve
/// `client_secret` ham string olarak gönderilir; başarısızsa Basic
/// `base64(client_id:client_secret)` denenir.
///
/// Logo paneli tek satırlık Base64 verir: `Base64(clientId + "~" + secret)`.
/// Bu bütünü `client_secret` alanına yapıştırmayın — decode edip `~`
/// (veya `+`) sonrasını secret olarak kullanın.
///
/// Kullanım örneği:
/// ```dart
/// final c = LogoTigerOAuthCredentials.tryParsePanelKey(panelB64);
/// // client_id = c.clientId; client_secret = c.clientSecret;
/// ```
/// {@endtemplate}
class LogoTigerOAuthCredentials {
  /// [clientId]: Logo paneli “Rest Servis Anahtar Sahibi (ClientId)”
  final String clientId;

  /// [clientSecret]: Panel secret’ı (`~`/`+` sonrası; dış Base64 değil)
  final String clientSecret;

  /// {@macro logo_tiger_oauth_credentials}
  const LogoTigerOAuthCredentials({
    required this.clientId,
    required this.clientSecret,
  });

  /// {@template logo_tiger_oauth_credentials_try_parse}
  /// Logo panel birleşik anahtarını ayırır.
  ///
  /// Kabul edilen girişler:
  /// - Panel Base64: `Base64(clientId + "~" + secret)` (Logo standart)
  /// - Eski / düz: `clientId+secret` veya `clientId~secret`
  ///
  /// Dönüş değeri:
  /// - [LogoTigerOAuthCredentials]: Ayrıştırma başarılıysa
  /// - `null`: Ayırıcı yok — ham secret olduğu gibi kullanılmalı
  /// {@endtemplate}
  static LogoTigerOAuthCredentials? tryParsePanelKey(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;

    var combined = input;
    final decoded = _tryBase64Utf8(input);
    if (decoded != null && _hasCredentialSeparator(decoded)) {
      combined = decoded;
    }

    final sepIndex = _firstSeparatorIndex(combined);
    if (sepIndex == null) return null;

    final id = combined.substring(0, sepIndex).trim();
    final secret = combined.substring(sepIndex + 1);
    if (id.isEmpty || secret.isEmpty) return null;
    if (id.contains(RegExp(r'\s'))) return null;

    return LogoTigerOAuthCredentials(clientId: id, clientSecret: secret);
  }

  static bool _hasCredentialSeparator(String text) =>
      text.contains('~') || text.contains('+');

  /// Logo paneli `~` kullanır; bazı çıktılar `+` gösterebilir.
  static int? _firstSeparatorIndex(String text) {
    final tilde = text.indexOf('~');
    final plus = text.indexOf('+');
    if (tilde < 0 && plus < 0) return null;
    if (tilde < 0) return plus;
    if (plus < 0) return tilde;
    return tilde < plus ? tilde : plus;
  }

  static String? _tryBase64Utf8(String raw) {
    try {
      final bytes = base64Decode(raw);
      final text = utf8.decode(bytes);
      if (text.isEmpty) return null;
      return text;
    } catch (_) {
      return null;
    }
  }
}
