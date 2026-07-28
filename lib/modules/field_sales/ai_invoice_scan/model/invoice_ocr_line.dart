// Dosya Adı: invoice_ocr_line.dart
// Açıklama: Fatura OCR satır + katalog eşleme modeli
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template invoice_ocr_line}
/// OCR’dan gelen tek fatura satırı.
/// {@endtemplate}
class InvoiceOcrLine {
  /// [name]: Ürün adı
  final String name;

  /// [sku]: Kod / barkod
  final String sku;

  /// [quantity]: Miktar
  final double quantity;

  /// [unit]: Birim
  final String unit;

  /// [unitPrice]: Birim fiyat
  final double? unitPrice;

  /// [vatRate]: KDV %
  final double vatRate;

  /// [lineTotal]: Satır toplam (KDV hariç tercih)
  final double? lineTotal;

  /// [confidence]: 0–1
  final double confidence;

  /// [manualOverride]: Kullanıcı düzeltti
  final bool manualOverride;

  /// Confidence eşiği
  static const double confidenceThreshold = 0.55;

  /// {@macro invoice_ocr_line}
  const InvoiceOcrLine({
    required this.name,
    this.sku = '',
    this.quantity = 1,
    this.unit = 'ADET',
    this.unitPrice,
    this.vatRate = 20,
    this.lineTotal,
    this.confidence = 0,
    this.manualOverride = false,
  });

  bool get isUncertain =>
      !manualOverride && confidence < confidenceThreshold;

  /// Fatura ekleme için birim fiyat
  double get effectiveUnitPrice {
    if (unitPrice != null && unitPrice! > 0) return unitPrice!;
    if (lineTotal != null && quantity > 0) return lineTotal! / quantity;
    return 0;
  }

  InvoiceOcrLine copyWith({
    String? name,
    String? sku,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? vatRate,
    double? lineTotal,
    double? confidence,
    bool? manualOverride,
  }) {
    return InvoiceOcrLine(
      name: name ?? this.name,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      vatRate: vatRate ?? this.vatRate,
      lineTotal: lineTotal ?? this.lineTotal,
      confidence: confidence ?? this.confidence,
      manualOverride: manualOverride ?? this.manualOverride,
    );
  }

  factory InvoiceOcrLine.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('${v ?? ''}');
    }

    final qty = asDouble(json['quantity']) ?? 1;
    final conf = (asDouble(json['confidence']) ?? 0).clamp(0.0, 1.0);
    final vat = asDouble(json['vat_rate'] ?? json['vatRate']) ?? 20;
    return InvoiceOcrLine(
      name: (json['name'] ?? json['product_name'] ?? '').toString().trim(),
      sku: (json['sku'] ?? json['code'] ?? json['barcode'] ?? '')
          .toString()
          .trim(),
      quantity: qty <= 0 ? 1 : qty,
      unit: (json['unit'] ?? 'ADET').toString().trim().isEmpty
          ? 'ADET'
          : (json['unit'] ?? 'ADET').toString().trim(),
      unitPrice: asDouble(json['unit_price'] ?? json['unitPrice'] ?? json['price']),
      vatRate: vat,
      lineTotal: asDouble(json['line_total'] ?? json['lineTotal'] ?? json['total']),
      confidence: conf,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sku': sku,
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
        'vat_rate': vatRate,
        'line_total': lineTotal,
        'confidence': confidence,
        'manualOverride': manualOverride,
      };
}

/// {@template invoice_ocr_line_match}
/// OCR satırı + products katalog fuzzy eşleme.
/// {@endtemplate}
class InvoiceOcrLineMatch {
  /// [line]
  final InvoiceOcrLine line;

  /// [matchedProductId]
  final String? matchedProductId;

  /// [matchedProductCode]
  final String? matchedProductCode;

  /// [matchedProductName]
  final String? matchedProductName;

  /// [matchScore]
  final double matchScore;

  /// {@macro invoice_ocr_line_match}
  const InvoiceOcrLineMatch({
    required this.line,
    this.matchedProductId,
    this.matchedProductCode,
    this.matchedProductName,
    this.matchScore = 0,
  });

  bool get hasProductMatch =>
      matchedProductId != null && matchedProductId!.trim().isNotEmpty;

  InvoiceOcrLineMatch copyWith({
    InvoiceOcrLine? line,
    String? matchedProductId,
    String? matchedProductCode,
    String? matchedProductName,
    double? matchScore,
  }) {
    return InvoiceOcrLineMatch(
      line: line ?? this.line,
      matchedProductId: matchedProductId ?? this.matchedProductId,
      matchedProductCode: matchedProductCode ?? this.matchedProductCode,
      matchedProductName: matchedProductName ?? this.matchedProductName,
      matchScore: matchScore ?? this.matchScore,
    );
  }
}
