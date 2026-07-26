// Dosya Adı: einvoice_status_record.dart
// Açıklama: e-Fatura durum dens satırı (ETTN + GİB durum) model
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'einvoice_gib_status.dart';

/// {@template EinvoiceDocSide}
/// Dens kuyruk yönü: satış / alış.
/// {@endtemplate}
enum EinvoiceDocSide {
  /// 1-SATIŞ
  sales,

  /// 2-ALIŞ
  purchase;

  /// SQLite kodu
  String get code => this == EinvoiceDocSide.purchase ? 'purchase' : 'sales';

  /// Kod → enum
  static EinvoiceDocSide fromCode(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'purchase' || v == 'alis' || v == 'alış') {
      return EinvoiceDocSide.purchase;
    }
    return EinvoiceDocSide.sales;
  }
}

/// {@template einvoice_status_record}
/// e-Fatura durum dens satırı — ETTN (UUID) + GİB durum alanları.
///
/// Kullanım örneği:
/// ```dart
/// final row = EinvoiceStatusRecord(
///   id: 'eis-1',
///   documentNo: 'EF20260001',
///   ettn: '11111111-1111-1111-1111-111111111111',
///   gibStatus: EinvoiceGibStatus.sent,
/// );
/// ```
/// {@endtemplate}
class EinvoiceStatusRecord {
  /// [id]: Yerel birincil anahtar
  final String id;

  /// [invoiceId]: İsteğe bağlı fatura id bağı
  final String? invoiceId;

  /// [documentNo]: Fiş / e-belge no
  final String documentNo;

  /// [ettn]: GİB ETTN (UBL UUID)
  final String ettn;

  /// [gibStatus]: GİB yaşam döngüsü durumu
  final EinvoiceGibStatus gibStatus;

  /// [docSide]: Satış / alış dens sekmesi
  final EinvoiceDocSide docSide;

  /// [profile]: `e_fatura` | `e_arsiv`
  final String profile;

  /// [customerId]: Cari id
  final String? customerId;

  /// [customerCode]: Cari kodu
  final String? customerCode;

  /// [customerName]: Cari ünvan
  final String? customerName;

  /// [documentDate]: Belge tarihi
  final DateTime? documentDate;

  /// [amount]: Tutar
  final double amount;

  /// [statusMessage]: GİB / entegratör mesajı
  final String? statusMessage;

  /// [approvalStatus]: ONAY (0 bekliyor …)
  final int approvalStatus;

  /// [isSynced]: Senkron bayrağı
  final int isSynced;

  /// [isDeleted]: Soft delete
  final int isDeleted;

  /// [createdAt]: Oluşturma
  final DateTime? createdAt;

  /// [updatedAt]: Güncelleme
  final DateTime? updatedAt;

  /// {@macro einvoice_status_record}
  const EinvoiceStatusRecord({
    required this.id,
    this.invoiceId,
    required this.documentNo,
    required this.ettn,
    this.gibStatus = EinvoiceGibStatus.draft,
    this.docSide = EinvoiceDocSide.sales,
    this.profile = 'e_fatura',
    this.customerId,
    this.customerCode,
    this.customerName,
    this.documentDate,
    this.amount = 0,
    this.statusMessage,
    this.approvalStatus = 0,
    this.isSynced = 0,
    this.isDeleted = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// {@template einvoice_status_record_gib_status_code}
  /// SQLite `gib_status` kolon değeri.
  /// {@endtemplate}
  String get gibStatusCode => gibStatus.code;

  /// {@template einvoice_status_record_to_map}
  /// SQLite satır map’i.
  ///
  /// Dönüş değeri:
  /// - [Map]: Kolon → değer
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'document_no': documentNo,
      'ettn': ettn,
      'gib_status': gibStatus.code,
      'doc_side': docSide.code,
      'profile': profile,
      'customer_id': customerId,
      'customer_code': customerCode,
      'customer_name': customerName,
      'document_date': documentDate?.toIso8601String(),
      'amount': amount,
      'status_message': statusMessage,
      'ONAY': approvalStatus,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// {@template einvoice_status_record_from_map}
  /// SQLite / stub map → model.
  ///
  /// Parametreler:
  /// - [map]: Kolon map’i
  ///
  /// Dönüş değeri:
  /// - [EinvoiceStatusRecord]: Dens satırı
  /// {@endtemplate}
  factory EinvoiceStatusRecord.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      final s = v.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return EinvoiceStatusRecord(
      id: map['id']?.toString() ?? '',
      invoiceId: map['invoice_id']?.toString(),
      documentNo: map['document_no']?.toString() ?? '',
      ettn: map['ettn']?.toString() ?? '',
      gibStatus: EinvoiceGibStatus.fromCode(map['gib_status']?.toString()),
      docSide: EinvoiceDocSide.fromCode(map['doc_side']?.toString()),
      profile: map['profile']?.toString() ?? 'e_fatura',
      customerId: map['customer_id']?.toString(),
      customerCode: map['customer_code']?.toString(),
      customerName: map['customer_name']?.toString(),
      documentDate: parseDate(map['document_date']),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      statusMessage: map['status_message']?.toString(),
      approvalStatus: (map['ONAY'] as num?)?.toInt() ??
          (map['approval_status'] as num?)?.toInt() ??
          0,
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      isDeleted: (map['is_deleted'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  /// {@template einvoice_status_record_copy_with}
  /// İmmutable kopya.
  /// {@endtemplate}
  EinvoiceStatusRecord copyWith({
    String? id,
    String? invoiceId,
    String? documentNo,
    String? ettn,
    EinvoiceGibStatus? gibStatus,
    EinvoiceDocSide? docSide,
    String? profile,
    String? customerId,
    String? customerCode,
    String? customerName,
    DateTime? documentDate,
    double? amount,
    String? statusMessage,
    int? approvalStatus,
    int? isSynced,
    int? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EinvoiceStatusRecord(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      documentNo: documentNo ?? this.documentNo,
      ettn: ettn ?? this.ettn,
      gibStatus: gibStatus ?? this.gibStatus,
      docSide: docSide ?? this.docSide,
      profile: profile ?? this.profile,
      customerId: customerId ?? this.customerId,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      documentDate: documentDate ?? this.documentDate,
      amount: amount ?? this.amount,
      statusMessage: statusMessage ?? this.statusMessage,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
