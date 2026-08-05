// Dosya Adı: compare_history_store_test.dart
// Açıklama: Dönem karşılaştırma geçmişi SQLite store unit test
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:exfin_ops/modules/manager/reports/model/compare_matrix_models.dart';
import 'package:exfin_ops/modules/manager/reports/viewmodel/compare_history_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late CompareHistoryStore store;

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1);
    store = CompareHistoryStore(openDb: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  test('save list and soft-delete persist across calls', () async {
    final query = ComparisonWizardState.fromTemplate(
      CompareTemplate.companyPeriod,
      anchor: DateTime(2026, 8, 5),
    ).copyWith(companyIds: const ['001'], step: 3);

    final result = CompareMatrixResult(
      query: query,
      rowKeys: const ['001'],
      rowLabels: const ['Firma 1'],
      colKeys: query.periods.map((p) => p.id).toList(),
      colLabels: query.periods.map((p) => p.label).toList(),
      cells: [
        CompareMatrixCell(
          rowKey: '001',
          colKey: query.periods.first.id,
          value: 120,
        ),
      ],
    );

    final saved = await store.save(
      name: 'Firma Ağustos',
      query: query,
      result: result,
    );
    expect(saved.id, isNotEmpty);

    final list = await store.list();
    expect(list.length, 1);
    expect(list.first.name, 'Firma Ağustos');
    expect(list.first.query.companyIds, ['001']);
    expect(list.first.result?.valueAt('001', query.periods.first.id), 120);

    await store.delete(saved.id);
    expect(await store.list(), isEmpty);
    expect(await store.getById(saved.id), isNull);
  });

  test('same name replace updates snapshot', () async {
    final q = ComparisonWizardState.fromTemplate(
      CompareTemplate.periodOverview,
    );
    await store.save(name: 'Özet', query: q);
    final again = await store.save(
      name: 'Özet',
      query: q.copyWith(topN: 25),
    );
    final list = await store.list();
    expect(list.length, 1);
    expect(list.first.id, again.id);
    expect(list.first.query.topN, 25);
  });
}
