// Dosya Adı: stock_report_query_service_test.dart
// Açıklama: STOK MBT rapor satırları — bakiye / depo / satış ranking
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/reports/stock/stock_report_filter.dart';
import 'package:exfin_ops/modules/field_sales/reports/stock/stock_report_ids.dart';
import 'package:exfin_ops/modules/field_sales/reports/stock/stock_report_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  const svc = StockReportQueryService();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createProductsTable);
        await db.execute(SqlQuerys.createWarehousesTable);
        await db.execute(SqlQuerys.createWarehouseStocksTable);
        await db.execute(SqlQuerys.createWarehouseTransfersTable);
        await db.execute(SqlQuerys.createBatchExpiryTable);
        await db.execute(SqlQuerys.createVehiclesTable);
        await db.execute(SqlQuerys.createVehicleStocksTable);
        await db.execute(SqlQuerys.createStockCountsTable);
        await db.execute(SqlQuerys.createOrdersTable);
        await db.execute(SqlQuerys.createOrderItemsTable);
        await db.execute(SqlQuerys.createInvoicesTable);
        await db.execute(SqlQuerys.createInvoiceItemsTable);
      },
    );

    await db.insert('products', {
      'id': 'p1',
      'code': 'STK-001',
      'name': 'Ürün A',
      'stock_quantity': 10,
    });
    await db.insert('products', {
      'id': 'p2',
      'code': 'STK-002',
      'name': 'Ürün B',
      'stock_quantity': 0,
    });
    await db.insert('products', {
      'id': 'p3',
      'code': 'STK-003',
      'name': 'Ürün C',
      'stock_quantity': -2,
    });
    await db.insert('warehouses', {
      'id': 'w1',
      'code': 'MRK',
      'name': 'Merkez',
      'type': 'central',
    });
    await db.insert('warehouse_stocks', {
      'warehouse_code': 'MRK',
      'product_id': 'p1',
      'quantity': 7,
    });
    await db.insert('batch_expiry', {
      'id': 'b1',
      'product_id': 'p1',
      'product_code': 'STK-001',
      'product_name': 'Ürün A',
      'lot_no': 'LOT-9',
      'expiry_date': '2027-01-01',
      'quantity': 3,
      'is_deleted': 0,
    });
    await db.insert('vehicles', {
      'id': 'v1',
      'plate': '34ABC01',
      'name': 'Van',
    });
    await db.insert('vehicle_stocks', {
      'vehicle_id': 'v1',
      'product_id': 'p1',
      'quantity': 4,
    });
    await db.insert('invoices', {
      'id': 'inv1',
      'customer_id': 'c1',
      'invoice_date': '2026-07-10',
      'total_amount': 100,
      'status': 'Completed',
      'invoice_type': 'Sales',
    });
    await db.insert('invoice_items', {
      'id': 'ii1',
      'invoice_id': 'inv1',
      'product_id': 'p1',
      'quantity': 5,
      'price': 20,
      'total_amount': 100,
    });
    await db.insert('orders', {
      'id': 'o1',
      'customer_id': 'c1',
      'order_date': '2026-07-12',
      'total_amount': 50,
      'status': 'Approved',
      'order_type': 'purchase',
    });
    await db.insert('order_items', {
      'id': 'oi1',
      'order_id': 'o1',
      'product_id': 'p2',
      'quantity': 8,
      'price': 5,
      'total_amount': 40,
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('handles tüm STOK id’leri', () {
    expect(StockReportIds.all.length, greaterThanOrEqualTo(9));
    expect(StockReportQueryService.handles('stok_bakiye'), isTrue);
    expect(StockReportQueryService.handles('cari_extre'), isFalse);
  });

  test('stok_bakiye gtZero filtreler', () async {
    final rows = await svc.fetchRows(
      db: db,
      reportId: StockReportIds.stokBakiye,
      filter: const StockReportFilter(gtZero: true),
    );
    expect(rows.any((r) => r['stock_code'] == 'STK-001'), isTrue);
    expect(rows.any((r) => r['stock_code'] == 'STK-002'), isFalse);
    expect(rows.first['balance'], isNotEmpty);
  });

  test('seri_lot lot_no döner', () async {
    final rows = await svc.fetchRows(
      db: db,
      reportId: StockReportIds.seriLot,
    );
    expect(rows, isNotEmpty);
    expect(rows.first['serial'], 'LOT-9');
  });

  test('urun_hangi_depo ambar satırı', () async {
    final rows = await svc.fetchRows(
      db: db,
      reportId: StockReportIds.urunHangiDepo,
    );
    expect(rows, isNotEmpty);
    expect(rows.first['warehouse'], contains('Merkez'));
  });

  test('en_cok_satilan_urun fatura kalemi', () async {
    final rows = await svc.fetchRows(
      db: db,
      reportId: StockReportIds.enCokSatilanUrun,
      filter: StockReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows, isNotEmpty);
    expect(rows.first['stock_code'], 'STK-001');
  });

  test('en_cok_alinan_urun purchase sipariş', () async {
    final rows = await svc.fetchRows(
      db: db,
      reportId: StockReportIds.enCokAlinanUrun,
      filter: StockReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows, isNotEmpty);
    expect(rows.first['stock_code'], 'STK-002');
  });

  test('satisi_yapilmayan_urun satılmayanları listeler', () async {
    final rows = await svc.fetchRows(
      db: db,
      reportId: StockReportIds.satisiYapilmayanUrun,
      filter: StockReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows.any((r) => r['stock_code'] == 'STK-002'), isTrue);
    expect(rows.any((r) => r['stock_code'] == 'STK-001'), isFalse);
  });

  test('ops_van_stock araç plakası', () async {
    final rows = await svc.fetchRows(
      db: db,
      reportId: StockReportIds.opsVanStock,
    );
    expect(rows, isNotEmpty);
    expect(rows.first['warehouse'], '34ABC01');
    expect(rows.first['balance'], '4');
  });
}
