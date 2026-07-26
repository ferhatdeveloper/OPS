// Dosya Adı: waybill_pending_seed.dart
// Açıklama: Bekleyen irsaliye dens stub seed (approval_status=0)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template waybill_pending_seed}
/// MBT Bekleyen İrsaliyeler dens seed satırları (SQLite boş pending).
///
/// Kullanım örneği:
/// ```dart
/// final maps = WaybillPendingSeed.defaultMaps();
/// ```
/// {@endtemplate}
class WaybillPendingSeed {
  WaybillPendingSeed._();

  /// Satış dens belge no (liste title)
  static const String salesDocNo = 'IRS-PENDING-S';

  /// Alış dens belge no
  static const String purchaseDocNo = 'IRS-PENDING-P';

  /// {@template waybill_pending_seed_default_maps}
  /// Yer tutucu dens satırlar (onay bekleyen; bu ay tarihli).
  ///
  /// Dönüş değeri:
  /// - [List<Map>]: `waybills` insert map'leri
  /// {@endtemplate}
  static List<Map<String, dynamic>> defaultMaps({DateTime? now}) {
    final base = now ?? DateTime.now();
    final date = DateTime(base.year, base.month, base.day.clamp(1, 28));
    final iso = date.toIso8601String();
    final stamp = DateTime.now().toIso8601String();

    return [
      {
        'id': 'seed-wb-pending-sales',
        'customer_id': 'C-PENDING-S',
        'waybill_date': iso,
        'waybill_type': 'waybill_wholesale',
        'total_amount': 1250.0,
        'status': 'Pending',
        'notes': salesDocNo,
        'approval_status': 0,
        'is_synced': 0,
        'created_at': stamp,
        'updated_at': stamp,
      },
      {
        'id': 'seed-wb-pending-purchase',
        'customer_id': 'C-PENDING-P',
        'waybill_date': iso,
        'waybill_type': 'waybill_purchase',
        'total_amount': 890.5,
        'status': 'Pending',
        'notes': purchaseDocNo,
        'approval_status': 0,
        'is_synced': 0,
        'created_at': stamp,
        'updated_at': stamp,
      },
    ];
  }
}
