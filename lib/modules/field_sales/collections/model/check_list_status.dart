// Dosya Adı: check_list_status.dart
// Açıklama: MBT Çek Listesi dens durum sekmeleri (master)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template check_list_status}
/// Çek yaşam döngüsü dens durumu (MBT sekmeler).
///
/// Kullanım örneği:
/// ```dart
/// final s = CheckListStatus.fromCode('collection');
/// assert(s.l10nKey.endsWith('collection'));
/// ```
/// {@endtemplate}
enum CheckListStatus {
  /// Teminata verilen
  collateral,

  /// Tahsile verilen
  collection,

  /// İade edilen
  returned,

  /// Tahsil edilen
  collected,

  /// Karşılıksız
  bounced,

  /// Tahsil edilemeyen
  uncollectible,

  /// Ödenen firma çekleri
  paidCompany,

  /// Verilen firma çekleri
  issuedCompany;

  /// {@template check_list_status_code}
  /// SQLite / seed `check_status` kodu.
  /// {@endtemplate}
  String get code {
    switch (this) {
      case CheckListStatus.collateral:
        return 'collateral';
      case CheckListStatus.collection:
        return 'collection';
      case CheckListStatus.returned:
        return 'returned';
      case CheckListStatus.collected:
        return 'collected';
      case CheckListStatus.bounced:
        return 'bounced';
      case CheckListStatus.uncollectible:
        return 'uncollectible';
      case CheckListStatus.paidCompany:
        return 'paid_company';
      case CheckListStatus.issuedCompany:
        return 'issued_company';
    }
  }

  /// {@template check_list_status_l10n}
  /// Sekme çeviri anahtarı.
  /// {@endtemplate}
  String get l10nKey {
    switch (this) {
      case CheckListStatus.collateral:
        return 'field_sales.check_status_collateral';
      case CheckListStatus.collection:
        return 'field_sales.check_status_collection';
      case CheckListStatus.returned:
        return 'field_sales.check_status_returned';
      case CheckListStatus.collected:
        return 'field_sales.check_status_collected';
      case CheckListStatus.bounced:
        return 'field_sales.check_status_bounced';
      case CheckListStatus.uncollectible:
        return 'field_sales.check_status_uncollectible';
      case CheckListStatus.paidCompany:
        return 'field_sales.check_status_paid_company';
      case CheckListStatus.issuedCompany:
        return 'field_sales.check_status_issued_company';
    }
  }

  /// {@template check_list_status_tabs}
  /// MBT dens sekme sırası.
  /// {@endtemplate}
  static const List<CheckListStatus> tabs = [
    CheckListStatus.collateral,
    CheckListStatus.collection,
    CheckListStatus.returned,
    CheckListStatus.collected,
    CheckListStatus.bounced,
    CheckListStatus.uncollectible,
    CheckListStatus.paidCompany,
    CheckListStatus.issuedCompany,
  ];

  /// {@template check_list_status_from_code}
  /// Kod → durum; bilinmeyen → tahsile verilen.
  /// {@endtemplate}
  static CheckListStatus fromCode(String? raw) {
    final v = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
    for (final s in CheckListStatus.values) {
      if (s.code == v) return s;
    }
    return CheckListStatus.collection;
  }
}
