// Dosya Adı: warehouse_master_seed.dart
// Açıklama: OPS ambar master seed (WHMS yok — kod/ad/tip sabitleri)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

/// {@template warehouse_master_seed_row}
/// Tek ambar satırı (kod + tip + l10n ad anahtarı).
///
/// Kullanım örneği:
/// ```dart
/// const row = WarehouseMasterSeedRow(
///   id: 'wh_mrk',
///   code: 'MRK',
///   type: WarehouseMasterSeed.typeCenter,
///   nameKey: 'field_sales.stock_slip.warehouse_center',
///   seedName: 'Merkez Depo',
/// );
/// ```
/// {@endtemplate}
class WarehouseMasterSeedRow {
  /// [id]: SQLite birincil anahtar
  final String id;

  /// [code]: Ambar kodu (sync eşleşmesi)
  final String code;

  /// [type]: merkez / araç / iade
  final String type;

  /// [nameKey]: Görünen ad l10n anahtarı
  final String nameKey;

  /// [seedName]: SQLite seed TR adı
  final String seedName;

  /// {@macro warehouse_master_seed_row}
  const WarehouseMasterSeedRow({
    required this.id,
    required this.code,
    required this.type,
    required this.nameKey,
    required this.seedName,
  });
}

/// {@template warehouse_master_seed}
/// OPS ambar master seed — WHMS domain değil; prep adım 3.
///
/// Kullanım örneği:
/// ```dart
/// final rows = WarehouseMasterSeed.defaultRows;
/// ```
/// {@endtemplate}
class WarehouseMasterSeed {
  WarehouseMasterSeed._();

  /// [tableName]: SQLite tablo adı
  static const String tableName = 'warehouses';

  /// [typeCenter]: Merkez depo tipi
  static const String typeCenter = 'center';

  /// [typeVehicle]: Araç depo tipi
  static const String typeVehicle = 'vehicle';

  /// [typeReturn]: İade depo tipi
  static const String typeReturn = 'return';

  /// Yer tutucu dens ambarlar (kod + tip).
  static const List<WarehouseMasterSeedRow> defaultRows = [
    WarehouseMasterSeedRow(
      id: 'wh_mrk',
      code: 'MRK',
      type: typeCenter,
      nameKey: 'field_sales.stock_slip.warehouse_center',
      seedName: 'Merkez Depo',
    ),
    WarehouseMasterSeedRow(
      id: 'wh_arc',
      code: 'ARC',
      type: typeVehicle,
      nameKey: 'field_sales.stock_slip.warehouse_vehicle',
      seedName: 'Araç Depo',
    ),
    WarehouseMasterSeedRow(
      id: 'wh_iad',
      code: 'IAD',
      type: typeReturn,
      nameKey: 'field_sales.stock_slip.warehouse_return',
      seedName: 'İade Deposu',
    ),
  ];

  /// {@template warehouse_master_seed_by_code}
  /// Koda göre seed satırı bulur.
  ///
  /// Parametreler:
  /// - [code]: Ambar kodu
  ///
  /// Dönüş değeri:
  /// - [WarehouseMasterSeedRow]: Eşleşen satır veya null
  /// {@endtemplate}
  static WarehouseMasterSeedRow? byCode(String code) {
    for (final row in defaultRows) {
      if (row.code == code) return row;
    }
    return null;
  }

  /// {@template warehouse_master_seed_maps}
  /// SQLite insert için map listesi.
  ///
  /// Dönüş değeri:
  /// - [List]: `warehouses` satır map’leri
  /// {@endtemplate}
  static List<Map<String, dynamic>> get defaultMaps {
    const createdAt = '2026-07-26T00:00:00.000';
    return defaultRows
        .map(
          (wh) => <String, dynamic>{
            'id': wh.id,
            'code': wh.code,
            'name': wh.seedName,
            'type': wh.type,
            'is_active': 1,
            'is_synced': 0,
            'created_at': createdAt,
            'updated_at': createdAt,
          },
        )
        .toList(growable: false);
  }
}
