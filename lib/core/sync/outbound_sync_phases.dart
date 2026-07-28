// Dosya Adı: outbound_sync_phases.dart
// Açıklama: Outbound sync aşamaları — Logo önce, PostgREST sonra
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template outbound_sync_phase}
/// JobQueue `sync_phase` değerleri.
///
/// Akış:
/// ```
/// SQLite kaydet → sync_queue(phase=logo)
///   → 1) Logo Tiger/Exfin POST (idempotent NUMBER)
///   → logo_ref + is_synced=1
///   → 2) phase=postgrest → kiracı mirror
///   → pg_synced=1 → kuyruk sil
/// ```
/// {@endtemplate}
class OutboundSyncPhase {
  OutboundSyncPhase._();

  /// [logo]: ERP fiş yazımı (önce)
  static const String logo = 'logo';

  /// [postgrest]: Logo başarılıktan sonra kiracı mirror
  static const String postgrest = 'postgrest';

  /// null / boş → logo aşaması kabul edilir.
  static String normalize(Object? raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s == postgrest) return postgrest;
    return logo;
  }
}
