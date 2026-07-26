// Dosya Adı: shelf_audit_store_test.dart
// Açıklama: Raf denetimi SharedPreferences kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/surveys/model/shelf_audit_record.dart';
import 'package:exfin_ops/modules/field_sales/surveys/viewmodel/shelf_audit_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ShelfAuditStore', () {
    test('boş prefs yüklenince varsayılan döner', () async {
      const store = ShelfAuditStore();
      final record = await store.load();
      expect(record.brandName, isEmpty);
      expect(record.facings, 0);
      expect(record.hasStock, isTrue);
    });

    test('save / load turu kalıcıdır', () async {
      const store = ShelfAuditStore();
      final updatedAt = DateTime(2026, 7, 26, 12, 0);
      await store.save(
        ShelfAuditRecord(
          customerCode: 'C001',
          customerName: 'Demo',
          category: 'İçecek',
          brandName: 'Marka A',
          facings: 5,
          shelfSharePct: 40.5,
          hasStock: false,
          notes: 'not',
          updatedAt: updatedAt,
        ),
      );

      final loaded = await store.load();
      expect(loaded.customerCode, 'C001');
      expect(loaded.brandName, 'Marka A');
      expect(loaded.facings, 5);
      expect(loaded.shelfSharePct, 40.5);
      expect(loaded.hasStock, isFalse);
      expect(loaded.updatedAt, updatedAt);

      await store.clear();
      expect((await store.load()).brandName, isEmpty);
    });
  });
}
