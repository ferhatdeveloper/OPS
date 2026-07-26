// Dosya Adı: announcement_campaign_row.dart
// Açıklama: Duyurular dens satırı — campaigns SQLite eşlemesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template announcement_campaign_row}
/// Plasiyer duyuru dens satırı (kampanya adı · başlangıç · bitiş).
///
/// Kullanım örneği:
/// ```dart
/// final row = AnnouncementCampaignRow.fromCampaignMap(map);
/// print(row.startDisplay); // 27-01-2026
/// ```
/// {@endtemplate}
class AnnouncementCampaignRow {
  /// [id]: campaigns.id
  final String id;

  /// [title]: Kampanya duyurusu metni (campaigns.name)
  final String title;

  /// [startDisplay]: Başlangıç (DD-MM-YYYY)
  final String startDisplay;

  /// [endDisplay]: Bitiş (DD-MM-YYYY)
  final String endDisplay;

  /// {@macro announcement_campaign_row}
  const AnnouncementCampaignRow({
    required this.id,
    required this.title,
    required this.startDisplay,
    required this.endDisplay,
  });

  /// {@template fromCampaignMap}
  /// Tek campaigns satırını dens duyuru satırına çevirir.
  ///
  /// Parametreler:
  /// - [map]: SQLite campaigns satırı
  ///
  /// Dönüş değeri:
  /// - [AnnouncementCampaignRow]: Dens satır
  /// {@endtemplate}
  factory AnnouncementCampaignRow.fromCampaignMap(
    Map<String, dynamic> map,
  ) {
    return AnnouncementCampaignRow(
      id: (map['id'] ?? '').toString(),
      title: (map['name'] ?? '').toString(),
      startDisplay: formatAnnouncementDate(
        (map['start_date'] ?? '').toString(),
      ),
      endDisplay: formatAnnouncementDate(
        (map['end_date'] ?? '').toString(),
      ),
    );
  }

  /// {@template fromCampaignMaps}
  /// Aktif kampanyaları başlangıç tarihine göre (yeni → eski) listeler.
  ///
  /// Parametreler:
  /// - [maps]: SQLite campaigns satırları
  ///
  /// Dönüş değeri:
  /// - [List]: Dens duyuru satırları
  /// {@endtemplate}
  static List<AnnouncementCampaignRow> fromCampaignMaps(
    List<Map<String, dynamic>> maps,
  ) {
    final active = maps.where((m) {
      final flag = m['is_active'];
      if (flag == null) return true;
      if (flag is int) return flag == 1;
      return flag.toString() == '1' || flag.toString().toLowerCase() == 'true';
    }).toList();

    active.sort((a, b) {
      final da = _parseSortDate((a['start_date'] ?? '').toString());
      final db = _parseSortDate((b['start_date'] ?? '').toString());
      return db.compareTo(da);
    });

    return active
        .map(AnnouncementCampaignRow.fromCampaignMap)
        .toList(growable: false);
  }
}

/// {@template formatAnnouncementDate}
/// ISO veya ham tarihi MBT DD-MM-YYYY gösterimine çevirir.
///
/// Parametreler:
/// - [raw]: Ham tarih metni
///
/// Dönüş değeri:
/// - [String]: Görüntü tarihi
/// {@endtemplate}
String formatAnnouncementDate(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(t)) return t;
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
  if (iso != null) {
    return '${iso.group(3)}-${iso.group(2)}-${iso.group(1)}';
  }
  return t;
}

DateTime _parseSortDate(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
  if (iso != null) {
    return DateTime(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }
  final dmy = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(t);
  if (dmy != null) {
    return DateTime(
      int.parse(dmy.group(3)!),
      int.parse(dmy.group(2)!),
      int.parse(dmy.group(1)!),
    );
  }
  final parsed = DateTime.tryParse(t);
  return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
}
