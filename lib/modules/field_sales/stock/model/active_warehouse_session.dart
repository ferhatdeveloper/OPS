// Dosya Adı: active_warehouse_session.dart
// Açıklama: Aktif ambar oturum kaydı (login seçimi)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template active_warehouse_session}
/// Seçili ambar (kod + ad + tip).
///
/// Kullanım örneği:
/// ```dart
/// const s = ActiveWarehouseSession(
///   code: 'ARC',
///   name: 'Araç Depo',
///   type: 'vehicle',
/// );
/// print(s.label); // ARC · Araç Depo
/// ```
/// {@endtemplate}
class ActiveWarehouseSession {
  /// [code]: Ambar kodu (MRK/ARC/IAD)
  final String code;

  /// [name]: Görünen ad
  final String name;

  /// [type]: center / vehicle / return
  final String type;

  /// {@macro active_warehouse_session}
  const ActiveWarehouseSession({
    required this.code,
    required this.name,
    this.type = '',
  });

  static const ActiveWarehouseSession empty = ActiveWarehouseSession(
    code: '',
    name: '',
  );

  bool get isEmpty => code.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// Liste / buton etiketi
  String get label {
    final c = code.trim();
    final n = name.trim();
    if (c.isEmpty) return n;
    if (n.isEmpty) return c;
    return '$c · $n';
  }

  ActiveWarehouseSession copyWith({
    String? code,
    String? name,
    String? type,
  }) {
    return ActiveWarehouseSession(
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveWarehouseSession &&
        other.code == code &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(code, name, type);
}
