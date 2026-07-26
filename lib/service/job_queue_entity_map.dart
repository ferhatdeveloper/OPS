// Dosya Adı: job_queue_entity_map.dart
// Açıklama: JobQueue entity_type → tablo eşlemesi + visit kuyruk payload kontrolleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template job_queue_entity_table}
/// JobQueue `entity_type` → yerel SQLite tablo (`is_synced` güncellemesi).
///
/// Kullanım örneği:
/// ```dart
/// final t = jobQueueEntityTable('visit'); // visits
/// ```
/// {@endtemplate}
String? jobQueueEntityTable(String type) {
  final t = type.toLowerCase();
  if (t == 'stock_transfer' ||
      t == 'warehouse_transfer' ||
      t == 'warehouse_transfers') {
    return 'warehouse_transfers';
  }
  if (t == 'whms_load_order' || t == 'load_order') {
    // Yükleme emri doğrudan vehicle_stocks’a consume edilir; tablo sync yok
    return null;
  }
  return switch (t) {
    'order' || 'orders' => 'orders',
    'invoice' || 'invoices' => 'invoices',
    'collection' || 'collections' => 'collections',
    'stock_count' || 'stock_counts' => 'stock_counts',
    'dispatch' || 'dispatches' || 'waybill' || 'waybills' => 'waybills',
    'visit' || 'visits' => 'visits',
    _ => null,
  };
}

/// {@template is_visit_queue_payload_ready}
/// Ziyaret kuyruk payload'ı işlenebilir mi? (boşsa fail → is_synced yok)
/// {@endtemplate}
bool isVisitQueuePayloadReady(Map<String, dynamic>? payload) {
  return payload != null && payload.isNotEmpty;
}

/// {@template visit_queue_skipped_data}
/// Logo visit API yokken kuyruk başarı gövdesi (`ok/skipped`).
/// {@endtemplate}
Map<String, dynamic> visitQueueSkippedData(Map<String, dynamic> payload) {
  return {
    'skipped': true,
    'entity_type': 'visit',
    'entity_id': payload['local_visit_id'],
  };
}
