// Dosya Adı: outbound_sync_phases.dart
// Açıklama: Outbound sync aşamaları — PG pending → Logo → PG confirmed
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

/// {@template outbound_sync_phase}
/// JobQueue `sync_phase` değerleri.
///
/// Akış:
/// ```
/// SQLite kaydet → sync_queue(phase=pg_pending)
///   → 1) PostgREST upsert pending (ops_doc_id, logo_synced=0)
///   → 2) phase=logo → Tiger/Exfin POST (idempotent NUMBER)
///   → logo_ref + is_synced=1
///   → 3) phase=postgrest → PG confirmed (logo_ref, logo_synced=1)
///   → pg_synced=1 → kuyruk sil
/// ```
/// Logo fail olsa bile PG pending satır merkezde kalır (cihaz kaybı yedeği).
/// {@endtemplate}
class OutboundSyncPhase {
  OutboundSyncPhase._();

  /// [pgPending]: Logo öncesi merkez yedek upsert
  static const String pgPending = 'pg_pending';

  /// [logo]: ERP fiş yazımı
  static const String logo = 'logo';

  /// [postgrest]: Logo sonrası kiracı confirmed mirror
  static const String postgrest = 'postgrest';

  /// Bilinen aşamayı döner; boş/bilinmeyen → [pgPending] (güvenli başlangıç).
  static String normalize(Object? raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s == postgrest) return postgrest;
    if (s == logo) return logo;
    if (s == pgPending) return pgPending;
    return pgPending;
  }
}
