// Dosya Adı: whms_labels_store_test.dart
// Açıklama: Paket tipi / dara / etiket şablon model + store testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/whms/labels/model/whms_label_template.dart';
import 'package:exfin_ops/modules/whms/labels/model/whms_package_type.dart';
import 'package:exfin_ops/modules/whms/labels/model/whms_tare.dart';
import 'package:exfin_ops/modules/whms/labels/viewmodel/whms_label_template_store.dart';
import 'package:exfin_ops/modules/whms/labels/viewmodel/whms_package_type_store.dart';
import 'package:exfin_ops/modules/whms/labels/viewmodel/whms_tare_store.dart';
import 'package:exfin_ops/modules/whms/contract/whms_route_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WhmsPackageType', () {
    test('toMap/fromMap round-trip', () {
      const row = WhmsPackageType(
        id: 'p1',
        code: 'KOLI',
        name: 'Koli',
        tareRef: 'PALET',
        afterSalesFlag: true,
      );
      final round = WhmsPackageType.fromMap(row.toMap());
      expect(round.code, 'KOLI');
      expect(round.tareRef, 'PALET');
      expect(round.afterSalesFlag, isTrue);
    });
  });

  group('WhmsTare', () {
    test('toMap/fromMap weight', () {
      const row = WhmsTare(
        id: 't1',
        code: 'PALET',
        name: 'Palet',
        weight: 25.5,
      );
      final round = WhmsTare.fromMap(row.toMap());
      expect(round.weight, 25.5);
    });
  });

  group('WhmsLabelTemplate', () {
    test('printLabelType shelf_large', () {
      const t = WhmsLabelTemplate(
        id: '1',
        code: 'RAF80',
        name: 'Raf',
        labelType: WhmsLabelTemplate.typeShelfLarge,
      );
      expect(t.printLabelType, WhmsLabelTemplate.typeShelfLarge);
    });
  });

  group('route separation', () {
    test('labels ≠ devices', () {
      expect(WhmsRouteMap.whmsLabels, '/whms/labels');
      expect(WhmsRouteMap.whmsDevices, '/whms/devices');
      expect(WhmsRouteMap.whmsLabels, isNot(WhmsRouteMap.whmsDevices));
      expect(WhmsRouteMap.fsWhmsMenuSeed['sub_whms_labels'], '/whms/labels');
      expect(WhmsRouteMap.fsWhmsMenuSeed['sub_whms_devices'], '/whms/devices');
      expect(WhmsRouteMap.fsWhmsMenuSeed['sub_whms_orders'], '/whms/orders-hub');
    });
  });

  group('stores (in-memory)', () {
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

    test('package type upsert + softDelete', () async {
      final store = WhmsPackageTypeStore(openDb: () async => db);
      await store.upsert(
        const WhmsPackageType(id: '', code: 'KOLI', name: 'Koli'),
      );
      expect(await store.listActive(), hasLength(1));
      final id = (await store.listActive()).first.id;
      await store.softDelete(id);
      expect(await store.listActive(), isEmpty);
    });

    test('tare upsert weight', () async {
      final store = WhmsTareStore(openDb: () async => db);
      await store.upsert(
        const WhmsTare(
          id: '',
          code: 'PALET',
          name: 'Palet',
          weight: 12,
        ),
      );
      final rows = await store.listActive();
      expect(rows.first.weight, 12);
    });

    test('label template seedDefaultsIfEmpty', () async {
      final store = WhmsLabelTemplateStore(openDb: () async => db);
      await store.seedDefaultsIfEmpty();
      final rows = await store.listActive();
      expect(rows, hasLength(2));
      await store.seedDefaultsIfEmpty();
      expect(await store.listActive(), hasLength(2));
    });
  });
}
