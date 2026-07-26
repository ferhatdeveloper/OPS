// Dosya Adı: warehouse_dens_row.dart
// Açıklama: Çoklu ambar dens satırı — warehouses SQLite eşlemesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'warehouse_master_seed.dart';

/// {@template warehouse_dens_row}
/// Plasiyer çoklu ambar dens satırı (kod · ad · tip).
///
/// Kullanım örneği:
/// ```dart
/// final row = WarehouseDensRow.fromWarehouseMap({
///   'id': 'wh_mrk',
///   'code': 'MRK',
///   'name': 'Merkez Depo',
///   'type': 'center',
///   'is_active': 1,
/// });
/// print(row.code); // MRK
/// ```
/// {@endtemplate}
class WarehouseDensRow {
  /// [id]: warehouses.id
  final String id;

  /// [code]: Ambar kodu
  final String code;

  /// [name]: Ambar adı (SQLite name)
  final String name;

  /// [type]: merkez / araç / iade ham değeri
  final String type;

  /// [typeNameKey]: Tip görünen adı l10n anahtarı
  final String typeNameKey;

  /// {@macro warehouse_dens_row}
  const WarehouseDensRow({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.typeNameKey,
  });

  /// {@template warehouse_dens_row_type_name_key}
  /// Tip kodunu stock_slip l10n anahtarına çevirir.
  ///
  /// Parametreler:
  /// - [type]: center / vehicle / return
  ///
  /// Dönüş değeri:
  /// - [String]: l10n anahtarı
  /// {@endtemplate}
  static String typeNameKeyFor(String type) {
    switch (type) {
      case WarehouseMasterSeed.typeVehicle:
        return 'field_sales.stock_slip.warehouse_vehicle';
      case WarehouseMasterSeed.typeReturn:
        return 'field_sales.stock_slip.warehouse_return';
      case WarehouseMasterSeed.typeCenter:
      default:
        return 'field_sales.stock_slip.warehouse_center';
    }
  }

  /// {@template warehouse_dens_row_from_map}
  /// Tek warehouses satırını dens satıra çevirir.
  ///
  /// Parametreler:
  /// - [map]: SQLite warehouses satırı
  ///
  /// Dönüş değeri:
  /// - [WarehouseDensRow]: Dens satır
  /// {@endtemplate}
  factory WarehouseDensRow.fromWarehouseMap(Map<String, dynamic> map) {
    final type = (map['type'] ?? WarehouseMasterSeed.typeCenter).toString();
    final code = (map['code'] ?? '').toString();
    final seed = WarehouseMasterSeed.byCode(code);
    return WarehouseDensRow(
      id: (map['id'] ?? '').toString(),
      code: code,
      name: (map['name'] ?? seed?.seedName ?? '').toString(),
      type: type,
      typeNameKey: seed?.nameKey ?? typeNameKeyFor(type),
    );
  }

  /// {@template warehouse_dens_row_from_maps}
  /// Aktif ambarları kod artan sırada dens listeye çevirir.
  ///
  /// Parametreler:
  /// - [maps]: SQLite warehouses satırları
  ///
  /// Dönüş değeri:
  /// - [List]: Dens ambar satırları
  /// {@endtemplate}
  static List<WarehouseDensRow> fromWarehouseMaps(
    List<Map<String, dynamic>> maps,
  ) {
    final active = maps.where((m) {
      final flag = m['is_active'];
      if (flag == null) return true;
      if (flag is int) return flag == 1;
      return flag.toString() == '1' ||
          flag.toString().toLowerCase() == 'true';
    }).toList();

    active.sort((a, b) {
      final ca = (a['code'] ?? '').toString();
      final cb = (b['code'] ?? '').toString();
      return ca.compareTo(cb);
    });

    return active
        .map(WarehouseDensRow.fromWarehouseMap)
        .toList(growable: false);
  }

  /// {@template warehouse_dens_row_from_seed}
  /// [WarehouseMasterSeed] varsayılan dens satırları.
  ///
  /// Dönüş değeri:
  /// - [List]: Seed dens satırları
  /// {@endtemplate}
  static List<WarehouseDensRow> fromSeed() {
    return fromWarehouseMaps(WarehouseMasterSeed.defaultMaps);
  }
}
