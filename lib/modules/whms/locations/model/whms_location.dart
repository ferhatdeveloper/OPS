// Dosya Adı: whms_location.dart
// Açıklama: WHMS lokasyon master modeli (ambar · kod · koridor/raf/göz)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_location}
/// Ambar altı adres: [code] + opsiyonel koridor (aisle) · raf · göz.
///
/// Kullanım örneği:
/// ```dart
/// final loc = WhmsLocation(
///   id: 'loc1',
///   warehouseCode: 'MRK',
///   code: 'A-01-02',
///   aisle: 'A',
///   rack: '01',
///   bin: '02',
/// );
/// print(loc.addressLabel); // A-01-02
/// ```
/// {@endtemplate}
class WhmsLocation {
  /// [id]: Birincil anahtar
  final String id;

  /// [warehouseCode]: Ambar kodu (MRK / ARC / …)
  final String warehouseCode;

  /// [code]: Lokasyon kodu (UNIQUE with warehouse)
  final String code;

  /// [aisle]: Koridor (opsiyonel)
  final String aisle;

  /// [rack]: Raf (opsiyonel)
  final String rack;

  /// [bin]: Göz (opsiyonel)
  final String bin;

  /// [barcode]: Lokasyon barkodu (opsiyonel)
  final String barcode;

  /// [routeSeq]: Toplama rota sırası
  final int routeSeq;

  /// [isActive]: Aktif
  final bool isActive;

  /// [isSynced]: Sync
  final bool isSynced;

  /// [isDeleted]: Soft delete
  final bool isDeleted;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro whms_location}
  const WhmsLocation({
    required this.id,
    required this.warehouseCode,
    required this.code,
    this.aisle = '',
    this.rack = '',
    this.bin = '',
    this.barcode = '',
    this.routeSeq = 0,
    this.isActive = true,
    this.isSynced = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Adres etiketi: aisle-rack-bin veya [code].
  String get addressLabel {
    final parts = <String>[
      aisle.trim(),
      rack.trim(),
      bin.trim(),
    ].where((p) => p.isNotEmpty);
    if (parts.isEmpty) return code.trim();
    return parts.join('-');
  }

  /// SQLite map → model.
  factory WhmsLocation.fromMap(Map<String, dynamic> map) {
    return WhmsLocation(
      id: map['id']?.toString() ?? '',
      warehouseCode: map['warehouse_code']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      aisle: map['aisle']?.toString() ?? '',
      rack: map['rack']?.toString() ?? '',
      bin: map['bin']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      routeSeq: (map['route_seq'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as num?)?.toInt() != 0,
      isSynced: (map['is_synced'] as num?)?.toInt() == 1,
      isDeleted: (map['is_deleted'] as num?)?.toInt() == 1,
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  /// Model → SQLite map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'warehouse_code': warehouseCode,
      'code': code,
      'aisle': aisle,
      'rack': rack,
      'bin': bin,
      'barcode': barcode,
      'route_seq': routeSeq,
      'is_active': isActive ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Kopya (CRUD güncelleme).
  WhmsLocation copyWith({
    String? id,
    String? warehouseCode,
    String? code,
    String? aisle,
    String? rack,
    String? bin,
    String? barcode,
    int? routeSeq,
    bool? isActive,
    bool? isSynced,
    bool? isDeleted,
    String? createdAt,
    String? updatedAt,
  }) {
    return WhmsLocation(
      id: id ?? this.id,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      code: code ?? this.code,
      aisle: aisle ?? this.aisle,
      rack: rack ?? this.rack,
      bin: bin ?? this.bin,
      barcode: barcode ?? this.barcode,
      routeSeq: routeSeq ?? this.routeSeq,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
