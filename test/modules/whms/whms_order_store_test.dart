// Dosya Adı: whms_order_store_test.dart
// Açıklama: WHMS emir store SQLite birim testleri
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/whms/contract/whms_bridge_dto.dart';
import 'package:exfin_ops/modules/whms/model/whms_order_line_dto.dart';
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

  test('create draft + list + approval', () async {
    final created = await store.createDraft(
      orderType: WhmsOrderType.malKabul,
      warehouseCode: 'MRK',
      orderDate: '2026-07-28',
      lines: [
        WhmsOrderLineDto(
          id: 'ln1',
          orderId: 'tmp',
          lineNo: 1,
          productId: 'p1',
          productCode: 'SKU1',
          quantity: 5,
          locationCode: 'A-01',
        ),
      ],
    );
    expect(created.status, WhmsOrderStatus.draft);

    final listed = await store.list();
    expect(listed, hasLength(1));
    expect(listed.first.lines, hasLength(1));

    await store.setApproval(created.id, WhmsApprovalStatus.approved);
    final got = await store.getById(created.id);
    expect(got?.approval, WhmsApprovalStatus.approved);
  });

  test('mal_kabul without location throws', () async {
    expect(
      () => store.createDraft(
        orderType: WhmsOrderType.malKabul,
        warehouseCode: 'MRK',
        orderDate: '2026-07-28',
        lines: const [
          WhmsOrderLineDto(
            id: 'ln1',
            orderId: 'tmp',
            lineNo: 1,
            productId: 'p1',
            quantity: 1,
          ),
        ],
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('confirmReceiptPutaway sets ONAY + done', () async {
    final created = await store.createDraft(
      orderType: WhmsOrderType.malKabul,
      warehouseCode: 'MRK',
      orderDate: '2026-07-28',
      lines: [
        WhmsOrderLineDto(
          id: 'ln1',
          orderId: 'tmp',
          lineNo: 1,
          productId: 'p1',
          productCode: 'SKU1',
          quantity: 10,
          locationCode: 'A-01',
        ),
      ],
    );

    final done = await store.confirmReceiptPutaway(
      orderId: created.id,
      lines: [
        created.lines.first.copyWith(
          locationCode: 'B-02',
          quantityDone: 10,
        ),
      ],
    );
    expect(done.status, WhmsOrderStatus.done);
    expect(done.approval, WhmsApprovalStatus.approved);
    expect(done.lines.first.locationCode, 'B-02');
    expect(done.lines.first.quantityDone, 10);
    expect(done.completedAt, isNotNull);
  });

  test('confirmReceiptPutaway without location throws', () async {
    final created = await store.createDraft(
      orderType: WhmsOrderType.putaway,
      warehouseCode: 'MRK',
      orderDate: '2026-07-28',
      lines: [
        WhmsOrderLineDto(
          id: 'ln1',
          orderId: 'tmp',
          lineNo: 1,
          productId: 'p1',
          quantity: 3,
          locationCode: 'A-01',
        ),
      ],
    );
    expect(
      () => store.confirmReceiptPutaway(
        orderId: created.id,
        lines: [
          created.lines.first.copyWith(locationCode: '  '),
        ],
      ),
      throwsA(isA<StateError>()),
    );
  });
}
