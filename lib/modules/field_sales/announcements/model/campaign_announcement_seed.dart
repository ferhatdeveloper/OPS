// Dosya Adı: campaign_announcement_seed.dart
// Açıklama: MBT DUYURULAR demo kampanya SQLite seed satırları
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template campaign_announcement_seed}
/// `campaigns` tablosu boşken MBT dens örnek duyuru satırları.
///
/// Kullanım örneği:
/// ```dart
/// for (final map in CampaignAnnouncementSeed.defaultMaps) {
///   await db.insert('campaigns', map);
/// }
/// ```
/// {@endtemplate}
class CampaignAnnouncementSeed {
  CampaignAnnouncementSeed._();

  /// [tableName]: SQLite tablo adı
  static const String tableName = 'campaigns';

  /// MBT cihaz gözlemi: Kampanya Duyurusu · 27-01-2026 → 27-04-2027
  static const List<Map<String, dynamic>> defaultMaps = [
    {
      'id': 'mbt_ann_campaign_1',
      'name': 'Kampanya Duyurusu',
      'campaign_type': 'discount',
      'start_date': '2026-01-27',
      'end_date': '2027-04-27',
      'is_active': 1,
      'is_synced': 0,
    },
  ];
}
