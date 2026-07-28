// Dosya Adı: postgrest_store_row_test.dart
// Açıklama: RetailEX /stores satırı eşlemesi ve varsayılan seçim
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/core/tenant/postgrest_master_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostgrestStoreRow', () {
    test('fromMap maps firm_nr and flags', () {
      final row = PostgrestStoreRow.fromMap({
        'id': 'uuid-1',
        'code': 'ST_01',
        'name': 'Merkez Depo',
        'firm_nr': '1',
        'is_main': true,
        'is_active': true,
        'default': true,
        'type': null,
      });
      expect(row.code, 'ST_01');
      expect(row.firmNr, '001');
      expect(row.isMain, isTrue);
      expect(row.isDefault, isTrue);
      expect(row.type, 'center');
      final dens = row.toWarehouseSeedRow();
      expect(dens.seedName, 'Merkez Depo');
      expect(dens.nameKey, 'api.store.ST_01');
    });

    test('pickDefaultStore prefers default then main', () {
      final sync = PostgrestMasterSync();
      final stores = [
        const PostgrestStoreRow(
          id: 'a',
          code: 'A',
          name: 'A',
          firmNr: '001',
          isMain: true,
        ),
        const PostgrestStoreRow(
          id: 'b',
          code: 'B',
          name: 'B',
          firmNr: '001',
          isDefault: true,
          isActive: true,
        ),
      ];
      expect(sync.pickDefaultStore(stores)?.code, 'B');
    });
  });
}
