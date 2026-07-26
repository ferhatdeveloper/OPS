// Dosya Adı: shelf_audit_record.dart
// Açıklama: Raf denetimi dens form kaydı (minimal persist)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template shelf_audit_record}
/// Yerel raf denetimi dens form özeti (SharedPreferences).
///
/// Kullanım örneği:
/// ```dart
/// const r = ShelfAuditRecord(
///   customerCode: 'C001',
///   brandName: 'Marka A',
///   facings: 4,
/// );
/// ```
/// {@endtemplate}
class ShelfAuditRecord {
  /// [customerCode]: Cari kodu
  final String customerCode;

  /// [customerName]: Cari ünvan
  final String customerName;

  /// [category]: Raf / kategori
  final String category;

  /// [brandName]: Marka / ürün
  final String brandName;

  /// [facings]: Facing adedi
  final int facings;

  /// [shelfSharePct]: Raf payı (%)
  final double shelfSharePct;

  /// [hasStock]: Rafta stok var mı
  final bool hasStock;

  /// [notes]: Not
  final String notes;

  /// [updatedAt]: Son kayıt zamanı
  final DateTime? updatedAt;

  /// {@macro shelf_audit_record}
  const ShelfAuditRecord({
    this.customerCode = '',
    this.customerName = '',
    this.category = '',
    this.brandName = '',
    this.facings = 0,
    this.shelfSharePct = 0,
    this.hasStock = true,
    this.notes = '',
    this.updatedAt,
  });

  /// {@template shelf_audit_record_from_json}
  /// JSON map'ten kayıt; hatalıysa varsayılan.
  /// {@endtemplate}
  static ShelfAuditRecord fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ShelfAuditRecord();
    final updatedRaw = json['updated_at'] as String?;
    return ShelfAuditRecord(
      customerCode: (json['customer_code'] as String?) ?? '',
      customerName: (json['customer_name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      brandName: (json['brand_name'] as String?) ?? '',
      facings: (json['facings'] as num?)?.toInt() ?? 0,
      shelfSharePct: (json['shelf_share_pct'] as num?)?.toDouble() ?? 0,
      hasStock: json['has_stock'] == true || json['has_stock'] == 1,
      notes: (json['notes'] as String?) ?? '',
      updatedAt:
          updatedRaw == null ? null : DateTime.tryParse(updatedRaw),
    );
  }

  /// {@template shelf_audit_record_to_json}
  /// SharedPreferences JSON serileştirme.
  /// {@endtemplate}
  Map<String, dynamic> toJson() {
    return {
      'customer_code': customerCode,
      'customer_name': customerName,
      'category': category,
      'brand_name': brandName,
      'facings': facings,
      'shelf_share_pct': shelfSharePct,
      'has_stock': hasStock,
      'notes': notes,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// {@template shelf_audit_record_copy_with}
  /// Alanları güncellenmiş kopya.
  /// {@endtemplate}
  ShelfAuditRecord copyWith({
    String? customerCode,
    String? customerName,
    String? category,
    String? brandName,
    int? facings,
    double? shelfSharePct,
    bool? hasStock,
    String? notes,
    DateTime? updatedAt,
  }) {
    return ShelfAuditRecord(
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      category: category ?? this.category,
      brandName: brandName ?? this.brandName,
      facings: facings ?? this.facings,
      shelfSharePct: shelfSharePct ?? this.shelfSharePct,
      hasStock: hasStock ?? this.hasStock,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
