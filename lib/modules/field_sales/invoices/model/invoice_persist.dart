// Dosya Adı: invoice_persist.dart
// Açıklama: Fatura SQLite satırı + e-Fatura dens + Logo kuyruk payload
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:uuid/uuid.dart';

import '../../../../core/services/logo_payload_mapper.dart';
import '../../../../core/sync/outbound_idempotency.dart';
import 'einvoice_gib_status.dart';
import 'einvoice_status_record.dart';
import 'invoice_model.dart';

/// {@template InvoicePersist}
/// Satın alma / toptan / iade fatura kaydı için SQLite + dens + queue
/// yardımcıları. Yerel `invoice_type` korunur; purchase → TYPE 3/8 flatten yok.
/// e-Fatura kaydında `ettn` / `gib_status` hem `invoices` hem
/// `einvoice_status` tablolarına yazılır.
/// {@endtemplate}
class InvoicePersist {
  InvoicePersist._();

  /// {@template InvoicePersist_prepareForPersist}
  /// Kayıt öncesi ETTN / GİB alanlarını doldurur.
  ///
  /// Kurallar:
  /// - e-Fatura: boş ETTN → UUID; boş gib → [EinvoiceGibStatus.queued]
  /// - Kağıt: ettn / gib_status temizlenir
  ///
  /// Parametreler:
  /// - [invoice]: Taslak fatura
  ///
  /// Dönüş değeri:
  /// - [InvoiceModel]: Persist için zenginleştirilmiş kopya
  /// {@endtemplate}
  static InvoiceModel prepareForPersist(InvoiceModel invoice) {
    if (!invoice.isEInvoice) {
      // copyWith null'ı "koru" saydığı için kağıt faturayı yeniden kur
      return InvoiceModel(
        id: invoice.id,
        customerId: invoice.customerId,
        invoiceDate: invoice.invoiceDate,
        totalAmount: invoice.totalAmount,
        status: invoice.status,
        notes: invoice.notes,
        invoiceType: invoice.invoiceType,
        isEInvoice: false,
        ettn: null,
        gibStatus: null,
        isSynced: invoice.isSynced,
      );
    }

    final existingEttn = invoice.ettn?.trim() ?? '';
    final ettn =
        existingEttn.isNotEmpty ? existingEttn : const Uuid().v4();

    final existingGib = invoice.gibStatus?.trim() ?? '';
    final gib = existingGib.isNotEmpty
        ? existingGib.toUpperCase()
        : EinvoiceGibStatus.queued.code;

    return invoice.copyWith(ettn: ettn, gibStatus: gib);
  }

  /// {@template buildInvoiceSqliteRow}
  /// SQLite `invoices` satırı — yerel `invoice_type` + ettn/gib korunur.
  ///
  /// Parametreler:
  /// - [invoice]: Kaydedilecek fatura modeli (tercihen [prepareForPersist])
  /// - [nowIso]: created_at / updated_at ISO zamanı
  ///
  /// Dönüş değeri:
  /// - [Map]: insert için satır map'i (`approval_status=1`)
  /// {@endtemplate}
  static Map<String, dynamic> buildInvoiceSqliteRow(
    InvoiceModel invoice, {
    required String nowIso,
  }) {
    final prepared = prepareForPersist(invoice);
    final row = prepared.toMap();
    // Yerel tip (örn. field_sales.purchase_invoice) olduğu gibi kalır
    row['invoice_type'] = prepared.invoiceType;
    row['approval_status'] = 1;
    row['created_at'] = nowIso;
    row['updated_at'] = nowIso;
    return row;
  }

  /// {@template InvoicePersist_buildEinvoiceStatusRecord}
  /// e-Fatura dens (`einvoice_status`) satırı — invoices ile aynı ETTN/GİB.
  ///
  /// Parametreler:
  /// - [invoice]: Persist için hazır fatura ([prepareForPersist] önerilir)
  /// - [nowIso]: created_at / updated_at
  /// - [densId]: Opsiyonel dens birincil anahtar
  /// - [customerCode]: Cari kodu
  /// - [customerName]: Cari ünvan
  ///
  /// Dönüş değeri:
  /// - [EinvoiceStatusRecord]: dens satırı; kağıt faturada `null`
  /// {@endtemplate}
  static EinvoiceStatusRecord? buildEinvoiceStatusRecord(
    InvoiceModel invoice, {
    required String nowIso,
    String? densId,
    String? customerCode,
    String? customerName,
  }) {
    final prepared = prepareForPersist(invoice);
    if (!prepared.isEInvoice) return null;

    final ettn = prepared.ettn?.trim() ?? '';
    if (ettn.isEmpty) return null;

    final queueType =
        LogoPayloadMapper.resolveInvoiceQueueType(prepared.invoiceType);
    final docSide = queueType == LogoPayloadMapper.invoiceQueuePurchase
        ? EinvoiceDocSide.purchase
        : EinvoiceDocSide.sales;
    final opsId = OutboundIdempotency.opsDocId(prepared.id);
    final number = OutboundIdempotency.ficheNumber('invoice', opsId);

    final now = DateTime.tryParse(nowIso);
    return EinvoiceStatusRecord(
      id: densId ?? const Uuid().v4(),
      invoiceId: prepared.id,
      documentNo: number,
      ettn: ettn,
      gibStatus: EinvoiceGibStatus.fromCode(prepared.gibStatus),
      docSide: docSide,
      profile: 'e_fatura',
      customerId: prepared.customerId,
      customerCode: customerCode,
      customerName: customerName,
      documentDate: prepared.invoiceDate,
      amount: prepared.totalAmount,
      approvalStatus: 0,
      isSynced: 0,
      isDeleted: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// {@template buildInvoiceQueuePayload}
  /// Logo job queue fatura payload'ı — tip koruyarak.
  ///
  /// Kurallar:
  /// - `type`: kuyruk kanalı (purchase|return|wholesale|retail)
  /// - `invoice_type`: **yerel** tip anahtarı (flatten yok)
  /// - purchase → logo_type/TRCODE **1** (≠ 3 iade, ≠ 8 toptan)
  ///
  /// Parametreler:
  /// - [invoice]: Kaydedilen fatura
  /// - [customerCode]: ARP / cari kodu
  /// - [lines]: Kalem satırları
  ///
  /// Dönüş değeri:
  /// - [Map]: `JobQueueService.enqueue` payload
  /// {@endtemplate}
  static Map<String, dynamic> buildInvoiceQueuePayload({
    required InvoiceModel invoice,
    required String customerCode,
    required List<Map<String, dynamic>> lines,
  }) {
    final localType = invoice.invoiceType;
    final queueType =
        LogoPayloadMapper.resolveInvoiceQueueType(localType);
    final logoType =
        LogoPayloadMapper.resolveInvoiceLogoType(localType);
    final opsId = OutboundIdempotency.opsDocId(invoice.id);
    final number = OutboundIdempotency.ficheNumber('invoice', opsId);
    return {
      ...invoice.toMap(),
      // Ortak id: invoices.id = ops_doc_id = client_doc_id (aynı UUID)
      'ops_doc_id': opsId,
      'client_doc_id': opsId,
      'NUMBER': number,
      'number': number,
      'document_no': number,
      'customer_code': customerCode,
      'arp_code': customerCode,
      'type': queueType,
      // Yerel tip korunur — queueType'a ezilmez
      'invoice_type': localType,
      if (logoType != null) 'logo_type': logoType,
      if (logoType != null) 'TRCODE': logoType,
      'lines': lines,
    };
  }
}
