// Dosya Adı: whms_label_template.dart
// Açıklama: WHMS etiket şablon stub modeli (printLabel tip eşlemesi)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_label_template}
/// Etiket şablonu — [labelType] `product_small` | `shelf_large`
/// (BluetoothPrintService labelType ile hizalı).
///
/// Kullanım örneği:
/// ```dart
/// const t = WhmsLabelTemplate(
///   id: '1',
///   code: 'URUN50',
///   name: 'Ürün 50x30',
/// );
/// ```
/// {@endtemplate}
class WhmsLabelTemplate {
  /// product_small → BluetoothPrintService varsayılan ürün etiketi
  static const String typeProductSmall = 'product_small';

  /// shelf_large → BluetoothPrintService raf etiketi
  static const String typeShelfLarge = 'shelf_large';

  /// [id]: PK
  final String id;

  /// [code]: Unique kod
  final String code;

  /// [name]: Şablon adı
  final String name;

  /// [labelType]: Yazıcı şablon tipi
  final String labelType;

  /// [sampleProductName]: Önizleme / test baskı adı
  final String? sampleProductName;

  /// [sampleProductCode]: Önizleme kodu
  final String? sampleProductCode;

  /// [samplePrice]: Önizleme fiyat metni
  final String? samplePrice;

  /// [isActive]: Aktif
  final bool isActive;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro whms_label_template}
  const WhmsLabelTemplate({
    required this.id,
    required this.code,
    required this.name,
    this.labelType = typeProductSmall,
    this.sampleProductName,
    this.sampleProductCode,
    this.samplePrice,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// BluetoothPrintService `labelType` parametresi.
  String get printLabelType =>
      labelType == typeShelfLarge ? typeShelfLarge : typeProductSmall;

  factory WhmsLabelTemplate.fromMap(Map<String, dynamic> map) {
    final rawType = map['label_type']?.toString() ?? typeProductSmall;
    return WhmsLabelTemplate(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      labelType: rawType == typeShelfLarge ? typeShelfLarge : typeProductSmall,
      sampleProductName: map['sample_product_name']?.toString(),
      sampleProductCode: map['sample_product_code']?.toString(),
      samplePrice: map['sample_price']?.toString(),
      isActive: (map['is_active'] as num?)?.toInt() != 0,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'label_type': labelType,
      'sample_product_name': sampleProductName,
      'sample_product_code': sampleProductCode,
      'sample_price': samplePrice,
      'is_active': isActive ? 1 : 0,
      'ONAY': 0,
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  WhmsLabelTemplate copyWith({
    String? code,
    String? name,
    String? labelType,
    String? sampleProductName,
    String? sampleProductCode,
    String? samplePrice,
    bool? isActive,
    String? updatedAt,
  }) {
    return WhmsLabelTemplate(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      labelType: labelType ?? this.labelType,
      sampleProductName: sampleProductName ?? this.sampleProductName,
      sampleProductCode: sampleProductCode ?? this.sampleProductCode,
      samplePrice: samplePrice ?? this.samplePrice,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
