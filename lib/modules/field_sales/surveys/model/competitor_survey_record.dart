// Dosya Adı: competitor_survey_record.dart
// Açıklama: Rakip anket dens form kaydı (minimal persist)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template competitor_survey_record}
/// Yerel rakip anket dens form özeti (SharedPreferences).
///
/// Kullanım örneği:
/// ```dart
/// const r = CompetitorSurveyRecord(
///   brandName: 'Rakip Marka',
///   productName: 'Ürün X',
///   observedPrice: 25.5,
/// );
/// ```
/// {@endtemplate}
class CompetitorSurveyRecord {
  /// [customerCode]: Cari kodu (ziyaret bağlamı)
  final String customerCode;

  /// [brandName]: Rakip marka
  final String brandName;

  /// [productName]: Rakip ürün
  final String productName;

  /// [observedPrice]: Gözlemlenen fiyat
  final double? observedPrice;

  /// [hasStock]: Stokta var mı
  final bool hasStock;

  /// [onPromotion]: Kampanyada mı
  final bool onPromotion;

  /// [notes]: Not
  final String notes;

  /// [updatedAt]: Son kayıt zamanı
  final DateTime? updatedAt;

  /// {@macro competitor_survey_record}
  const CompetitorSurveyRecord({
    this.customerCode = '',
    this.brandName = '',
    this.productName = '',
    this.observedPrice,
    this.hasStock = true,
    this.onPromotion = false,
    this.notes = '',
    this.updatedAt,
  });

  /// {@template competitor_survey_record_from_json}
  /// JSON map'ten kayıt; hatalıysa varsayılan.
  /// {@endtemplate}
  static CompetitorSurveyRecord fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompetitorSurveyRecord();
    final updatedRaw = json['updated_at'] as String?;
    return CompetitorSurveyRecord(
      customerCode: (json['customer_code'] as String?) ?? '',
      brandName: (json['brand_name'] as String?) ?? '',
      productName: (json['product_name'] as String?) ?? '',
      observedPrice: (json['observed_price'] as num?)?.toDouble(),
      hasStock: json['has_stock'] == true || json['has_stock'] == 1,
      onPromotion:
          json['on_promotion'] == true || json['on_promotion'] == 1,
      notes: (json['notes'] as String?) ?? '',
      updatedAt:
          updatedRaw == null ? null : DateTime.tryParse(updatedRaw),
    );
  }

  /// {@template competitor_survey_record_to_json}
  /// SharedPreferences JSON serileştirme.
  /// {@endtemplate}
  Map<String, dynamic> toJson() {
    return {
      'customer_code': customerCode,
      'brand_name': brandName,
      'product_name': productName,
      'observed_price': observedPrice,
      'has_stock': hasStock,
      'on_promotion': onPromotion,
      'notes': notes,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// {@template competitor_survey_record_copy_with}
  /// Alanları güncellenmiş kopya.
  /// {@endtemplate}
  CompetitorSurveyRecord copyWith({
    String? customerCode,
    String? brandName,
    String? productName,
    double? observedPrice,
    bool? hasStock,
    bool? onPromotion,
    String? notes,
    DateTime? updatedAt,
  }) {
    return CompetitorSurveyRecord(
      customerCode: customerCode ?? this.customerCode,
      brandName: brandName ?? this.brandName,
      productName: productName ?? this.productName,
      observedPrice: observedPrice ?? this.observedPrice,
      hasStock: hasStock ?? this.hasStock,
      onPromotion: onPromotion ?? this.onPromotion,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
