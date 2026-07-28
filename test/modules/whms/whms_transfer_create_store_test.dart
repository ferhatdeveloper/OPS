// Dosya Adı: whms_transfer_create_store_test.dart
// Açıklama: Transfer draft + ürün satırları SQLite persist testi
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

  test('transfer draft persists product lines + lot', () async {
    final created = await store.createDraft(
      orderType: WhmsOrderType.transfer,
      fromWarehouseCode: 'MRK',
      toWarehouseCode: 'IAD',
      warehouseCode: 'MRK',
      orderDate: '2026-07-28',
      lines: const [
        WhmsOrderLineDto(
          id: 'ln_t1',
          orderId: 'tmp',
          lineNo: 1,
          productId: 'p1',
          productCode: 'SKU-T1',
          productName: 'Transfer Ürün',
          quantity: 3,
          unitName: 'ADET',
          lotNo: 'LOT-A',
        ),
        WhmsOrderLineDto(
          id: 'ln_t2',
          orderId: 'tmp',
          lineNo: 2,
          productId: 'p2',
          productCode: 'SKU-T2',
          quantity: 1.5,
        ),
      ],
    );

    expect(created.orderType, WhmsOrderType.transfer);
    expect(created.status, WhmsOrderStatus.draft);
    expect(created.fromWarehouseCode, 'MRK');
    expect(created.toWarehouseCode, 'IAD');
    expect(created.lines, hasLength(2));
    expect(created.lines.first.productCode, 'SKU-T1');
    expect(created.lines.first.lotNo, 'LOT-A');
    expect(created.lines.first.quantity, 3);
    expect(created.lines.last.quantity, 1.5);

    final dto = created.toTransferDto();
    expect(dto, isNotNull);
    expect(dto!.lines, hasLength(2));
    expect(dto.lines.first.productCode, 'SKU-T1');

    await store.setApproval(created.id, WhmsApprovalStatus.approved);
    final approved = await store.getById(created.id);
    expect(approved?.approval, WhmsApprovalStatus.approved);
    expect(approved?.toTransferDto()?.approval, WhmsApprovalStatus.approved);
  });
}
