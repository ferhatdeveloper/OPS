// Dosya Adı: whms_package_type.dart
// Açıklama: WHMS paket tipi master modeli (code · tare_ref · after_sales)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_package_type}
/// Paket tipi: [code] + opsiyonel dara referansı + satış sonrası bayrağı.
///
/// Kullanım örneği:
/// ```dart
/// const p = WhmsPackageType(id: '1', code: 'KOLI', name: 'Koli');
/// ```
/// {@endtemplate}
class WhmsPackageType {
  /// [id]: PK
  final String id;

  /// [code]: Unique kod
  final String code;

  /// [name]: Görünen ad
  final String name;

  /// [tareRef]: Dara kodu (whms_tares.code)
  final String? tareRef;

  /// [afterSalesFlag]: Satış sonrası paket
  final bool afterSalesFlag;

  /// [isActive]: Aktif
  final bool isActive;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro whms_package_type}
  const WhmsPackageType({
    required this.id,
    required this.code,
    required this.name,
    this.tareRef,
    this.afterSalesFlag = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory WhmsPackageType.fromMap(Map<String, dynamic> map) {
    return WhmsPackageType(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      tareRef: map['tare_ref']?.toString(),
      afterSalesFlag: (map['after_sales_flag'] as num?)?.toInt() == 1,
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
      'tare_ref': tareRef,
      'after_sales_flag': afterSalesFlag ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'ONAY': 0,
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  WhmsPackageType copyWith({
    String? code,
    String? name,
    String? tareRef,
    bool? afterSalesFlag,
    bool? isActive,
    String? updatedAt,
    bool clearTareRef = false,
  }) {
    return WhmsPackageType(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      tareRef: clearTareRef ? null : (tareRef ?? this.tareRef),
      afterSalesFlag: afterSalesFlag ?? this.afterSalesFlag,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
