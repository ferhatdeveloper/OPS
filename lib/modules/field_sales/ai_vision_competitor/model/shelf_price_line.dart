// Dosya Adı: shelf_price_line.dart
// Açıklama: Vision OCR satırı + katalog karşılaştırma modeli
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template shelf_price_line}
/// Tek fotoğraftan çıkarılan ürün+fiyat satırı.
/// {@endtemplate}
class ShelfPriceLine {
  /// [name]: Ürün adı
  final String name;

  /// [sku]: Opsiyonel SKU / barkod
  final String sku;

  /// [price]: Okunan fiyat
  final double? price;

  /// [currency]: Para birimi
  final String currency;

  /// [confidence]: 0–1
  final double confidence;

  /// [manualOverride]: Kullanıcı düzeltti mi
  final bool manualOverride;

  /// Confidence eşiği — altı şüpheli
  static const double confidenceThreshold = 0.55;

  /// {@macro shelf_price_line}
  const ShelfPriceLine({
    required this.name,
    this.sku = '',
    this.price,
    this.currency = 'TRY',
    this.confidence = 0,
    this.manualOverride = false,
  });

  bool get isUncertain =>
      !manualOverride && confidence < confidenceThreshold;

  ShelfPriceLine copyWith({
    String? name,
    String? sku,
    double? price,
    String? currency,
    double? confidence,
    bool? manualOverride,
  }) {
    return ShelfPriceLine(
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      confidence: confidence ?? this.confidence,
      manualOverride: manualOverride ?? this.manualOverride,
    );
  }

  factory ShelfPriceLine.fromJson(Map<String, dynamic> json) {
    final priceRaw = json['price'];
    double? price;
    if (priceRaw is num) {
      price = priceRaw.toDouble();
    } else {
      price = double.tryParse('${priceRaw ?? ''}');
    }
    final confRaw = json['confidence'];
    double conf = 0;
    if (confRaw is num) {
      conf = confRaw.toDouble();
    } else {
      conf = double.tryParse('${confRaw ?? ''}') ?? 0;
    }
    return ShelfPriceLine(
      name: (json['name'] ?? '').toString().trim(),
      sku: (json['sku'] ?? json['code'] ?? json['barcode'] ?? '')
          .toString()
          .trim(),
      price: price,
      currency: (json['currency'] ?? 'TRY').toString().trim().isEmpty
          ? 'TRY'
          : (json['currency'] ?? 'TRY').toString().trim(),
      confidence: conf.clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sku': sku,
        'price': price,
        'currency': currency,
        'confidence': confidence,
        'manualOverride': manualOverride,
      };
}

/// {@template shelf_price_comparison}
/// Rakip fiyat vs kendi fiyat.
/// {@endtemplate}
class ShelfPriceComparison {
  /// [line]: Vision satırı
  final ShelfPriceLine line;

  /// [matchedProductId]
  final String? matchedProductId;

  /// [matchedProductCode]
  final String? matchedProductCode;

  /// [matchedProductName]
  final String? matchedProductName;

  /// [ourPrice]
  final double? ourPrice;

  /// [matchScore]
  final double matchScore;

  /// {@macro shelf_price_comparison}
  const ShelfPriceComparison({
    required this.line,
    this.matchedProductId,
    this.matchedProductCode,
    this.matchedProductName,
    this.ourPrice,
    this.matchScore = 0,
  });

  /// Fark % (rakip − bizim) / bizim * 100
  double? get priceDiffPercent {
    final theirs = line.price;
    final ours = ourPrice;
    if (theirs == null || ours == null || ours == 0) return null;
    return ((theirs - ours) / ours) * 100.0;
  }
}
