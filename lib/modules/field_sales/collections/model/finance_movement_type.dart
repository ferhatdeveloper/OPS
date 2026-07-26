// Dosya Adı: finance_movement_type.dart
// Açıklama: Finans Yeni Hareket 7 tip — API payment_type map
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template finance_movement_kind}
/// Hareket sınıfı: tahsilat / ödeme / virman.
/// {@endtemplate}
enum FinanceMovementKind {
  /// Cari alacak (tahsilat)
  collection,

  /// Cari borç artırıcı / kasa çıkış (ödeme)
  payment,

  /// Kasa↔kasa; cari yok
  virman,
}

/// {@template finance_movement_type}
/// MBT Finans → Yeni Hareket 7 tip sheet değerleri.
///
/// API `payment_type`: cash / credit_card / check / note /
/// CashOut / CreditCardOut / virman.
///
/// Kullanım örneği:
/// ```dart
/// final t = FinanceMovementType.fromStorage('CreditCard');
/// assert(t.apiCode == 'credit_card');
/// ```
/// {@endtemplate}
enum FinanceMovementType {
  /// Nakit tahsilat
  cashCollection,

  /// Kredi kartı tahsilat
  creditCardCollection,

  /// Çek tahsilat
  checkCollection,

  /// Senet tahsilat
  noteCollection,

  /// Nakit ödeme (kasa çıkış)
  cashOut,

  /// Kredi kartı ödeme
  creditCardOut,

  /// Virman (kasa↔kasa)
  virman;

  /// {@template finance_movement_type_kind}
  /// Tahsilat / ödeme / virman sınıfı.
  /// {@endtemplate}
  FinanceMovementKind get kind {
    switch (this) {
      case FinanceMovementType.cashOut:
      case FinanceMovementType.creditCardOut:
        return FinanceMovementKind.payment;
      case FinanceMovementType.virman:
        return FinanceMovementKind.virman;
      case FinanceMovementType.cashCollection:
      case FinanceMovementType.creditCardCollection:
      case FinanceMovementType.checkCollection:
      case FinanceMovementType.noteCollection:
        return FinanceMovementKind.collection;
    }
  }

  /// {@template finance_movement_type_requires_customer}
  /// Cari zorunlu mu (virman hariç evet).
  /// {@endtemplate}
  bool get requiresCustomer => kind != FinanceMovementKind.virman;

  /// {@template finance_movement_type_api_code}
  /// Logo / sync `payment_type` değeri (KDV yok).
  /// {@endtemplate}
  String get apiCode {
    switch (this) {
      case FinanceMovementType.cashCollection:
        return 'cash';
      case FinanceMovementType.creditCardCollection:
        return 'credit_card';
      case FinanceMovementType.checkCollection:
        return 'check';
      case FinanceMovementType.noteCollection:
        return 'note';
      case FinanceMovementType.cashOut:
        return 'CashOut';
      case FinanceMovementType.creditCardOut:
        return 'CreditCardOut';
      case FinanceMovementType.virman:
        return 'virman';
    }
  }

  /// {@template finance_movement_type_l10n}
  /// Sheet satır çeviri anahtarı.
  /// {@endtemplate}
  String get titleL10nKey {
    switch (this) {
      case FinanceMovementType.cashCollection:
        return 'field_sales.finance_type_cash_in';
      case FinanceMovementType.creditCardCollection:
        return 'field_sales.finance_type_card_in';
      case FinanceMovementType.checkCollection:
        return 'field_sales.finance_type_check_in';
      case FinanceMovementType.noteCollection:
        return 'field_sales.finance_type_note_in';
      case FinanceMovementType.cashOut:
        return 'field_sales.finance_type_cash_out';
      case FinanceMovementType.creditCardOut:
        return 'field_sales.finance_type_card_out';
      case FinanceMovementType.virman:
        return 'field_sales.finance_type_virman';
    }
  }

