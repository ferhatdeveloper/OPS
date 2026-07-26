// Dosya Adı: collection_untransferred_record.dart
// Açıklama: Transfer edilmeyen tahsilat dens satır modeli
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'collection_model.dart';
import 'finance_movement_type.dart';

/// {@template CollectionUntransferredDocSide}
/// Dens kuyruk yönü: satış (tahsilat) / alış (ödeme).
/// {@endtemplate}
enum CollectionUntransferredDocSide {
  /// 1-SATIŞ (tahsilat)
  sales,

  /// 2-ALIŞ (ödeme)
  purchase;

  /// SQLite / seed kodu
  String get code =>
      this == CollectionUntransferredDocSide.purchase ? 'purchase' : 'sales';

  /// Kod → enum
  static CollectionUntransferredDocSide fromCode(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'purchase' || v == 'alis' || v == 'alış') {
      return CollectionUntransferredDocSide.purchase;
    }
    return CollectionUntransferredDocSide.sales;
  }

  /// {@template CollectionUntransferredDocSide_from_payment}
  /// Ödeme tipinden dens sekme yönü (ödeme → alış, diğer → satış).
  /// {@endtemplate}
  static CollectionUntransferredDocSide fromPaymentType(String? paymentType) {
    final kind = FinanceMovementType.fromStorage(paymentType).kind;
    return kind == FinanceMovementKind.payment
        ? CollectionUntransferredDocSide.purchase
        : CollectionUntransferredDocSide.sales;
  }
}

/// {@template collection_untransferred_record}
/// Transfer edilmeyen tahsilat dens satırı (kuyruk bağlama).
///
/// Kullanım örneği:
/// ```dart
/// final r = CollectionUntransferredRecord(
///   id: 'cu-1',
///   documentNo: 'TH-001',
///   customerCode: 'C001',
///   customerName: 'Demo',
///   amount: 100,
///   paymentType: 'Cash',
///   collectionDate: DateTime.now(),
/// );
/// ```
/// {@endtemplate}
class CollectionUntransferredRecord {
  /// [id]: Yerel kayıt kimliği
  final String id;

  /// [documentNo]: Evrak / fiş no
  final String documentNo;

  /// [customerCode]: Cari kodu
  final String customerCode;

  /// [customerName]: Cari ünvan
  final String customerName;

  /// [amount]: Tutar
  final double amount;

  /// [paymentType]: Ödeme tipi (Cash, Check, …)
  final String paymentType;

  /// [collectionDate]: Tahsilat tarihi
  final DateTime collectionDate;

  /// [docSide]: 1-SATIŞ / 2-ALIŞ
  final CollectionUntransferredDocSide docSide;

  /// [cashCode]: Kasa kodu
  final String? cashCode;

  /// [currencyCode]: Döviz
  final String currencyCode;

  /// [notes]: Not
  final String? notes;

  /// [isSynced]: Senkron bayrağı (untransferred → false)
  final bool isSynced;

  /// {@macro collection_untransferred_record}
  const CollectionUntransferredRecord({
    required this.id,
    required this.documentNo,
    required this.customerCode,
    required this.customerName,
    required this.amount,
    required this.paymentType,
    required this.collectionDate,
    this.docSide = CollectionUntransferredDocSide.sales,
    this.cashCode,
    this.currencyCode = 'TRY',
    this.notes,
    this.isSynced = false,
  });

  /// {@template collection_untransferred_record_from_collection}
  /// [CollectionModel] + cari görünen adlardan dens kayıt üretir.
  ///
  /// Parametreler:
  /// - [model]: Yerel tahsilat
  /// - [customerCode]: Cari kodu
  /// - [customerName]: Cari ünvan
  ///
  /// Dönüş değeri:
  /// - [CollectionUntransferredRecord]: Dens satır
  /// {@endtemplate}
  factory CollectionUntransferredRecord.fromCollection(
    CollectionModel model, {
    String customerCode = '',
    String customerName = '',
  }) {
    return CollectionUntransferredRecord(
      id: model.id,
      documentNo: (model.documentNo ?? '').trim().isEmpty
          ? model.id
          : model.documentNo!.trim(),
      customerCode: customerCode.trim().isEmpty
          ? model.customerId
          : customerCode.trim(),
      customerName: customerName,
      amount: model.amount,
      paymentType: model.paymentType,
      collectionDate: model.collectionDate,
      docSide: CollectionUntransferredDocSide.fromPaymentType(
        model.paymentType,
      ),
      cashCode: model.cashCode,
      currencyCode: (model.currencyCode ?? 'TRY').trim().isEmpty
          ? 'TRY'
          : model.currencyCode!.trim(),
      notes: model.notes,
      isSynced: model.isSynced,
    );
  }

  /// {@template collection_untransferred_record_from_map}
  /// SQLite / seed map → dens kayıt.
  /// {@endtemplate}
  factory CollectionUntransferredRecord.fromMap(Map<String, dynamic> map) {
    final dateRaw = map['collection_date'] as String?;
    final date = dateRaw == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : (DateTime.tryParse(dateRaw) ??
            DateTime.fromMillisecondsSinceEpoch(0));
    final payment = (map['payment_type'] as String?) ?? 'Cash';
    final sideRaw = map['doc_side'] as String?;
    return CollectionUntransferredRecord(
      id: (map['id'] as String?) ?? '',
      documentNo: (map['document_no'] as String?) ?? '',
      customerCode: (map['customer_code'] as String?) ??
          (map['customer_id'] as String?) ??
          '',
      customerName: (map['customer_name'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentType: payment,
      collectionDate: date,
      docSide: sideRaw != null
          ? CollectionUntransferredDocSide.fromCode(sideRaw)
          : CollectionUntransferredDocSide.fromPaymentType(payment),
      cashCode: map['cash_code'] as String?,
      currencyCode: (map['currency_code'] as String?) ?? 'TRY',
      notes: map['notes'] as String?,
      isSynced: (map['is_synced'] as int?) == 1 ||
          (map['is_synced'] as bool?) == true,
    );
  }

  /// {@template collection_untransferred_record_to_map}
  /// SQLite insert için map.
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_no': documentNo,
      'customer_code': customerCode,
      'customer_name': customerName,
      'amount': amount,
      'payment_type': paymentType,
      'collection_date': collectionDate.toIso8601String(),
      'doc_side': docSide.code,
      'cash_code': cashCode,
      'currency_code': currencyCode,
      'notes': notes,
      'is_synced': isSynced ? 1 : 0,
    };
  }
}
