// Dosya Adı: cari_report_query_service_test.dart
// Açıklama: CARİ rapor SQLite satır → ReportLayout map birim testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/reports/cari/cari_report_filter.dart';
import 'package:exfin_ops/modules/field_sales/reports/cari/cari_report_ids.dart';
import 'package:exfin_ops/modules/field_sales/reports/cari/cari_report_query_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Database> openDb() async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute(SqlQuerys.createCustomersTable);
    await db.execute(SqlQuerys.createInvoicesTable);
    await db.execute(SqlQuerys.createCollectionsTable);
    await db.execute(SqlQuerys.createInvoiceItemsTable);
    await db.execute(SqlQuerys.createOrdersTable);
    await db.execute(SqlQuerys.createOrderItemsTable);
    await db.execute(SqlQuerys.createProductsTable);
    return db;
  }

  test('handles 14+ cari id', () {
    expect(CariReportIds.handles('cari_extre'), isTrue);
    expect(CariReportIds.handles('cari_risk'), isTrue);
    expect(CariReportIds.handles('stok_bakiye'), isFalse);
  });

  test('borc_alacak / cari_risk layout sütunları', () async {
    final db = await openDb();
    await db.insert('customers', {
      'id': 'c1',
      'code': 'C-001',
      'name': 'Test Cari',
      'balance': 150.5,
      'is_active': 1,
    });
    final svc = const CariReportQueryService();
    final rows = await svc.fetchRows(
      db: db,
      reportId: CariReportIds.borcAlacak,
    );
    expect(rows, hasLength(1));
    expect(rows.first['code'], 'C-001');
    expect(rows.first['debit'], '150.50');
    expect(rows.first['balance'], '150.50');

    final risk = await svc.fetchRows(
      db: db,
      reportId: CariReportIds.cariRisk,
    );
    expect(risk, hasLength(1));
    await db.close();
  });

  test('cari_extre fatura+tahsilat bakiye', () async {
    final db = await openDb();
    await db.insert('customers', {
      'id': 'c1',
      'code': 'C-001',
      'name': 'Test',
      'balance': 0,
      'is_active': 1,
    });
    await db.insert('invoices', {
      'id': 'i1',
      'customer_id': 'c1',
      'invoice_date': '2026-07-01',
      'total_amount': 100,
      'status': 'Completed',
      'invoice_type': 'Sales',
    });
    await db.insert('collections', {
      'id': 'col1',
      'customer_id': 'c1',
      'collection_date': '2026-07-02',
      'amount': 40,
      'payment_type': 'Cash',
      'status': 'Completed',
    });
    final rows = await const CariReportQueryService().fetchRows(
      db: db,
      reportId: CariReportIds.cariExtre,
      filter: CariReportFilter(
        dateFrom: DateTime(2026, 1, 1),
        dateTo: DateTime(2026, 12, 31),
        code: 'C-001',
      ),
    );
    expect(rows.length, 2);
    expect(rows.last['balance'], '60.00');
    await db.close();
  });

  test('musteri_senet Note payment_type', () async {
    final db = await openDb();
    await db.insert('customers', {
      'id': 'c1',
      'code': 'C-1',
      'name': 'A',
      'is_active': 1,
    });
    await db.insert('collections', {
      'id': 'n1',
      'customer_id': 'c1',
      'collection_date': '2026-07-10',
      'amount': 200,
      'payment_type': 'Note',
      'check_number': 'SN-9',
      'due_date': '2026-08-01',
      'status': 'Pending',
    });
    final rows = await const CariReportQueryService().fetchRows(
      db: db,
      reportId: CariReportIds.musteriSenet,
      filter: CariReportFilter(
        dateFrom: DateTime(2026, 1, 1),
        dateTo: DateTime(2026, 12, 31),
      ),
    );
    expect(rows, hasLength(1));
    expect(rows.first['doc_no'], 'SN-9');
    await db.close();
  });

  test('yakinimdaki_cari_gps haversine mesafe', () async {
    final db = await openDb();
    await db.insert('customers', {
      'id': 'c1',
      'code': 'NEAR',
      'name': 'Yakin',
      'latitude': 41.01,
      'longitude': 28.97,
      'is_active': 1,
    });
    await db.insert('customers', {
      'id': 'c2',
      'code': 'FAR',
      'name': 'Uzak',
      'latitude': 40.0,
      'longitude': 29.0,
      'is_active': 1,
    });
    final rows = await const CariReportQueryService().fetchRows(
      db: db,
      reportId: CariReportIds.yakinimdakiCariGps,
      filter: const CariReportFilter(
        originLat: 41.01,
        originLng: 28.97,
        maxDistanceMeters: 5000,
      ),
    );
    expect(rows, hasLength(1));
    expect(rows.first['code'], 'NEAR');
    expect(rows.first['distance'], isNotEmpty);
    await db.close();
  });
}
