// Dosya Adı: visit_reason_code_persist_test.dart
// Açıklama: visits.reason_code şema migrate + VisitModel kod kalıcılık testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/route_model.dart';
import 'package:exfin_ops/modules/field_sales/routes/model/visit_reason_master.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('VisitModel reason_code map', () {
    test('toMap / fromMap VisitReasonMaster kodunu taşır', () {
      final now = DateTime.parse('2026-07-26T10:00:00.000');
      final visit = VisitModel(
        id: 'v-1',
        customerId: 'c-1',
        checkInAt: now,
        checkOutAt: now,
        notes: 'SEBEP: ROUTINE\nNOT: ok',
        reasonCode: 'ROUTINE',
        status: 'Completed',
        durationMinutes: 0,
      );

      final map = visit.toMap();
      expect(map['reason_code'], 'ROUTINE');
      expect(VisitReasonMaster.contains(map['reason_code'] as String), isTrue);

      final loaded = VisitModel.fromMap(map);
      expect(loaded.reasonCode, 'ROUTINE');
      expect(loaded.notes, contains('SEBEP: ROUTINE'));
    });

    test('reason_code null iken fromMap null döner', () {
      final map = <String, dynamic>{
        'id': 'v-2',
        'customer_id': 'c-2',
        'check_in_at': '2026-07-26T10:00:00.000',
        'status': 'Open',
        'is_synced': 0,
      };
      final loaded = VisitModel.fromMap(map);
      expect(loaded.reasonCode, isNull);
    });
  });

  group('visits.reason_code migrate', () {
    test('CREATE TABLE reason_code kolonunu içerir', () {
      expect(SqlQuerys.createVisitsTable, contains('reason_code TEXT'));
      expect(
        SqlQuerys.addVisitsReasonCodeColumn,
        contains('ADD COLUMN reason_code'),
      );
    });

    test('eski şemaya ALTER ile reason_code eklenir ve kod yazılır', () async {
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE visits (
                id TEXT PRIMARY KEY,
                customer_id TEXT,
                check_in_at TEXT,
                notes TEXT,
                status TEXT,
                is_synced INTEGER DEFAULT 0
              );
            ''');
          },
        ),
      );

      final before = await db.rawQuery('PRAGMA table_info(visits)');
      expect(
        before.any((c) => c['name'] == 'reason_code'),
        isFalse,
      );

      await db.execute(SqlQuerys.addVisitsReasonCodeColumn);

      final after = await db.rawQuery('PRAGMA table_info(visits)');
      expect(
        after.any((c) => c['name'] == 'reason_code'),
        isTrue,
      );

      await db.insert('visits', {
        'id': 'v-mig-1',
        'customer_id': 'c-1',
        'check_in_at': '2026-07-26T10:00:00.000',
        'notes': 'SEBEP: ORDER',
        'reason_code': 'ORDER',
        'status': 'Completed',
        'is_synced': 0,
      });

      final rows = await db.query(
        'visits',
        where: 'id = ?',
        whereArgs: ['v-mig-1'],
      );
      expect(rows.single['reason_code'], 'ORDER');
      expect(
        VisitReasonMaster.contains(rows.single['reason_code'] as String),
        isTrue,
      );

      await db.close();
    });

    test('yeni CREATE şemasında reason_code doğrudan yazılır', () async {
      final db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(SqlQuerys.createVisitsTable);
          },
        ),
      );

      final cols = await db.rawQuery('PRAGMA table_info(visits)');
      expect(cols.any((c) => c['name'] == 'reason_code'), isTrue);

      final visit = VisitModel(
        id: 'v-new-1',
        customerId: 'c-9',
        checkInAt: DateTime.parse('2026-07-26T12:00:00.000'),
        reasonCode: 'COLLECTION',
        status: 'Open',
      );
      await db.insert('visits', visit.toMap());

      final rows = await db.query(
        'visits',
        where: 'id = ?',
        whereArgs: ['v-new-1'],
      );
      expect(rows.single['reason_code'], 'COLLECTION');

      await db.close();
    });
  });
}
