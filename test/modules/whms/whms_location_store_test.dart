// Dosya Adı: whms_location_store_test.dart
// Açıklama: WhmsLocation model + store (in-memory) + fake mock testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/whms/locations/model/whms_location.dart';
import 'package:exfin_ops/modules/whms/locations/viewmodel/whms_location_store.dart';

/// Test double — UI / emir akışı store’a bağlanmadan lokasyon listesi.
class _FakeWhmsLocationStore {
  _FakeWhmsLocationStore(this._rows);

  final List<WhmsLocation> _rows;

  Future<List<WhmsLocation>> listActive({String? warehouseCode}) async {
    final code = warehouseCode?.trim() ?? '';
    final active = _rows.where((r) => !r.isDeleted && r.isActive);
    if (code.isEmpty) return active.toList(growable: false);
    return active
        .where((r) => r.warehouseCode == code)
        .toList(growable: false);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WhmsLocation', () {
    test('addressLabel + toMap/fromMap round-trip', () {
      const loc = WhmsLocation(
        id: 'loc1',
        warehouseCode: 'MRK',
        code: 'A-01-02',
        aisle: 'A',
        rack: '01',
        bin: '02',
        barcode: 'LOC-1',
        routeSeq: 20,
      );
      expect(loc.addressLabel, 'A-01-02');
      final round = WhmsLocation.fromMap(loc.toMap());
      expect(round.id, 'loc1');
      expect(round.code, 'A-01-02');
      expect(round.warehouseCode, 'MRK');
      expect(round.routeSeq, 20);
      expect(round.isActive, isTrue);
      expect(round.isDeleted, isFalse);
    });

    test('aisle/rack/bin boşsa addressLabel = code', () {
      const loc = WhmsLocation(
        id: 'loc2',
        warehouseCode: 'MRK',
        code: 'ZONE-1',
      );
      expect(loc.addressLabel, 'ZONE-1');
    });
  });

  group('_FakeWhmsLocationStore (mock)', () {
    test('warehouse filtresi yalnızca eşleşen aktif satırları döner', () async {
      final fake = _FakeWhmsLocationStore(const [
        WhmsLocation(
          id: '1',
          warehouseCode: 'MRK',
          code: 'A-01-01',
        ),
        WhmsLocation(
          id: '2',
          warehouseCode: 'ARC',
          code: 'B-01-01',
        ),
        WhmsLocation(
          id: '3',
          warehouseCode: 'MRK',
          code: 'A-02-01',
          isDeleted: true,
        ),
      ]);

      final mrk = await fake.listActive(warehouseCode: 'MRK');
      expect(mrk.map((e) => e.id).toList(), ['1']);
      final all = await fake.listActive();
      expect(all.map((e) => e.id).toList(), ['1', '2']);
    });
  });

  group('WhmsLocationStore', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {},
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('upsert + listActive MRK filtreler', () async {
      final store = WhmsLocationStore(openDb: () async => db);
      await store.ensureReady();

      await store.upsert(
        const WhmsLocation(
          id: 'loc_mrk',
          warehouseCode: 'MRK',
          code: 'A-01-01',
          aisle: 'A',
          rack: '01',
          bin: '01',
          routeSeq: 10,
        ),
      );
      await store.upsert(
        const WhmsLocation(
          id: 'loc_arc',
          warehouseCode: 'ARC',
          code: 'B-01-01',
          routeSeq: 10,
        ),
      );

      final all = await store.listActive();
      expect(all, hasLength(2));

      final mrk = await store.listActive(warehouseCode: 'MRK');
      expect(mrk, hasLength(1));
      expect(mrk.first.code, 'A-01-01');
      expect(mrk.first.addressLabel, 'A-01-01');
    });

    test('softDelete listeden çıkarır', () async {
      final store = WhmsLocationStore(openDb: () async => db);
      final created = await store.upsert(
        const WhmsLocation(
          id: '',
          warehouseCode: 'MRK',
          code: 'Z-99-01',
          barcode: 'LOC-Z',
          routeSeq: 99,
        ),
      );
      expect(created.id, isNotEmpty);

      var rows = await store.listActive(warehouseCode: 'MRK');
      expect(rows.any((r) => r.id == created.id), isTrue);

      await store.softDelete(created.id);
      rows = await store.listActive(warehouseCode: 'MRK');
      expect(rows.any((r) => r.id == created.id), isFalse);
    });

    test('boş code → ArgumentError', () async {
      final store = WhmsLocationStore(openDb: () async => db);
      expect(
        () => store.upsert(
          const WhmsLocation(
            id: 'x',
            warehouseCode: 'MRK',
            code: '',
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
