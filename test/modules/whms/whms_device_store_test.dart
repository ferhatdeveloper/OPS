// Dosya Adı: whms_device_store_test.dart
// Açıklama: WhmsDeviceStore CRUD + MAC normalize / unique testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/whms/devices/model/whms_device.dart';
import 'package:exfin_ops/modules/whms/devices/viewmodel/whms_device_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WhmsDeviceStore.normalizeMac', () {
    test('strip + upper + colon format', () {
      expect(
        WhmsDeviceStore.normalizeMac('aa-bb-cc-dd-ee-ff'),
        'AA:BB:CC:DD:EE:FF',
      );
      expect(
        WhmsDeviceStore.normalizeMac('AABBCCDDEEFF'),
        'AA:BB:CC:DD:EE:FF',
      );
      expect(WhmsDeviceStore.normalizeMac('  '), isNull);
      expect(WhmsDeviceStore.normalizeMac(null), isNull);
    });
  });

  group('WhmsDeviceStore', () {
    late Database db;
    late WhmsDeviceStore store;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {},
      );
      store = WhmsDeviceStore(openDb: () async => db);
    });

    tearDown(() async {
      await db.close();
    });

    test('insert + getById + findByMac + listActive', () async {
      final row = await store.insert(
        name: 'RF-1',
        mac: 'aa:bb:cc:dd:ee:ff',
        model: 'Zebra',
        osName: 'Android',
        roles: const ['pick', 'sevk'],
        defaultWarehouseCode: 'MRK',
      );
      expect(row.mac, 'AA:BB:CC:DD:EE:FF');
      expect(row.roles, ['pick', 'sevk']);
      expect(row.defaultWarehouseCode, 'MRK');

      final byId = await store.getById(row.id);
      expect(byId?.name, 'RF-1');

      final byMac = await store.findByMac('AA-BB-CC-DD-EE-FF');
      expect(byMac?.id, row.id);

      final active = await store.listActive();
      expect(active.map((e) => e.id), [row.id]);
    });

    test('duplicate MAC throws', () async {
      await store.insert(name: 'A', mac: '11:22:33:44:55:66');
      expect(
        () => store.insert(name: 'B', mac: '112233445566'),
        throwsA(isA<StateError>()),
      );
    });

    test('setActive + softDelete hide from listActive', () async {
      final row = await store.insert(
        name: 'T1',
        mac: 'AA:AA:AA:AA:AA:01',
      );
      await store.setActive(row.id, false);
      expect(await store.listActive(), isEmpty);
      final inactive = await store.getById(row.id);
      expect(inactive?.isActive, isFalse);

      await store.setActive(row.id, true);
      expect(await store.listActive(), hasLength(1));

      await store.softDelete(row.id);
      expect(await store.getById(row.id), isNull);
      expect(await store.findByMac('AA:AA:AA:AA:AA:01'), isNull);
    });

    test('upsert updates roles and warehouse', () async {
      final created = await store.insert(name: 'U1');
      final updated = await store.upsert(
        created.copyWith(
          roles: const ['mal_kabul'],
          defaultWarehouseCode: 'ARC',
          mac: 'BB:BB:BB:BB:BB:02',
        ),
      );
      expect(updated.roles, ['mal_kabul']);
      expect(updated.defaultWarehouseCode, 'ARC');
      expect(updated.mac, 'BB:BB:BB:BB:BB:02');
    });
  });
}
