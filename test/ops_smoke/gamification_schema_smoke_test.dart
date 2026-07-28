// Dosya Adı: gamification_schema_smoke_test.dart
// Açıklama: OPS smoke — plasiyer_profile şema SQL varlığı
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('createPlasiyerProfileTable applies on in-memory db', () async {
    final db = await openDatabase(inMemoryDatabasePath, version: 1);
    addTearDown(db.close);
    await db.execute(SqlQuerys.createPlasiyerProfileTable);
    final info = await db.rawQuery('PRAGMA table_info(plasiyer_profile)');
    final names = info.map((c) => c['name']).toList();
    expect(names, contains('total_points'));
    expect(names, contains('level'));
  });
}
