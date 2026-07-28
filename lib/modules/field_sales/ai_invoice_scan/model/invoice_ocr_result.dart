// Dosya Adı: invoice_ocr_result.dart
// Açıklama: Fatura OCR başlık + satır sonuç modeli
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'invoice_ocr_line.dart';

/// {@template invoice_ocr_draft}
/// OCR’dan parse edilen fatura taslağı (onay öncesi).
/// {@endtemplate}
class InvoiceOcrDraft {
  /// [partyName]: Cari ünvan
  final String partyName;

  /// [partyCode]: Cari kod
  final String partyCode;

  /// [documentNo]: Belge no
  final String documentNo;

  /// [documentDate]: YYYY-MM-DD veya boş
  final String documentDate;

  /// [currency]
  final String currency;

  /// [confidence]: Başlık güveni
  final double confidence;

  /// [lines]: Satırlar
  final List<InvoiceOcrLine> lines;

  /// {@macro invoice_ocr_draft}
  const InvoiceOcrDraft({
    this.partyName = '',
    this.partyCode = '',
    this.documentNo = '',
    this.documentDate = '',
    this.currency = 'TRY',
    this.confidence = 0,
    this.lines = const [],
  });

  bool get hasContent =>
      lines.isNotEmpty ||
      partyName.trim().isNotEmpty ||
      documentNo.trim().isNotEmpty;

  InvoiceOcrDraft copyWith({
    String? partyName,
    String? partyCode,
    String? documentNo,
    String? documentDate,
    String? currency,
    double? confidence,
    List<InvoiceOcrLine>? lines,
  }) {
    return InvoiceOcrDraft(
      partyName: partyName ?? this.partyName,
      partyCode: partyCode ?? this.partyCode,
      documentNo: documentNo ?? this.documentNo,
      documentDate: documentDate ?? this.documentDate,
      currency: currency ?? this.currency,
      confidence: confidence ?? this.confidence,
      lines: lines ?? this.lines,
    );
  }

  factory InvoiceOcrDraft.fromJson(Map<String, dynamic> json) {
    double conf = 0;
    final confRaw = json['confidence'];
    if (confRaw is num) {
      conf = confRaw.toDouble();
    } else {
      conf = double.tryParse('${confRaw ?? ''}') ?? 0;
    }
    final rawLines = json['lines'];
    final lines = <InvoiceOcrLine>[];
    if (rawLines is List) {
      for (final e in rawLines) {
        if (e is! Map) continue;
        final line = InvoiceOcrLine.fromJson(Map<String, dynamic>.from(e));
        if (line.name.isEmpty) continue;
        lines.add(line);
      }
    }
    return InvoiceOcrDraft(
      partyName: (json['party_name'] ?? json['partyName'] ?? json['customer'] ?? '')
          .toString()
          .trim(),
      partyCode:
          (json['party_code'] ?? json['partyCode'] ?? json['customer_code'] ?? '')
              .toString()
              .trim(),
      documentNo:
          (json['document_no'] ?? json['documentNo'] ?? json['invoice_no'] ?? '')
              .toString()
              .trim(),
      documentDate:
          (json['document_date'] ?? json['documentDate'] ?? json['date'] ?? '')
              .toString()
              .trim(),
      currency: (json['currency'] ?? 'TRY').toString().trim().isEmpty
          ? 'TRY'
          : (json['currency'] ?? 'TRY').toString().trim(),
      confidence: conf.clamp(0.0, 1.0),
      lines: lines,
    );
  }

  Map<String, dynamic> toJson() => {
        'party_name': partyName,
        'party_code': partyCode,
        'document_no': documentNo,
        'document_date': documentDate,
        'currency': currency,
        'confidence': confidence,
        'lines': lines.map((e) => e.toJson()).toList(),
      };
}

/// {@template invoice_ocr_customer_match}
/// Cari fuzzy eşleme sonucu.
/// {@endtemplate}
class InvoiceOcrCustomerMatch {
  /// [customerId]
  final String? customerId;

  /// [customerCode]
  final String? customerCode;

  /// [customerName]
  final String? customerName;

  /// [score]
  final double score;

  /// {@macro invoice_ocr_customer_match}
  const InvoiceOcrCustomerMatch({
    this.customerId,
    this.customerCode,
    this.customerName,
    this.score = 0,
  });

  bool get hasMatch =>
      customerId != null && customerId!.trim().isNotEmpty;
}
