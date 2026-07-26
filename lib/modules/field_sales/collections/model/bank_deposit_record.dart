// Dosya Adı: bank_deposit_record.dart
// Açıklama: Banka yatırma yerel kayıt modeli (kasa → banka)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template bank_deposit_record}
/// Kasa bakiyesini banka hesabına yatırma fişi (offline-first).
/// Cari (ARP) yoktur — virman benzeri kasa/banka hareketi.
///
/// Kullanım örneği:
/// ```dart
/// final record = BankDepositRecord(
///   id: 'bd-1',
///   cashCode: '100 01 01',
///   bankCode: '102 01 01',
///   amount: 500,
///   depositDate: DateTime.now(),
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
/// {@endtemplate}
class BankDepositRecord {
  /// [id]: Yerel UUID
  final String id;

  /// [cashCode]: Kaynak kasa kodu (Logo safe_code)
  final String cashCode;

  /// [bankCode]: Hedef banka hesap kodu
  final String bankCode;

  /// [amount]: Yatırılan tutar
  final double amount;

  /// [documentNo]: Evrak no
  final String? documentNo;

  /// [depositDate]: Yatırma tarihi
  final DateTime depositDate;

  /// [notes]: Açıklama
  final String? notes;

  /// [onay]: Sync onay (0 bekle / 1 onaylı)
  final int onay;

  /// [isSynced]: Logo aktarıldı mı
  final bool isSynced;

  /// [createdAt]: Oluşturma
  final DateTime createdAt;

  /// [updatedAt]: Güncelleme
  final DateTime updatedAt;

  /// {@macro bank_deposit_record}
  const BankDepositRecord({
    required this.id,
    required this.cashCode,
    required this.bankCode,
    required this.amount,
    this.documentNo,
    required this.depositDate,
    this.notes,
    this.onay = 1,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// [entityType]: JobQueue / sync_queue entity_type
  static const String entityType = 'bank_deposit';

  /// [slipType]: Yerel fiş tipi
  static const String slipType = 'bank_deposit';

  /// [paymentType]: Logo / collections sync tipi (cari flatten yok)
  static const String paymentType = 'bank_deposit';

  /// {@template bank_deposit_record_parse_amount}
  /// TR / EN ondalık metnini double? olarak okur.
  ///
  /// Parametreler:
  /// - [raw]: Tutar metni (örn. `1.250,75` veya `1250.75`)
  ///
  /// Dönüş değeri:
  /// - [double?]: Geçerliyse tutar, aksi halde null
  /// {@endtemplate}
  static double? parseAmount(String? raw) {
    if (raw == null) return null;
    var t = raw.trim();
    if (t.isEmpty) return null;
    if (t.contains(',') && t.contains('.')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (t.contains(',')) {
      t = t.replaceAll(',', '.');
    }
    return double.tryParse(t);
  }

  /// {@template bank_deposit_record_validate_guard}
  /// Kaydet öncesi guard; hata l10n anahtarı veya null.
  ///
  /// Parametreler:
  /// - [cashCode]: Kaynak kasa
  /// - [bankCode]: Hedef banka
  /// - [amount]: Tutar
  ///
  /// Dönüş değeri:
  /// - [String?]: Hata anahtarı veya null (geçerli)
  /// {@endtemplate}
  static String? validateGuard({
    required String cashCode,
    required String bankCode,
    required double? amount,
  }) {
    final cash = cashCode.trim();
    final bank = bankCode.trim();
    if (cash.isEmpty || bank.isEmpty) {
      return 'field_sales.bank_deposit_requires_accounts';
    }
    if (cash == bank) {
      return 'field_sales.bank_deposit_same_account';
    }
    if (amount == null || amount <= 0) {
      return 'field_sales.payment_invalid_amount';
    }
    return null;
  }

  /// {@template bank_deposit_record_from_map}
  /// SQLite satırından üretir.
  /// {@endtemplate}
  factory BankDepositRecord.fromMap(Map<String, dynamic> map) {
    return BankDepositRecord(
      id: map['id']?.toString() ?? '',
      cashCode: map['cash_code']?.toString() ?? '',
      bankCode: map['bank_code']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      documentNo: map['document_no']?.toString(),
      depositDate:
          DateTime.tryParse(map['deposit_date']?.toString() ?? '') ??
              DateTime.now(),
      notes: map['notes']?.toString(),
      onay: (map['ONAY'] as int?) ?? 0,
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// {@template bank_deposit_record_to_map}
  /// SQLite insert map'i.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cash_code': cashCode,
      'bank_code': bankCode,
      'amount': amount,
      'document_no': documentNo,
      'deposit_date': depositDate.toIso8601String(),
      'notes': notes,
      'status': 'saved',
      'ONAY': onay,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// {@template bank_deposit_record_to_queue_payload}
  /// sync_queue payload (Logo aktarım iskeleti — cari yok).
  /// {@endtemplate}
  Map<String, dynamic> toQueuePayload() {
    return {
      'id': id,
      'entity': entityType,
      'type': entityType,
      'slip_type': slipType,
      'payment_type': paymentType,
      'cash_code': cashCode,
      'safe_code': cashCode,
      'CODE': cashCode,
      'bank_code': bankCode,
      'target_safe_code': bankCode,
      'TARGET_CODE': bankCode,
      'amount': amount,
      'document_no': documentNo,
      'deposit_date': depositDate.toIso8601String(),
      'date': depositDate.toIso8601String(),
      'notes': notes,
      'description': notes,
      'ONAY': onay,
    };
  }
}
