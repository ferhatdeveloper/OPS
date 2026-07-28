// Dosya Adı: active_warehouse_store_test.dart
// Açıklama: Aktif ambar prefs oturum birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:exfin_ops/modules/field_sales/stock/model/active_warehouse_session.dart';
import 'package:exfin_ops/modules/field_sales/stock/viewmodel/active_warehouse_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ActiveWarehouseStore.resetMemory();
  });

  test('save + load ambar oturumu', () async {
    const store = ActiveWarehouseStore();
    await store.save(
      const ActiveWarehouseSession(
        code: 'ARC',
        name: 'Araç Depo',
        type: 'vehicle',
      ),
    );
    final loaded = await store.load();
    expect(loaded.code, 'ARC');
    expect(loaded.name, 'Araç Depo');
    expect(ActiveWarehouseStore.current?.code, 'ARC');
    expect(loaded.label, 'ARC · Araç Depo');
  });
}
