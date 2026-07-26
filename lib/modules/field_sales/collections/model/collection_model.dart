// Dosya Adı: collection_model.dart
// Açıklama: Tahsilat kaydı modeli (nakit MBT alanları dahil)
// Oluşturulma Tarihi: 2024-01-01
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template collection_model}
/// Yerel tahsilat kaydı (Cash / CreditCard / Check / Note).
///
/// Kullanım örneği:
/// ```dart
/// CollectionModel(
///   id: '1',
///   customerId: 'C001',
///   amount: 100,
///   paymentType: 'Cash',
///   collectionDate: DateTime.now(),
///   cashCode: '01',
/// );
/// ```
/// {@endtemplate}
class CollectionModel {
  /// [id]: Kayıt kimliği
  final String id;

  /// [customerId]: Cari kimliği
  final String customerId;

  /// [amount]: Tutar
  final double amount;

  /// [paymentType]: Ödeme tipi ('Cash', 'CreditCard', 'Check', 'Note')
  final String paymentType;

  /// [collectionDate]: Tahsilat tarihi
  final DateTime collectionDate;

  /// [notes]: Açıklama / not
  final String? notes;

  /// [bankName]: Çek/senet banka adı
  final String? bankName;

  /// [branchName]: Çek şube adı
  final String? branchName;

  /// [checkNumber]: Çek/senet numarası
  final String? checkNumber;

  /// [dueDate]: Vade tarihi
  final DateTime? dueDate;

  /// [cashCode]: Kasa kodu (MBT KASA KODU / Logo safe_code)
  final String? cashCode;

  /// [targetCashCode]: Virman hedef kasa kodu
  final String? targetCashCode;

  /// [documentNo]: Evrak no (MBT EVRAK NO)
  final String? documentNo;

  /// [currencyCode]: İşlem dövizi
  final String? currencyCode;

  /// [salespersonCode]: Plasiyer kodu
  final String? salespersonCode;

  /// [specialCode1]: Özelkod 1
  final String? specialCode1;

  /// [endorsement]: Ciro (çek)
  final String? endorsement;

  /// [originalDebtor]: Asıl borçlu (çek)
  final String? originalDebtor;

  /// [workplace]: İşyeri (çek)
  final String? workplace;

  /// [accountNumber]: Hesap no (çek)
  final String? accountNumber;

  /// [checkStatus]: Çek dens durum kodu (check_status)
  final String? checkStatus;

  /// [isSynced]: Senkron durumu
  final bool isSynced;

  /// [createdAt]: Oluşturulma zamanı
  final DateTime? createdAt;

  /// {@macro collection_model}
  CollectionModel({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.paymentType,
    required this.collectionDate,
    this.notes,
    this.bankName,
    this.branchName,
    this.checkNumber,
    this.dueDate,
    this.cashCode,
    this.targetCashCode,
    this.documentNo,
    this.currencyCode,
    this.salespersonCode,
    this.specialCode1,
    this.endorsement,
    this.originalDebtor,
    this.workplace,
    this.accountNumber,
    this.checkStatus,
    this.isSynced = false,
    this.createdAt,
  });

  /// {@template collection_model_from_map}
  /// SQLite satırından model üretir.
  /// {@endtemplate}
  factory CollectionModel.fromMap(Map<String, dynamic> map) {
    return CollectionModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentType: map['payment_type'] as String,
      collectionDate: DateTime.parse(map['collection_date'] as String),
      notes: map['notes'] as String?,
      bankName: map['bank_name'] as String?,
      branchName: map['branch_name'] as String?,
      checkNumber: map['check_number'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      cashCode: map['cash_code'] as String?,
      targetCashCode: map['target_cash_code'] as String?,
      documentNo: map['document_no'] as String?,
      currencyCode: map['currency_code'] as String?,
      salespersonCode: map['salesperson_code'] as String?,
      specialCode1: map['special_code_1'] as String?,
      endorsement: map['endorsement'] as String?,
      originalDebtor: map['original_debtor'] as String?,
      workplace: map['workplace'] as String?,
      accountNumber: map['account_number'] as String?,
      checkStatus: map['check_status'] as String?,
      isSynced: (map['is_synced'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// {@template collection_model_to_map}
  /// SQLite insert/update haritası.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'payment_type': paymentType,
      'collection_date': collectionDate.toIso8601String(),
      'notes': notes,
      'bank_name': bankName,
      'branch_name': branchName,
      'check_number': checkNumber,
      'due_date': dueDate?.toIso8601String(),
      'cash_code': cashCode,
      'target_cash_code': targetCashCode,
      'document_no': documentNo,
      'currency_code': currencyCode,
      'salesperson_code': salespersonCode,
      'special_code_1': specialCode1,
      'endorsement': endorsement,
      'original_debtor': originalDebtor,
      'workplace': workplace,
      'account_number': accountNumber,
      'check_status': checkStatus,
      'is_synced': isSynced ? 1 : 0,
      'created_at':
          createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }
}
