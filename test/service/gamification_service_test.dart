// Dosya Adı: gamification_service_test.dart
// Açıklama: plasiyer_profile şema/seed ve puan upsert birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/service/gamification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(inMemoryDatabasePath, version: 1);
  });

  tearDown(() async {
    await db.close();
  });

  group('SqlQuerys.createPlasiyerProfileTable', () {
    test('CREATE TABLE IF NOT EXISTS plasiyer_profile içerir', () {
      expect(
        SqlQuerys.createPlasiyerProfileTable,
        contains('CREATE TABLE IF NOT EXISTS plasiyer_profile'),
      );
      expect(
        SqlQuerys.createPlasiyerProfileTable,
        contains('total_points'),
      );
      expect(
        SqlQuerys.createPlasiyerProfileTable,
        contains('last_achievement'),
      );
    });
  });

  group('GamificationService.ensureSchema', () {
    test('tablo yokken oluşturur ve user seed yazar', () async {
      final service = GamificationService();
      const userId = '10000000-0000-4000-a000-000000000001';

      await service.ensureSchema(
        db,
        userId: userId,
        displayName: 'Demo Plasiyer',
      );

      final rows = await db.query(
        'plasiyer_profile',
        where: 'id = ?',
        whereArgs: [userId],
      );
      expect(rows, hasLength(1));
      expect(rows.first['name'], 'Demo Plasiyer');
      expect(rows.first['total_points'], 0);
    });

    test('puan UPDATE sonra satır artar', () async {
      final service = GamificationService();
      const userId = 'user-a';
      await service.ensureSchema(db, userId: userId);

      final updated = await db.rawUpdate(
        '''
        UPDATE plasiyer_profile
        SET total_points = total_points + ?,
            last_achievement = ?
        WHERE id = ?
        ''',
        [10, 'Ziyaret Başlatıldı', userId],
      );
      expect(updated, 1);

      final rows = await db.query(
        'plasiyer_profile',
        where: 'id = ?',
        whereArgs: [userId],
      );
      expect(rows.first['total_points'], 10);
      expect(rows.first['last_achievement'], 'Ziyaret Başlatıldı');
    });

    test('addPoints tablo yokken oluşturur ve puan yazar', () async {
      const userId = 'p0-user';
      final service = GamificationService();
      final ok = await service.addPoints(
        userId,
        10,
        'Test',
        database: db,
      );
      expect(ok, isTrue);

      final rows = await db.query(
        'plasiyer_profile',
        where: 'id = ?',
        whereArgs: [userId],
      );
      expect(rows, hasLength(1));
      expect(rows.first['total_points'], 10);
    });

    test('ensureSchema bozuk bağlantıda fırlatmaz', () async {
      final service = GamificationService();
      await db.close();
      // Kapalı db — check-in yolunu bozmamalı
      await expectLater(
        service.ensureSchema(db, userId: 'x'),
        completes,
      );
      db = await openDatabase(inMemoryDatabasePath, version: 1);
    });
  });

  group('SqlQuerys.fieldSalesMenuL10nByUuid', () {
    test('Diğer / GPS / kamera uuid → dotted l10n key', () {
      final map = SqlQuerys.fieldSalesMenuL10nByUuid;
      expect(map['fs_other'], 'dashboard.diger');
      expect(map['sub_oth_live_loc'], 'submodules.canli_konum');
      expect(map['sub_oth_cam_monitor'], 'submodules.arac_kamera_izleme');
      expect(
        map['sub_oth_cam_settings'],
        'field_sales.stubs.vehicle_camera_settings',
      );
      expect(map.values.every((t) => t.contains('.')), isTrue);
    });

    test('legacy TR title UPDATE ile key olur', () async {
      await db.execute('''
        CREATE TABLE menu (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT,
          title TEXT,
          module_name TEXT,
          updated_at TEXT
        );
      ''');
      await db.insert('menu', {
        'uuid': 'fs_other',
        'title': 'Diğer',
        'module_name': 'FieldSales',
      });
      await db.insert('menu', {
        'uuid': 'sub_oth_live_loc',
        'title': 'Canlı Konum',
        'module_name': 'FieldSales',
      });

      for (final e in SqlQuerys.fieldSalesMenuL10nByUuid.entries) {
        await db.update(
          'menu',
          {'title': e.value},
          where: 'uuid = ?',
          whereArgs: [e.key],
        );
      }

      final other = await db.query(
        'menu',
        where: 'uuid = ?',
        whereArgs: ['fs_other'],
      );
      final live = await db.query(
        'menu',
        where: 'uuid = ?',
        whereArgs: ['sub_oth_live_loc'],
      );
      expect(other.first['title'], 'dashboard.diger');
      expect(live.first['title'], 'submodules.canli_konum');
    });
  });
}
