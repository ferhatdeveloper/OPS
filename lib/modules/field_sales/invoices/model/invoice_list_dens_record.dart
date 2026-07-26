// Dosya Adı: invoice_list_dens_record.dart
// Açıklama: Fatura listesi dens satırı (SQLite invoices + cari)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../../core/services/logo_payload_mapper.dart';
import '../../shared/view/mbt_sales_purchase_queue_body.dart';

/// {@template invoice_list_dens_record}
/// Fatura listesi dens kaydı — SQLite `invoices` + cari join.
///
/// Kullanım örneği:
/// ```dart
/// final r = InvoiceListDensRecord.fromMap(row);
/// ```
/// {@endtemplate}
class InvoiceListDensRecord {
  /// [id]: Fatura kimliği
  final String id;

  /// [customerId]: Cari id
  final String customerId;

  /// [customerCode]: Cari kodu
  final String customerCode;

  /// [customerName]: Cari ünvan
  final String customerName;

  /// [invoiceDate]: Fatura tarihi
  final DateTime invoiceDate;

  /// [totalAmount]: Genel toplam
  final double totalAmount;

  /// [status]: Yerel durum
  final String status;

  /// [notes]: Not
  final String? notes;

  /// [invoiceType]: Yerel tip anahtarı
  final String? invoiceType;

  /// [isEInvoice]: e-Belge mi
  final bool isEInvoice;

  /// [ettn]: GİB ETTN
  final String? ettn;

  /// [gibStatus]: GİB durum kodu
  final String? gibStatus;

  /// [isSynced]: Senkron bayrağı
  final int isSynced;

  /// [approvalStatus]: Onay durumu (0 bekleyen …)
  final int approvalStatus;

  /// [docSide]: 1-SATIŞ / 2-ALIŞ dens sekmesi
  final MbtQueueDocSide docSide;

  /// {@macro invoice_list_dens_record}
  const InvoiceListDensRecord({
    required this.id,
    required this.customerId,
    required this.customerCode,
    required this.customerName,
    required this.invoiceDate,
    required this.totalAmount,
    required this.status,
    this.notes,
    this.invoiceType,
    this.isEInvoice = true,
    this.ettn,
    this.gibStatus,
    this.isSynced = 0,
    this.approvalStatus = 0,
    required this.docSide,
  });

  /// {@template invoice_list_dens_record_side_from_type}
  /// Yerel `invoice_type` → dens satış/alış sekmesi.
  /// Satın alma → alış; iade/toptan/van → satış.
  /// {@endtemplate}
  static MbtQueueDocSide sideFromInvoiceType(String? invoiceType) {
    final q = LogoPayloadMapper.resolveInvoiceQueueType(invoiceType);
    return q == LogoPayloadMapper.invoiceQueuePurchase
        ? MbtQueueDocSide.purchase
        : MbtQueueDocSide.sales;
  }

  /// {@template invoice_list_dens_record_from_map}
  /// SQLite join satırı → dens kaydı.
  /// {@endtemplate}
  factory InvoiceListDensRecord.fromMap(Map<String, dynamic> map) {
    final type = map['invoice_type']?.toString();
    final dateRaw = map['invoice_date']?.toString();
    final parsed = dateRaw == null || dateRaw.isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : (DateTime.tryParse(dateRaw) ??
            DateTime.fromMillisecondsSinceEpoch(0));
    return InvoiceListDensRecord(
      id: map['id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      customerCode: map['customer_code']?.toString() ?? '',
      customerName: map['customer_name']?.toString() ?? '',
      invoiceDate: parsed,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? '',
      notes: map['notes']?.toString(),
      invoiceType: type,
      isEInvoice: map['is_e_invoice'] == 1 || map['is_e_invoice'] == true,
      ettn: map['ettn']?.toString(),
      gibStatus: map['gib_status']?.toString(),
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
      approvalStatus: (map['approval_status'] as num?)?.toInt() ?? 0,
      docSide: sideFromInvoiceType(type),
    );
  }
}
