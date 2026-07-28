// Dosya Adı: warehouse_list_row.dart
// Açıklama: Ambar dens satır modeli (kod · ad · tip)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

/// {@template warehouse_list_row}
/// Ambar dens satırı (kod · ad · tip).
///
/// Kullanım örneği:
/// ```dart
/// const row = WarehouseListRow(code: 'ARC', name: 'Araç Depo');
/// print(row.label); // ARC · Araç Depo
/// ```
/// {@endtemplate}
class WarehouseListRow {
  /// [code]: Ambar kodu
  final String code;

  /// [name]: Görünen ad
  final String name;

  /// [type]: Tip (center/vehicle/return)
  final String type;

  /// {@macro warehouse_list_row}
  const WarehouseListRow({
    required this.code,
    required this.name,
    this.type = '',
  });

  /// Liste etiketi
  String get label {
    if (code.isEmpty) return name;
    if (name.isEmpty) return code;
    return '$code · $name';
  }
}
