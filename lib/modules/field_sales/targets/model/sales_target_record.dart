// Dosya Adı: sales_target_record.dart
// Açıklama: Satış hedefi dens satırı (SQLite targets tablosu)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template sales_target_record}
/// Plasiyer satış hedefi dens satırı — `targets` SQLite kolonları.
///
/// Kullanım örneği:
/// ```dart
/// final row = SalesTargetRecord(
///   id: 'st_1',
///   userId: 'Ahmet Yılmaz',
///   targetAmount: 250000,
///   achievedAmount: 180000,
///   period: '2026-07',
///   type: 'Sales',
/// );
/// ```
/// {@endtemplate}
class SalesTargetRecord {
  /// [id]: Yerel birincil anahtar
  final String id;

  /// [userId]: Plasiyer / personel adı veya kodu
  final String userId;

  /// [targetAmount]: Hedef tutar / adet
  final double targetAmount;

  /// [achievedAmount]: Gerçekleşen tutar / adet
  final double achievedAmount;

  /// [period]: Dönem (`2026-07`, `2026-Q3`, `Temmuz`)
  final String period;

  /// [type]: `Sales` | `Collection` | `Visit`
  final String type;

  /// [createdAt]: Oluşturma (ISO-8601)
  final String? createdAt;

  /// [updatedAt]: Güncelleme (ISO-8601)
  final String? updatedAt;

  /// [isSynced]: Senkron bayrağı (0/1)
  final int isSynced;

  /// {@macro sales_target_record}
  const SalesTargetRecord({
    required this.id,
    required this.userId,
    required this.targetAmount,
    this.achievedAmount = 0,
    required this.period,
    required this.type,
    this.createdAt,
    this.updatedAt,
    this.isSynced = 0,
  });

  /// {@template sales_target_record_achievement_ratio}
  /// Gerçekleşme oranı (0…∞); hedef 0 ise 0.
  /// {@endtemplate}
  double get achievementRatio {
    if (targetAmount <= 0) return 0;
    return achievedAmount / targetAmount;
  }

  /// {@template sales_target_record_achievement_percent}
  /// Gerçekleşme yüzdesi (0…∞).
  /// {@endtemplate}
  double get achievementPercent => achievementRatio * 100;

  /// {@template sales_target_record_to_map}
  /// SQLite `targets` satır map’i.
  ///
  /// Dönüş değeri:
  /// - [Map]: Kolon → değer
  /// {@endtemplate}
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'target_amount': targetAmount,
      'achieved_amount': achievedAmount,
      'period': period,
      'type': type,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_synced': isSynced,
    };
  }

  /// {@template sales_target_record_from_map}
  /// SQLite / seed map → dens satır.
  ///
  /// Parametreler:
  /// - [map]: Kolon map’i
  ///
  /// Dönüş değeri:
  /// - [SalesTargetRecord]: Dens satırı
  /// {@endtemplate}
  factory SalesTargetRecord.fromMap(Map<String, dynamic> map) {
    return SalesTargetRecord(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0,
      achievedAmount: (map['achieved_amount'] as num?)?.toDouble() ?? 0,
      period: map['period']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Sales',
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      isSynced: (map['is_synced'] as num?)?.toInt() ?? 0,
    );
  }

  /// {@template sales_target_record_copy_with}
  /// İmmutable kopya.
  /// {@endtemplate}
  SalesTargetRecord copyWith({
    String? id,
    String? userId,
    double? targetAmount,
    double? achievedAmount,
    String? period,
    String? type,
    String? createdAt,
    String? updatedAt,
    int? isSynced,
  }) {
    return SalesTargetRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetAmount: targetAmount ?? this.targetAmount,
      achievedAmount: achievedAmount ?? this.achievedAmount,
      period: period ?? this.period,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
