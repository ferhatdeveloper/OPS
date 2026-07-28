// Dosya Adı: whms_tare.dart
// Açıklama: WHMS dara master modeli (code · weight)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

/// {@template whms_tare}
/// Dara kaydı: [code] + [weight] (kg).
///
/// Kullanım örneği:
/// ```dart
/// const t = WhmsTare(id: '1', code: 'PALET', name: 'Palet', weight: 25);
/// ```
/// {@endtemplate}
class WhmsTare {
  /// [id]: PK
  final String id;

  /// [code]: Unique kod
  final String code;

  /// [name]: Görünen ad
  final String name;

  /// [weight]: Ağırlık (kg)
  final double weight;

  /// [isActive]: Aktif
  final bool isActive;

  /// [createdAt]: Oluşturma
  final String? createdAt;

  /// [updatedAt]: Güncelleme
  final String? updatedAt;

  /// {@macro whms_tare}
  const WhmsTare({
    required this.id,
    required this.code,
    required this.name,
    this.weight = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory WhmsTare.fromMap(Map<String, dynamic> map) {
    return WhmsTare(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
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
      'weight': weight,
      'is_active': isActive ? 1 : 0,
      'ONAY': 0,
      'is_synced': 0,
      'is_deleted': 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  WhmsTare copyWith({
    String? code,
    String? name,
    double? weight,
    bool? isActive,
    String? updatedAt,
  }) {
    return WhmsTare(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
