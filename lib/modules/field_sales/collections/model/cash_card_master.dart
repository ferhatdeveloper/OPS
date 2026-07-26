// Dosya Adı: cash_card_master.dart
// Açıklama: MBT Kasa Kart Listesi master (safe_code) — nakit + KK POS dens
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/localization/app_localization.dart';

/// {@template cash_card_option}
/// Kasa kartı master satırı (Logo safe_code + l10n ünvan).
///
/// Kullanım örneği:
/// ```dart
/// const opt = CashCardOption(
///   code: '100 01 01',
///   l10nKey: 'field_sales.cash_card_merkez_tl',
/// );
/// ```
/// {@endtemplate}
class CashCardOption {
  /// [code]: Logo / MBT kasa kodu (safe_code)
  final String code;

  /// [l10nKey]: `field_sales.*` ünvan çeviri anahtarı
  final String l10nKey;

  /// {@macro cash_card_option}
  const CashCardOption({
    required this.code,
    required this.l10nKey,
  });

  /// {@template cash_card_option_label}
  /// Yerelleştirilmiş kasa ünvanı.
  ///
  /// Parametreler:
  /// - [l10n]: Uygulama yerelleştirmesi
  ///
  /// Dönüş değeri:
  /// - [String]: Dens liste / alan etiketi
  /// {@endtemplate}
  String label(AppLocalization l10n) => l10n.translate(l10nKey);
}

/// {@template cash_card_master}
/// Kasa Kart Listesi dens master (MBT: MERKEZ TL/USD/EURO, ŞUBE TL).
///
/// Fiş TYPE üretmez; nakit / KK tahsilat POS-kasa `safe_code` kaynağıdır.
///
/// Kullanım örneği:
/// ```dart
/// final items = CashCardMaster.options;
/// final label = CashCardMaster.labelOf(l10n, '100 01 01');
/// ```
/// {@endtemplate}
class CashCardMaster {
  /// Master örnekleri oluşturulmaz.
  const CashCardMaster._();

  /// [defaultCode]: MBT nakit formunda görülen varsayılan kasa
  static const String defaultCode = '100 01 01';

  /// [options]: Dens liste sırası (MBT gözlemi)
  static const List<CashCardOption> options = [
    CashCardOption(
      code: '100 01 01',
      l10nKey: 'field_sales.cash_card_merkez_tl',
    ),
    CashCardOption(
      code: '100 01 02',
      l10nKey: 'field_sales.cash_card_merkez_usd',
    ),
    CashCardOption(
      code: '100 01 03',
      l10nKey: 'field_sales.cash_card_merkez_euro',
    ),
    CashCardOption(
      code: '200 01 01',
      l10nKey: 'field_sales.cash_card_sube_tl',
    ),
  ];

  /// {@template cash_card_master_codes}
  /// Tüm master kasa kodları.
  /// {@endtemplate}
  static List<String> get codes =>
      options.map((o) => o.code).toList(growable: false);

  /// {@template cash_card_master_contains}
  /// Kod master’da var mı.
  ///
  /// Parametreler:
  /// - [code]: Kontrol edilecek kasa kodu
  ///
  /// Dönüş değeri:
  /// - [bool]: Geçerli master kodu
  /// {@endtemplate}
  static bool contains(String? code) {
    if (code == null || code.trim().isEmpty) return false;
    return options.any((o) => o.code == code.trim());
  }

  /// {@template cash_card_master_by_code}
  /// Koda göre master satırı (yoksa null).
  ///
  /// Parametreler:
  /// - [code]: safe_code
  ///
  /// Dönüş değeri:
  /// - [CashCardOption?]: Eşleşen satır
  /// {@endtemplate}
  static CashCardOption? byCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final trimmed = code.trim();
    for (final o in options) {
      if (o.code == trimmed) return o;
    }
    return null;
  }

  /// {@template cash_card_master_label_of}
  /// Kod → yerelleştirilmiş ünvan (bilinmeyen kodda ham değer).
  ///
  /// Parametreler:
  /// - [l10n]: Yerelleştirme
  /// - [code]: safe_code
  ///
  /// Dönüş değeri:
  /// - [String]: Ünvan veya kod
  /// {@endtemplate}
  static String labelOf(AppLocalization l10n, String? code) {
    final opt = byCode(code);
    if (opt == null) return code?.trim() ?? '';
    return opt.label(l10n);
  }

  /// {@template cash_card_master_display}
  /// Dens alan gösterimi: `kod · ünvan`.
  ///
  /// Parametreler:
  /// - [l10n]: Yerelleştirme
  /// - [code]: safe_code
  ///
  /// Dönüş değeri:
  /// - [String]: Seçici alan metni
  /// {@endtemplate}
  static String displayOf(AppLocalization l10n, String? code) {
    final opt = byCode(code);
    if (opt == null) return code?.trim() ?? '';
    return '${opt.code} · ${opt.label(l10n)}';
  }

  /// {@template cash_card_master_filter}
  /// Kod / ünvan ile dens süzgeç.
  ///
  /// Parametreler:
  /// - [l10n]: Yerelleştirme
  /// - [query]: Arama metni
  ///
  /// Dönüş değeri:
  /// - [List]: Eşleşen master satırları
  /// {@endtemplate}
  static List<CashCardOption> filter(
    AppLocalization l10n,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return options;
    return options
        .where(
          (o) =>
              o.code.toLowerCase().contains(q) ||
              o.label(l10n).toLowerCase().contains(q),
        )
        .toList(growable: false);
  }
}
