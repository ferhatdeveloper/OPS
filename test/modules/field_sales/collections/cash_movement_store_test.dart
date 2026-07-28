// Dosya Adı: cash_movement_store_test.dart
// Açıklama: Kasa hareketleri collections query birim testi
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/cash_movement_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createCollectionsTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('listByCashCode collections satırlarını döner', () async {
    await db.insert('collections', {
      'id': 'col-1',
      'customer_id': 'C1',
      'amount': 100,
      'payment_type': 'cash',
      'collection_date': '2026-07-27T10:00:00.000',
      'document_no': 'EVR-1',
      'cash_code': '100 01 01',
      'created_at': '2026-07-27T10:00:00.000',
      'updated_at': '2026-07-27T10:00:00.000',
    });

    final store = CashMovementStore(openDb: () async => db);
    final rows = await store.listByCashCode('100 01 01');
    expect(rows, hasLength(1));
    expect(rows.first.documentNo, 'EVR-1');
    expect(rows.first.operation, 'cash');
  });
}
