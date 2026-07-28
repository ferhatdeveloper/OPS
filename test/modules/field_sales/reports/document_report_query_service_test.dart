// Dosya Adı: document_report_query_service_test.dart
// Açıklama: SİPARİŞ/FATURA/İRSALİYE belge rapor SQLite satır testleri
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/reports/documents/document_report_filter.dart';
import 'package:exfin_ops/modules/field_sales/reports/documents/document_report_ids.dart';
import 'package:exfin_ops/modules/field_sales/reports/documents/document_report_query_service.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/mbt_report_catalog.dart';
import 'package:exfin_ops/modules/field_sales/reports/model/report_layout_defaults.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  const svc = DocumentReportQueryService();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createCustomersTable);
        await db.execute(SqlQuerys.createProductsTable);
        await db.execute(SqlQuerys.createOrdersTable);
        await db.execute(SqlQuerys.createOrderItemsTable);
        await db.execute(SqlQuerys.createInvoicesTable);
        await db.execute(SqlQuerys.createInvoiceItemsTable);
        await db.execute(SqlQuerys.createWaybillsTable);
        await db.execute(SqlQuerys.createWaybillItemsTable);
      },
    );

    await db.insert('customers', {
      'id': 'c1',
      'code': 'C001',
      'name': 'Alpha Market',
    });
    await db.insert('customers', {
      'id': 'c2',
      'code': 'C002',
      'name': 'Beta Tedarik',
    });
    await db.insert('products', {
      'id': 'p1',
      'code': 'STK-01',
      'name': 'Ürün A',
      'price': 10,
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('DocumentReportIds 11 belge raporunu kapsar', () {
    expect(DocumentReportIds.all, hasLength(11));
    for (final id in DocumentReportIds.all) {
      expect(MbtReportCatalog.byId(id), isNotNull, reason: id);
      expect(DocumentReportIds.handles(id), isTrue);
      final layout = ReportLayoutDefaults.forReportId(id);
      expect(layout.columns, isNotEmpty, reason: id);
    }
  });

  test('satış siparişleri tarih + tip filtreler', () async {
    await db.insert('orders', {
      'id': 'o-sale',
      'customer_id': 'c1',
      'order_date': '2026-07-20T10:00:00.000',
      'total_amount': 100,
      'status': 'Approved',
      'order_type': 'sales',
      'approval_status': 1,
    });
    await db.insert('orders', {
      'id': 'o-buy',
      'customer_id': 'c2',
      'order_date': '2026-07-20T10:00:00.000',
      'total_amount': 50,
      'status': 'Approved',
      'order_type': 'purchase',
      'approval_status': 1,
    });
    await db.insert('orders', {
      'id': 'o-old',
      'customer_id': 'c1',
      'order_date': '2026-01-01T10:00:00.000',
      'total_amount': 10,
      'status': 'Approved',
      'order_type': 'sales',
      'approval_status': 1,
    });

    final sales = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.satisSiparisleri,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(sales, hasLength(1));
    expect(sales.first['doc_no'], 'o-sale');
    expect(sales.first['code'], 'C001');
    expect(sales.first['amount'], '100.00');

    final purchase = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.alisSiparisleri,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(purchase, hasLength(1));
    expect(purchase.first['doc_no'], 'o-buy');
  });

  test('bekleyen satış siparişleri ONAY/Pending', () async {
    await db.insert('orders', {
      'id': 'o-pend',
      'customer_id': 'c1',
      'order_date': '2026-07-15T10:00:00.000',
      'total_amount': 80,
      'status': 'Pending',
      'order_type': 'sales',
      'approval_status': 0,
    });
    await db.insert('orders', {
      'id': 'o-ok',
      'customer_id': 'c1',
      'order_date': '2026-07-15T10:00:00.000',
      'total_amount': 90,
      'status': 'Approved',
      'order_type': 'sales',
      'approval_status': 1,
    });

    final rows = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.bekleyenSatisSiparis,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows, hasLength(1));
    expect(rows.first['doc_no'], 'o-pend');
    expect(rows.first['status'], 'Pending');
  });

  test('bekleyen sipariş stok kodu EXISTS filtresi', () async {
    await db.insert('orders', {
      'id': 'o-stk',
      'customer_id': 'c1',
      'order_date': '2026-07-10T10:00:00.000',
      'total_amount': 40,
      'status': 'Pending',
      'order_type': 'sales',
      'approval_status': 0,
    });
    await db.insert('order_items', {
      'id': 'oi1',
      'order_id': 'o-stk',
      'product_id': 'p1',
      'quantity': 2,
      'price': 20,
      'total_amount': 40,
    });
    await db.insert('orders', {
      'id': 'o-other',
      'customer_id': 'c1',
      'order_date': '2026-07-10T10:00:00.000',
      'total_amount': 5,
      'status': 'Pending',
      'order_type': 'sales',
      'approval_status': 0,
    });

    final rows = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.bekleyenSatisSiparis,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
        stockCode: 'STK-01',
      ),
    );
    expect(rows, hasLength(1));
    expect(rows.first['doc_no'], 'o-stk');
  });

  test('satış/alış faturaları Logo tip ayrımı', () async {
    await db.insert('invoices', {
      'id': 'inv-s',
      'customer_id': 'c1',
      'invoice_date': '2026-07-18T10:00:00.000',
      'total_amount': 200,
      'status': 'Completed',
      'invoice_type': 'Sales',
    });
    await db.insert('invoices', {
      'id': 'inv-p',
      'customer_id': 'c2',
      'invoice_date': '2026-07-18T10:00:00.000',
      'total_amount': 120,
      'status': 'Completed',
      'invoice_type': 'purchase',
    });

    final sales = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.satisFaturalari,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(sales.map((e) => e['doc_no']), contains('inv-s'));
    expect(sales.map((e) => e['doc_no']), isNot(contains('inv-p')));

    final purchase = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.alisFaturalari,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(purchase, hasLength(1));
    expect(purchase.first['doc_no'], 'inv-p');
  });

  test('fatura karlılık profit sütunu üretir', () async {
    await db.insert('invoices', {
      'id': 'inv-k',
      'customer_id': 'c1',
      'invoice_date': '2026-07-19T10:00:00.000',
      'total_amount': 100,
      'status': 'Completed',
      'invoice_type': 'Sales',
    });
    await db.insert('invoice_items', {
      'id': 'ii1',
      'invoice_id': 'inv-k',
      'product_id': 'p1',
      'quantity': 10,
      'price': 10,
      'total_amount': 100,
    });

    final rows = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.faturaKarlilik,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows, hasLength(1));
    expect(rows.first['amount'], '100.00');
    expect(rows.first.containsKey('profit'), isTrue);
    // line_base 100 * 0.85 = 85 → profit 15
    expect(rows.first['profit'], '15.00');
  });

  test('faturasız irsaliye — invoice_id dolu ve geçerli fatura hariç', () async {
    await db.insert('waybills', {
      'id': 'wb-linked',
      'customer_id': 'c1',
      'waybill_date': '2026-07-24T10:00:00.000',
      'waybill_type': 'waybill_wholesale',
      'total_amount': 90,
      'status': 'Completed',
      'invoice_id': 'inv-linked',
    });
    await db.insert('invoices', {
      'id': 'inv-linked',
      'customer_id': 'c1',
      'invoice_date': '2026-07-24T12:00:00.000',
      'total_amount': 90,
      'status': 'Completed',
      'invoice_type': 'Sales',
    });

    final rows = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.faturasizIrsaliyeSatis,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows.map((e) => e['doc_no']), isNot(contains('wb-linked')));
  });

  test('faturasız irsaliye — aynı gün fatura yoksa dahil', () async {
    await db.insert('waybills', {
      'id': 'wb1',
      'customer_id': 'c1',
      'waybill_date': '2026-07-21T10:00:00.000',
      'waybill_type': 'waybill_wholesale',
      'total_amount': 75,
      'status': 'Completed',
    });
    await db.insert('waybills', {
      'id': 'wb2',
      'customer_id': 'c1',
      'waybill_date': '2026-07-22T10:00:00.000',
      'waybill_type': 'waybill_wholesale',
      'total_amount': 60,
      'status': 'Completed',
    });
    await db.insert('invoices', {
      'id': 'inv-match',
      'customer_id': 'c1',
      'invoice_date': '2026-07-22T12:00:00.000',
      'total_amount': 60,
      'status': 'Completed',
      'invoice_type': 'Sales',
    });

    final rows = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.faturasizIrsaliyeSatis,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows.map((e) => e['doc_no']), contains('wb1'));
    expect(rows.map((e) => e['doc_no']), isNot(contains('wb2')));
  });

  test('alış irsaliyeleri waybill_purchase', () async {
    await db.insert('waybills', {
      'id': 'wb-p',
      'customer_id': 'c2',
      'waybill_date': '2026-07-23T10:00:00.000',
      'waybill_type': 'waybill_purchase',
      'total_amount': 33,
      'status': 'Completed',
    });
    await db.insert('waybills', {
      'id': 'wb-s',
      'customer_id': 'c1',
      'waybill_date': '2026-07-23T10:00:00.000',
      'waybill_type': 'waybill_wholesale',
      'total_amount': 44,
      'status': 'Completed',
    });

    final rows = await svc.fetchRows(
      db: db,
      reportId: DocumentReportIds.alisIrsaliyeleri,
      filter: DocumentReportFilter(
        dateFrom: DateTime(2026, 7, 1),
        dateTo: DateTime(2026, 7, 31),
      ),
    );
    expect(rows, hasLength(1));
    expect(rows.first['doc_no'], 'wb-p');
  });
}
