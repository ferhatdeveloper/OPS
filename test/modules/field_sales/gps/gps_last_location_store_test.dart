// Dosya Adı: gps_last_location_store_test.dart
// Açıklama: GPS dens son konum seed + SQLite store birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/gps/model/gps_last_location_record.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/gps_last_location_seed.dart';
import 'package:exfin_ops/modules/field_sales/gps/model/personnel_live_location.dart';
import 'package:exfin_ops/modules/field_sales/gps/view/gps_tracking_screen.dart';
import 'package:exfin_ops/modules/field_sales/gps/viewmodel/gps_last_location_store.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  group('GpsLastLocationSeed', () {
    test('route ve stub satırlar dolu', () {
      expect(GpsLastLocationSeed.route, GpsTrackingScreen.routeName);
      expect(GpsLastLocationSeed.tableName, 'gps_logs');
      expect(GpsLastLocationSeed.defaultRows, isNotEmpty);
      for (final r in GpsLastLocationSeed.defaultRows) {
        expect(r.id, isNotEmpty);
        expect(r.salespersonCode, isNotEmpty);
        expect(r.latitude, isNot(0));
        expect(r.longitude, isNot(0));
      }
      expect(GpsLastLocationSeed.defaultMaps.first['timestamp'], isNotEmpty);
    });
  });

  group('GpsLastLocationRecord', () {
    test('toMap/fromMap lat/lng ve plasiyer korur', () {
      final row = GpsLastLocationRecord(
        id: 't1',
        latitude: 41.01,
        longitude: 28.97,
        recordedAt: DateTime(2026, 7, 26, 12, 0),
        salespersonCode: 'PLS01',
        label: 'Test',
        accuracy: 10,
        isSynced: 1,
      );
      final map = row.toMap();
      expect(map['latitude'], 41.01);
      expect(map['salesperson_code'], 'PLS01');
      expect(map['is_synced'], 1);

      final back = GpsLastLocationRecord.fromMap(map);
      expect(back.latitude, 41.01);
      expect(back.longitude, 28.97);
      expect(back.salespersonCode, 'PLS01');
      expect(back.label, 'Test');
      expect(back.accuracy, 10);
      expect(back.coordinateText, contains('41.01000'));
    });
  });

  group('GpsLastLocationStore', () {
    test('seed + plasiyer başına son konum', () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(() async => db.close());

      final store = GpsLastLocationStore(openDb: () async => db);
      await store.ensureReady();

      final rows = await store.loadLastLocations();
      expect(rows.length, GpsLastLocationSeed.defaultRows.length);
      expect(
        rows.map((e) => e.salespersonCode).toSet().length,
        rows.length,
      );

      // Aynı plasiyere daha yeni konum → dens sonu güncellenir
      await db.insert('gps_logs', {
        'id': 'gps_newer_pls01',
        'latitude': 41.1,
        'longitude': 29.1,
        'timestamp': DateTime(2026, 7, 26, 18, 0).toIso8601String(),
        'salesperson_code': 'PLS01',
        'label': 'Güncel',
        'is_synced': 0,
        'is_deleted': 0,
      });

      final after = await store.loadLastLocations();
      final pls01 = after.firstWhere((e) => e.salespersonCode == 'PLS01');
      expect(pls01.id, 'gps_newer_pls01');
      expect(pls01.latitude, 41.1);
      expect(after.length, GpsLastLocationSeed.defaultRows.length);
    });
  });

  testWidgets('GpsTrackingScreen dens seed satırları gösterir', (tester) async {
    final rows = GpsLastLocationSeed.defaultRows
        .map(
          (r) => PersonnelLiveLocation(
            userId: r.salespersonCode,
            salespersonCode: r.salespersonCode,
            displayName: r.label,
            latitude: r.latitude,
            longitude: r.longitude,
            updatedAt: r.recordedAt,
            accuracy: r.accuracy,
            isSynced: r.isSynced == 1,
          ),
        )
        .toList(growable: false);
    await pumpStubWithL10n(
      tester,
      GpsTrackingScreen(records: rows),
    );
    await tester.pump();

    expectStubL10nSmoke(tester, 'field_sales.stubs.gps_tracking');
    expect(find.textContaining('PLS01'), findsWidgets);
    expect(find.textContaining('Eminönü'), findsOneWidget);
    expectStubL10nSmoke(tester, 'field_sales.gps_live_stale');
  });
}
