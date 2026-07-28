// Dosya Adı: promissory_list_status.dart
// Açıklama: MBT Senet Listesi dens durum sekmeleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template promissory_list_status}
/// Senet yaşam döngüsü dens durumu (MBT sekmeler — çek ile parity).
///
/// Kullanım örneği:
/// ```dart
/// final s = PromissoryListStatus.fromCode('collection');
/// ```
/// {@endtemplate}
enum PromissoryListStatus {
  /// Portföydeki / teminata
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

  /// Ödenen firma senetleri
  paidCompany,

  /// Verilen firma senetleri
  issuedCompany;

  /// {@template promissory_list_status_code}
  /// Seed / storage kodu.
  /// {@endtemplate}
  String get code {
    switch (this) {
      case PromissoryListStatus.collateral:
        return 'collateral';
      case PromissoryListStatus.collection:
        return 'collection';
      case PromissoryListStatus.returned:
        return 'returned';
      case PromissoryListStatus.collected:
        return 'collected';
      case PromissoryListStatus.bounced:
        return 'bounced';
      case PromissoryListStatus.uncollectible:
        return 'uncollectible';
      case PromissoryListStatus.paidCompany:
        return 'paid_company';
      case PromissoryListStatus.issuedCompany:
        return 'issued_company';
    }
  }

  /// {@template promissory_list_status_l10n}
  /// Sekme çeviri anahtarı.
  /// {@endtemplate}
  String get l10nKey {
    switch (this) {
      case PromissoryListStatus.collateral:
        return 'field_sales.promissory_status_collateral';
      case PromissoryListStatus.collection:
        return 'field_sales.promissory_status_collection';
      case PromissoryListStatus.returned:
        return 'field_sales.promissory_status_returned';
      case PromissoryListStatus.collected:
        return 'field_sales.promissory_status_collected';
      case PromissoryListStatus.bounced:
        return 'field_sales.promissory_status_bounced';
      case PromissoryListStatus.uncollectible:
        return 'field_sales.promissory_status_uncollectible';
      case PromissoryListStatus.paidCompany:
        return 'field_sales.promissory_status_paid_company';
      case PromissoryListStatus.issuedCompany:
        return 'field_sales.promissory_status_issued_company';
    }
  }

  /// MBT dens sekme sırası.
  static const List<PromissoryListStatus> tabs = [
    PromissoryListStatus.collateral,
    PromissoryListStatus.collection,
    PromissoryListStatus.returned,
    PromissoryListStatus.collected,
    PromissoryListStatus.bounced,
    PromissoryListStatus.uncollectible,
    PromissoryListStatus.paidCompany,
    PromissoryListStatus.issuedCompany,
  ];

  /// Kod → durum; bilinmeyen → tahsile verilen.
  static PromissoryListStatus fromCode(String? raw) {
    final v = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
    for (final s in PromissoryListStatus.values) {
      if (s.code == v) return s;
    }
    return PromissoryListStatus.collection;
  }
}
