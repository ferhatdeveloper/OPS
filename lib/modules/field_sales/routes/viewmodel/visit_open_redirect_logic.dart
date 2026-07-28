// Dosya Adı: visit_open_redirect_logic.dart
// Açıklama: Açık ziyaret yönlendirme kararları (UI / Provider yok)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// Açık ziyaret engeli l10n hata anahtarı.
const String kVisitAlreadyOpenErrorKey = 'field_sales.visit_already_open';

/// {@template should_redirect_to_open_visit}
/// Check-in hatası açık ziyaret engeli mi?
/// {@endtemplate}
bool shouldRedirectToOpenVisit(String? error) =>
    error == kVisitAlreadyOpenErrorKey;

/// {@template open_visit_redirect_customer_id}
/// Açık ziyaretten forma gidecek cari id (boşsa yönlendirme yok).
/// {@endtemplate}
String? openVisitRedirectCustomerId(String? customerId) {
  final id = customerId?.trim() ?? '';
  return id.isEmpty ? null : id;
}