  /// {@template finance_movement_type_is_check}
  /// Çek detay formu gerekir mi.
  /// {@endtemplate}
  bool get isCheck => this == FinanceMovementType.checkCollection;

  /// {@template finance_movement_type_is_note}
  /// Senet detay formu gerekir mi.
  /// {@endtemplate}
  bool get isNote => this == FinanceMovementType.noteCollection;

  /// {@template finance_movement_type_is_credit_card}
  /// Kredi kartı dens alanları gerekir mi.
  /// {@endtemplate}
  bool get isCreditCard => this == FinanceMovementType.creditCardCollection;

  /// {@template finance_movement_type_from_storage}
  /// EN literal / API kodundan tip üretir; bilinmeyen → nakit tahsilat.
  ///
  /// Parametreler:
  /// - [raw]: Cash, credit_card, CashOut, virman, …
  ///
  /// Dönüş değeri:
  /// - [FinanceMovementType]: Eşleşen tip
  /// {@endtemplate}
  static FinanceMovementType fromStorage(String? raw) {
    final v = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
    switch (v) {
      case 'cash':
      case 'nakit':
        return FinanceMovementType.cashCollection;
      case 'credit_card':
      case 'creditcard':
      case 'kk':
      case 'card':
        return FinanceMovementType.creditCardCollection;
      case 'check':
      case 'cheque':
      case 'cek':
      case 'çek':
        return FinanceMovementType.checkCollection;
      case 'note':
      case 'senet':
      case 'promissory':
        return FinanceMovementType.noteCollection;
      case 'cashout':
      case 'cash_out':
      case 'nakit_odeme':
      case 'nakit_ödeme':
        return FinanceMovementType.cashOut;
      case 'creditcardout':
      case 'credit_card_out':
      case 'kk_odeme':
      case 'kk_ödeme':
        return FinanceMovementType.creditCardOut;
      case 'virman':
      case 'transfer':
      case 'safe_transfer':
        return FinanceMovementType.virman;
      default:
        return FinanceMovementType.cashCollection;
    }
  }

  /// {@template finance_movement_type_normalize_api}
  /// Ham değeri API `payment_type` koduna çevirir.
  /// Havale/EFT (`wire`) 7 tip sheet dışında ayrı dens menü kodudur.
  /// {@endtemplate}
  static String normalizeApiCode(String? raw) {
    final v = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
    switch (v) {
      case 'wire':
      case 'eft':
      case 'havale':
      case 'wire_transfer':
      case 'bank_transfer':
        return 'wire';
      default:
        return FinanceMovementType.fromStorage(raw).apiCode;
    }
  }

  /// {@template finance_movement_type_wire_api}
  /// Havale/EFT dens `payment_type` API kodu.
  /// {@endtemplate}
  static const String wireApiCode = 'wire';

  /// {@template finance_movement_type_collection_types}
  /// Sheet / form: 4 tahsilat tipi.
  /// {@endtemplate}
  static const List<FinanceMovementType> collectionTypes = [
    FinanceMovementType.cashCollection,
    FinanceMovementType.creditCardCollection,
    FinanceMovementType.checkCollection,
    FinanceMovementType.noteCollection,
  ];

  /// {@template finance_movement_type_payment_types}
  /// Sheet / form: 2 ödeme tipi.
  /// {@endtemplate}
  static const List<FinanceMovementType> paymentTypes = [
    FinanceMovementType.cashOut,
    FinanceMovementType.creditCardOut,
  ];

  /// {@template finance_movement_type_all_sheet}
  /// Yeni Hareket dens sheet sırası (7 tip).
  /// {@endtemplate}
  static const List<FinanceMovementType> sheetTypes = [
    FinanceMovementType.cashCollection,
    FinanceMovementType.creditCardCollection,
    FinanceMovementType.checkCollection,
    FinanceMovementType.noteCollection,
    FinanceMovementType.cashOut,
    FinanceMovementType.creditCardOut,
    FinanceMovementType.virman,
  ];
}
