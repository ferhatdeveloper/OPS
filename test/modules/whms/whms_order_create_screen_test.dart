// Dosya Adı: whms_order_create_screen_test.dart
// Açıklama: WHMS emir oluştur — createDraft header taslak birim testi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/whms/contract/whms_bridge_dto.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_status.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_type.dart';
import 'package:exfin_ops/modules/whms/viewmodel/whms_order_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late WhmsOrderStore store;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createWhmsOrdersTable);
        await db.execute(SqlQuerys.createWhmsOrderLinesTable);
      },
    );
    store = WhmsOrderStore(openDb: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  test('createDraft mal_kabul satırsız → draft ONAY=0', () async {
    final created = await store.createDraft(
      orderType: WhmsOrderType.malKabul,
      warehouseCode: 'MRK',
      notes: 'test',
      referenceNo: 'REF-1',
      orderDate: '2026-07-28',
    );
    expect(created.status, WhmsOrderStatus.draft);
    expect(created.approval, WhmsApprovalStatus.pending);
    expect(created.lines, isEmpty);
    expect(created.notes, 'test');
    expect(created.referenceNo, 'REF-1');
  });
}
