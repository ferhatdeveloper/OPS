// Dosya Adı: report_pivot_preference_store_test.dart
// Açıklama: Pivot varsayılan görünüm — rapor id başına kalıcılık
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/reports/viewmodel/report_pivot_preference_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rapor id başına kaydet / yükle / sil', () async {
    final mem = <String, String>{};
    final store = ReportPivotPreferenceStore(memory: mem);

    expect(await store.load('cari_extre'), isNull);

    await store.save(
      'cari_extre',
      const ReportPivotPreference(
        rowFieldId: 'code',
        columnFieldId: 'date',
        valueFieldId: 'amount',
      ),
    );

    final loaded = await store.load('cari_extre');
    expect(loaded, isNotNull);
    expect(loaded!.rowFieldId, 'code');
    expect(loaded.columnFieldId, 'date');
    expect(loaded.valueFieldId, 'amount');

    // Ayrı rapor id karışmaz
    expect(await store.load('tahsilat_listesi'), isNull);

    await store.clear('cari_extre');
    expect(await store.load('cari_extre'), isNull);
  });
}
