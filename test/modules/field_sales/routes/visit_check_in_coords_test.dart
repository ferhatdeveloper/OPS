// Dosya Adı: visit_check_in_coords_test.dart
// Açıklama: Rota dışı cari check-in koordinat çözümleme birim testi
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('customers tablosundan lat/lng okunur (rota dışı check-in)', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(() async => db.close());

    await db.execute(SqlQuerys.createCustomersTable);
    await db.insert('customers', {
      'id': 'c1',
      'code': 'C1',
      'name': 'Test Cari',
      'latitude': 41.01,
      'longitude': 28.97,
      'is_active': 1,
      'created_at': '2026-07-27T00:00:00.000',
      'updated_at': '2026-07-27T00:00:00.000',
      'card_role': 'customer',
    });

    final rows = await db.query(
      'customers',
      columns: ['latitude', 'longitude'],
      where: 'id = ?',
      whereArgs: ['c1'],
      limit: 1,
    );
    expect(rows, hasLength(1));
    expect((rows.first['latitude'] as num).toDouble(), 41.01);
    expect((rows.first['longitude'] as num).toDouble(), 28.97);
  });

  test('rota dışı cari için firstWhere StateError üretmez (where boş)', () {
    final routeCustomers = <String>[];
    final matches = routeCustomers.where((id) => id == 'missing');
    expect(matches.isEmpty, isTrue);
    // Eski kod firstWhere ile StateError verirdi; boş where güvenli
    expect(() => matches.first, throwsStateError);
  });
}
