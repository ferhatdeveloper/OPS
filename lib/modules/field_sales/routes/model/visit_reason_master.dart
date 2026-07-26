// Dosya Adı: visit_reason_master.dart
// Açıklama: MBT ZIYARET SEBEBI dens dropdown master listesi (kod + l10n)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';

/// {@template visit_reason_option}
/// Ziyaret sebebi master satırı (stabil kod + l10n anahtarı).
///
/// Kullanım örneği:
/// ```dart
/// final opt = VisitReasonOption(
///   code: 'ROUTINE',
///   l10nKey: 'field_sales.routine_visit',
/// );
/// ```
/// {@endtemplate}
class VisitReasonOption {
  /// [code]: Kalıcı / senkron kodu (dil bağımsız)
  final String code;

  /// [l10nKey]: `field_sales.*` çeviri anahtarı
  final String l10nKey;

  /// {@macro visit_reason_option}
  const VisitReasonOption({
    required this.code,
    required this.l10nKey,
  });

  /// {@template visit_reason_option_label}
  /// Yerelleştirilmiş etiket.
  ///
  /// Parametreler:
  /// - [l10n]: Uygulama yerelleştirmesi
  ///
  /// Dönüş değeri:
  /// - [String]: Dropdown / not metni
  /// {@endtemplate}
  String label(AppLocalization l10n) => l10n.translate(l10nKey);
}

/// {@template visit_reason_master}
/// ZIYARET SEBEBI dens dropdown master listesi.
///
/// Kodlar dil bağımsızdır; UI etiketi l10n ile çözülür.
/// MBT ekranında picker içeriği dump edilmedi — OPS saha satış
/// standart sebepleri (mevcut l10n key’leri) master olarak sabitlenir.
///
/// Kullanım örneği:
/// ```dart
/// final items = VisitReasonMaster.options;
/// final label = VisitReasonMaster.labelOf(l10n, 'ROUTINE');
/// ```
/// {@endtemplate}
class VisitReasonMaster {
  /// Master örnekleri oluşturulmaz.
  const VisitReasonMaster._();

  /// [options]: Dens dropdown sırası (master)
  static const List<VisitReasonOption> options = [
    VisitReasonOption(
      code: 'ROUTINE',
      l10nKey: 'field_sales.routine_visit',
    ),
    VisitReasonOption(
      code: 'COLLECTION',
      l10nKey: 'field_sales.collection_meeting',
    ),
    VisitReasonOption(
      code: 'CAMPAIGN',
      l10nKey: 'field_sales.campaign_intro',
    ),
    VisitReasonOption(
      code: 'COMPLAINT',
      l10nKey: 'field_sales.complaint_management',
    ),
    VisitReasonOption(
      code: 'ORDER',
      l10nKey: 'field_sales.visit_reason_order',
    ),
    VisitReasonOption(
      code: 'STOCK',
      l10nKey: 'field_sales.visit_reason_stock',
    ),
    VisitReasonOption(
      code: 'DELIVERY',
      l10nKey: 'field_sales.visit_reason_delivery',
    ),
    VisitReasonOption(
      code: 'NEW_CUSTOMER',
      l10nKey: 'field_sales.visit_reason_new_customer',
    ),
    VisitReasonOption(
      code: 'OTHER',
      l10nKey: 'field_sales.visit_reason_other',
    ),
  ];

  /// {@template visit_reason_master_codes}
  /// Tüm master kodları.
  /// {@endtemplate}
  static List<String> get codes =>
      options.map((o) => o.code).toList(growable: false);

  /// {@template visit_reason_master_contains}
  /// Kod master’da var mı.
  ///
  /// Parametreler:
  /// - [code]: Kontrol edilecek kod
  ///
  /// Dönüş değeri:
  /// - [bool]: Geçerli master kodu
  /// {@endtemplate}
  static bool contains(String? code) {
    if (code == null || code.trim().isEmpty) return false;
    return options.any((o) => o.code == code);
  }

  /// {@template visit_reason_master_by_code}
  /// Koda göre master satırı (yoksa null).
  ///
  /// Parametreler:
  /// - [code]: Stabil kod
  ///
  /// Dönüş değeri:
  /// - [VisitReasonOption?]: Eşleşen satır
  /// {@endtemplate}
  static VisitReasonOption? byCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    for (final o in options) {
      if (o.code == code) return o;
    }
    return null;
  }

  /// {@template visit_reason_master_label_of}
  /// Kod → yerelleştirilmiş etiket (bilinmeyen kodda ham değer).
  ///
  /// Parametreler:
  /// - [l10n]: Yerelleştirme
  /// - [code]: Stabil kod
  ///
  /// Dönüş değeri:
  /// - [String]: Etiket veya kod
  /// {@endtemplate}
  static String labelOf(AppLocalization l10n, String? code) {
    final opt = byCode(code);
    if (opt == null) return code?.trim() ?? '';
    return opt.label(l10n);
  }

  /// {@template visit_reason_master_labeled}
  /// Dens dropdown için (kod, etiket) listesi.
  ///
  /// Parametreler:
  /// - [l10n]: Yerelleştirme
  ///
  /// Dönüş değeri:
  /// - [List]: `{code, label}` map listesi
  /// {@endtemplate}
  static List<Map<String, String>> labeled(AppLocalization l10n) {
    return options
        .map(
          (o) => <String, String>{
            'code': o.code,
            'label': o.label(l10n),
          },
        )
        .toList(growable: false);
  }
}
