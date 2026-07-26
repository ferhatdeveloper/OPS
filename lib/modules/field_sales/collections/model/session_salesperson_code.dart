// Dosya Adı: session_salesperson_code.dart
// Açıklama: Oturum haritasından plasiyer/kullanıcı kodu çözümleyici
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template resolve_salesperson_code_from_session}
/// Nakit tahsilat PLASIYER alanını oturumdan ön-doldurmak için kod seçer.
///
/// Öncelik: Logo plasiyer kodu → kullanıcı kodu (username) → genel kod alanları.
///
/// Parametreler:
/// - [session]: `getUserSession()` sonucu (null olabilir)
///
/// Dönüş değeri:
/// - [String?]: Trimlenmiş kod; yoksa null
///
/// Kullanım örneği:
/// ```dart
/// final code = resolveSalespersonCodeFromSession(session);
/// // örn. 'PLS01' veya 'demo'
/// ```
/// {@endtemplate}
String? resolveSalespersonCodeFromSession(Map<String, dynamic>? session) {
  if (session == null || session.isEmpty) return null;

  const keys = <String>[
    'logo_salesman_code',
    'salesman_code',
    'salesperson_code',
    'username',
    'user_code',
    'code',
  ];

  for (final key in keys) {
    final raw = session[key];
    if (raw == null) continue;
    final value = raw.toString().trim();
    if (value.isNotEmpty) return value;
  }
  return null;
}
