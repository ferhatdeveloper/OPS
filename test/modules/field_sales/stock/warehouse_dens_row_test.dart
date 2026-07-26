// Dosya Adı: warehouse_dens_row_test.dart
// Açıklama: Çoklu ambar dens satırının warehouses SQLite map eşlemesi
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/warehouse_dens_row.dart';
import 'package:exfin_ops/modules/field_sales/stock/model/warehouse_master_seed.dart';

void main() {
  group('WarehouseDensRow.fromWarehouseMap', () {
    test('kod / ad / tip dens alanları dolar', () {
      final row = WarehouseDensRow.fromWarehouseMap({
        'id': 'wh_mrk',
        'code': 'MRK',
        'name': 'Merkez Depo',
        'type': WarehouseMasterSeed.typeCenter,
        'is_active': 1,
      });

      expect(row.id, 'wh_mrk');
      expect(row.code, 'MRK');
      expect(row.name, 'Merkez Depo');
      expect(row.type, WarehouseMasterSeed.typeCenter);
      expect(
        row.typeNameKey,
        'field_sales.stock_slip.warehouse_center',
      );
    });

    test('araç tipi vehicle l10n anahtarı alır', () {
      final row = WarehouseDensRow.fromWarehouseMap({
        'id': 'wh_arc',
        'code': 'ARC',
        'name': 'Araç Depo',
        'type': WarehouseMasterSeed.typeVehicle,
      });

      expect(
        row.typeNameKey,
        'field_sales.stock_slip.warehouse_vehicle',
      );
    });
  });

  group('WarehouseDensRow.fromWarehouseMaps', () {
    test('aktif satırları kod artan sırada döner; pasifi eler', () {
      final rows = WarehouseDensRow.fromWarehouseMaps([
        {
          'id': 'wh_iad',
          'code': 'IAD',
          'name': 'İade Deposu',
          'type': WarehouseMasterSeed.typeReturn,
          'is_active': 1,
        },
        {
          'id': 'wh_off',
          'code': 'ZZZ',
          'name': 'Kapalı',
          'type': WarehouseMasterSeed.typeCenter,
          'is_active': 0,
        },
        {
          'id': 'wh_arc',
          'code': 'ARC',
          'name': 'Araç Depo',
          'type': WarehouseMasterSeed.typeVehicle,
          'is_active': 1,
        },
      ]);

      expect(rows.map((r) => r.code).toList(), ['ARC', 'IAD']);
      expect(rows.first.type, WarehouseMasterSeed.typeVehicle);
    });

    test('seed maps → 3 dens satır', () {
      final rows = WarehouseDensRow.fromSeed();
      expect(rows.length, WarehouseMasterSeed.defaultRows.length);
      expect(rows.map((r) => r.code).toList(), ['ARC', 'IAD', 'MRK']);
    });
  });
}
