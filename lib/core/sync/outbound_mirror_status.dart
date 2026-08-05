// Dosya Adı: outbound_mirror_status.dart
// Açıklama: PostgREST belge mirror sync_status — logo_pending / confirmed
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

/// {@template outbound_mirror_status}
/// Kiracı PostgREST mirror satır durumu (muhasebe filtresi).
///
/// **Muhasebe kuralı:** `logo_pending` = merkez yedek, ERP fişi yok.
/// Cari hareket / gelir / stok etkisi yalnızca Logo OK sonrası
/// (`confirmed` + `logo_synced=1`) sayılır. Raporlar `logo_synced=1`
/// veya `sync_status=confirmed` filtrelemeli.
///
/// Ortak id: `ops_doc_id` (= SQLite `id` = yazılım ajanı `client_doc_id`).
/// Logo bağlama anahtarı: kararlı `NUMBER` (SPECODE / docTracking değil).
///
/// Akış:
/// ```
/// SQLite (ops_doc_id) → PG upsert logo_pending → Logo → PG confirmed
/// ```
/// Logo fail olsa bile PG’de pending satır kalır (aynı id ile upsert);
/// bu “hayalet fiş” değil — status ile ayrılır.
/// {@endtemplate}
class OutboundMirrorStatus {
  OutboundMirrorStatus._();

  /// [logoPending]: Merkezde kayıt var; Logo henüz yazılmadı.
  /// Muhasebe belgesi sayılmaz.
  static const String logoPending = 'logo_pending';

  /// [confirmed]: Logo OK + mirror güncellendi (`logo_ref` dolu).
  static const String confirmed = 'confirmed';
}
