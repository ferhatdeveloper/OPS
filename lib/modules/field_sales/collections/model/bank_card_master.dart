// Dosya Adı: bank_card_master.dart
// Açıklama: MBT Banka Kart Listesi dens master (kod · bakiye · döviz)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import '../../../../core/localization/app_localization.dart';

/// {@template bank_card_option}
/// Banka kartı dens satırı (kod + ünvan + çoklu döviz bakiye stub).
///
/// Kullanım örneği:
/// ```dart
/// const opt = BankCardOption(
///   code: '102 01 01',
///   l10nKey: 'field_sales.bank_card_merkez_tl',
/// );
/// ```
/// {@endtemplate}
class BankCardOption {
  /// [code]: Logo / MBT banka hesap kodu
  final String code;

  /// [l10nKey]: `field_sales.*` ünvan çeviri anahtarı
  final String l10nKey;

  /// [displayName]: Serbest ünvan (CRUD); doluysa l10n yerine kullanılır
  final String? displayName;

  /// [balanceTl]: TL bakiye (stub 0)
  final double balanceTl;

  /// [balanceUsd]: USD bakiye (stub 0)
  final double balanceUsd;

  /// [balanceIqd]: IQD bakiye (stub 0)
  final double balanceIqd;

  /// {@macro bank_card_option}
  const BankCardOption({
    required this.code,
    required this.l10nKey,
    this.displayName,
    this.balanceTl = 0,
    this.balanceUsd = 0,
    this.balanceIqd = 0,
  });

  /// {@template bank_card_option_label}
  /// Yerelleştirilmiş banka ünvanı (veya [displayName]).
  /// {@endtemplate}
  String label(AppLocalization l10n) {
    final free = displayName?.trim();
    if (free != null && free.isNotEmpty) return free;
    if (l10nKey.trim().isEmpty) return code;
    return l10n.translate(l10nKey);
  }

  /// {@template bank_card_option_format_amount}
  /// Dens bakiye gösterimi (`0,00`).
  /// {@endtemplate}
  static String formatAmount(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]}';
  }
}

/// {@template bank_card_master}
/// Banka Kart Listesi dens master (MBT Yönetici → BANKA).
///
/// Kullanım örneği:
/// ```dart
/// final items = BankCardMaster.options;
/// ```
/// {@endtemplate}
class BankCardMaster {
  const BankCardMaster._();

  /// [options]: Dens liste sırası
  static const List<BankCardOption> options = [
    BankCardOption(
      code: '102 01 01',
      l10nKey: 'field_sales.bank_card_merkez_tl',
    ),
    BankCardOption(
      code: '102 01 02',
      l10nKey: 'field_sales.bank_card_merkez_usd',
    ),
    BankCardOption(
      code: '102 01 03',
      l10nKey: 'field_sales.bank_card_merkez_iqd',
    ),
    BankCardOption(
      code: '102 02 01',
      l10nKey: 'field_sales.bank_card_sube_tl',
    ),
  ];

  /// {@template bank_card_master_filter}
  /// Kod / ünvan dens süzgeç.
  /// {@endtemplate}
  static List<BankCardOption> filter(
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
