// Dosya Adı: whms_fifo_rule_store_test.dart
// Açıklama: WhmsFifoRule store CRUD + engine fromMap uyumu testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/whms/engine/whms_fifo_models.dart';
import 'package:exfin_ops/modules/whms/engine/whms_fifo_rule_engine.dart';
import 'package:exfin_ops/modules/whms/fifo/viewmodel/whms_fifo_rule_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WhmsFifoRule persist', () {
    test('toMap/fromMap round-trip + id', () {
      const rule = WhmsFifoRule(
        id: 'r1',
        productCode: 'SKU1',
        fifoDays: 30,
        fefoEnforce: true,
        warnDays: 7,
      );
      final round = WhmsFifoRule.fromMap(rule.toMap());
      expect(round.id, 'r1');
      expect(round.productCode, 'SKU1');
      expect(round.fifoDays, 30);
      expect(round.fefoEnforce, isTrue);
      expect(round.warnDays, 7);
      expect(round.isActive, isTrue);
      expect(round.isDeleted, isFalse);
    });
  });

  group('WhmsFifoRuleStore', () {
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

    test('upsert + listActive + findByProductCode → engine', () async {
      final store = WhmsFifoRuleStore(openDb: () async => db);
      await store.ensureReady();

      await store.upsert(
        const WhmsFifoRule(
          id: 'f1',
          productCode: 'SKU-A',
          fifoDays: 14,
          fefoEnforce: true,
          warnDays: 5,
        ),
      );
      await store.upsert(
        const WhmsFifoRule(
          id: 'f2',
          productCode: 'SKU-B',
          fifoDays: 0,
          fefoEnforce: false,
          warnDays: 0,
        ),
      );

      final all = await store.listActive();
      expect(all, hasLength(2));

      final fefoOnly = await store.listActive(fefoEnforceOnly: true);
      expect(fefoOnly, hasLength(1));
      expect(fefoOnly.first.productCode, 'SKU-A');

      final found = await store.findByProductCode('SKU-A');
      expect(found, isNotNull);

      final check = WhmsFifoRuleEngine.checkOutbound(
        productCode: 'SKU-A',
        proposedExpiry: DateTime(2026, 8, 5),
        today: DateTime(2026, 7, 28),
        rule: found!,
      );
      // 8 gün kalan < fifo_days 14 → block
      expect(check.isBlocked, isTrue);
      expect(check.messageKey, WhmsFifoMessageKeys.blockFifoDays);
    });

    test('softDelete listeden ve query’den çıkarır', () async {
      final store = WhmsFifoRuleStore(openDb: () async => db);
      final created = await store.upsert(
        const WhmsFifoRule(
          id: '',
          productCode: 'SKU-DEL',
          fifoDays: 10,
        ),
      );
      expect(created.id, isNotEmpty);

      var found = await WhmsFifoRuleStore.queryByProductCode(
        db,
        productCode: 'SKU-DEL',
      );
      expect(found, isNotNull);

      await store.softDelete(created.id);
      final rows = await store.listActive();
      expect(rows.any((r) => r.id == created.id), isFalse);

      found = await WhmsFifoRuleStore.queryByProductCode(
        db,
        productCode: 'SKU-DEL',
      );
      expect(found, isNull);
    });

    test('boş product_code → ArgumentError', () async {
      final store = WhmsFifoRuleStore(openDb: () async => db);
      expect(
        () => store.upsert(
          const WhmsFifoRule(id: 'x', productCode: ''),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
