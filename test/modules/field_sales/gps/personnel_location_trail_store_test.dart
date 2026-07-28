// Dosya Adı: personnel_location_trail_store_test.dart
// Açıklama: Trail nokta merge + dönem aralığı + SQLite trail birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/field_sales/gps/model/personnel_location_trail_point.dart';
import 'package:exfin_ops/modules/field_sales/gps/viewmodel/personnel_location_trail_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('PersonnelLocationTrailPoint.mergeChronological', () {
    test('geçersiz koordinat elenir, kronolojik sıralar', () {
      final a = PersonnelLocationTrailPoint(
        id: 'a',
        salespersonCode: 'PLS01',
        latitude: 41.01,
        longitude: 28.97,
        recordedAt: DateTime(2026, 7, 28, 10, 0),
      );
      final b = PersonnelLocationTrailPoint(
        id: 'b',
        salespersonCode: 'PLS01',
        latitude: 41.02,
        longitude: 28.98,
        recordedAt: DateTime(2026, 7, 28, 9, 0),
      );
      final zero = PersonnelLocationTrailPoint(
        id: 'z',
        salespersonCode: 'PLS01',
        latitude: 0,
        longitude: 0,
        recordedAt: DateTime(2026, 7, 28, 11, 0),
      );
      final merged = PersonnelLocationTrailPoint.mergeChronological([
        a,
        zero,
        b,
      ]);
      expect(merged.length, 2);
      expect(merged.first.id, 'b');
      expect(merged.last.id, 'a');
    });

    test('aynı id için daha yeni kaydı tutar', () {
      final older = PersonnelLocationTrailPoint(
        id: 'same',
        salespersonCode: 'PLS01',
        latitude: 41.0,
        longitude: 29.0,
        recordedAt: DateTime(2026, 7, 28, 8, 0),
      );
      final newer = PersonnelLocationTrailPoint(
        id: 'same',
        salespersonCode: 'PLS01',
        latitude: 41.1,
        longitude: 29.1,
        recordedAt: DateTime(2026, 7, 28, 12, 0),
      );
      final merged =
          PersonnelLocationTrailPoint.mergeChronological([older, newer]);
      expect(merged.length, 1);
      expect(merged.first.latitude, closeTo(41.1, 1e-6));
    });

    test('fromMap timestamp / salesperson_code okur', () {
      final p = PersonnelLocationTrailPoint.fromMap({
        'id': 'g1',
        'salesperson_code': 'PLS02',
        'latitude': 40.5,
        'longitude': 29.5,
        'timestamp': '2026-07-28T15:30:00.000',
        'accuracy': 8.5,
        'label': 'Test',
      });
      expect(p.salespersonCode, 'PLS02');
      expect(p.latitude, closeTo(40.5, 1e-6));
      expect(p.recordedAt.hour, 15);
      expect(p.accuracy, 8.5);
      expect(p.label, 'Test');
    });
  });

  group('PersonnelLocationTrailStore.rangeForPeriod', () {
    test('bugün ve bu hafta aralığı', () {
      final now = DateTime(2026, 7, 28); // Salı
      final today = PersonnelLocationTrailStore.rangeForPeriod(
        PersonnelTrailPeriod.today,
        now: now,
      );
      expect(today.$1, DateTime(2026, 7, 28));
      expect(today.$2, DateTime(2026, 7, 28));

      final week = PersonnelLocationTrailStore.rangeForPeriod(
        PersonnelTrailPeriod.thisWeek,
        now: now,
      );
      expect(week.$1, DateTime(2026, 7, 27)); // Pzt
      expect(week.$2, DateTime(2026, 8, 2)); // Paz
    });
  });

  group('PersonnelLocationTrailStore.loadTrailLocal', () {
    test('plasiyer + tarih filtresi kronolojik trail döner', () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() async => db.close());

      final store = PersonnelLocationTrailStore(openDb: () async => db);
      await store.loadTrailLocal(
        salespersonCode: 'PLS01',
        start: DateTime(2026, 7, 28),
        end: DateTime(2026, 7, 28),
      );

      await db.insert('gps_logs', {
        'id': 't1',
        'latitude': 41.0,
        'longitude': 29.0,
        'timestamp': DateTime(2026, 7, 28, 9, 0).toIso8601String(),
        'salesperson_code': 'PLS01',
        'label': 'A',
        'is_synced': 0,
        'is_deleted': 0,
      });
      await db.insert('gps_logs', {
        'id': 't2',
        'latitude': 41.01,
        'longitude': 29.01,
        'timestamp': DateTime(2026, 7, 28, 11, 0).toIso8601String(),
        'salesperson_code': 'PLS01',
        'label': 'B',
        'is_synced': 0,
        'is_deleted': 0,
      });
      await db.insert('gps_logs', {
        'id': 'other',
        'latitude': 40.0,
        'longitude': 28.0,
        'timestamp': DateTime(2026, 7, 28, 10, 0).toIso8601String(),
        'salesperson_code': 'PLS99',
        'label': 'X',
        'is_synced': 0,
        'is_deleted': 0,
      });
      await db.insert('gps_logs', {
        'id': 'old',
        'latitude': 41.02,
        'longitude': 29.02,
        'timestamp': DateTime(2026, 7, 20, 10, 0).toIso8601String(),
        'salesperson_code': 'PLS01',
        'label': 'Old',
        'is_synced': 0,
        'is_deleted': 0,
      });

      final trail = await store.loadTrailLocal(
        salespersonCode: 'PLS01',
        start: DateTime(2026, 7, 28),
        end: DateTime(2026, 7, 28),
      );
      expect(trail.length, 2);
      expect(trail.first.id, 't1');
      expect(trail.last.id, 't2');
    });
  });
}
