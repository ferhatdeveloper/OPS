// Dosya Adı: compare_matrix_repository_test.dart
// Açıklama: Esnek matris repository unit test
// Oluşturulma Tarihi: 2026-08-04
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-04

import 'package:exfin_ops/modules/manager/reports/model/compare_matrix_models.dart';
import 'package:exfin_ops/modules/manager/reports/model/period_comparison_models.dart';
import 'package:exfin_ops/modules/manager/reports/viewmodel/compare_matrix_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE invoices (
            id TEXT PRIMARY KEY,
            customer_id TEXT,
            invoice_date TEXT,
            created_at TEXT,
            total_amount REAL,
            status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE invoice_items (
            id TEXT PRIMARY KEY,
            invoice_id TEXT,
            product_id TEXT,
            total_amount REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            name TEXT,
            category TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            name TEXT,
            il TEXT,
            card_role TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            order_date TEXT,
            created_at TEXT,
            status TEXT,
            customer_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE collections (
            id TEXT PRIMARY KEY,
            collection_date TEXT,
            created_at TEXT,
            amount REAL,
            status TEXT,
            customer_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE visits (
            id TEXT PRIMARY KEY,
            check_in_at TEXT,
            created_at TEXT,
            customer_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE targets (
            id TEXT PRIMARY KEY,
            period TEXT,
            target_amount REAL,
            achieved_amount REAL
          )
        ''');
      },
    );

    await db.insert('customers', {
      'id': 'c1',
      'name': 'Musteri 1',
      'il': 'Istanbul',
      'card_role': 'customer',
    });
    await db.insert('products', {
      'id': 'p1',
      'name': 'Urun A',
      'category': 'Kola',
    });
    await db.insert('products', {
      'id': 'p2',
      'name': 'Urun B',
      'category': 'Su',
    });
    await db.insert('invoices', {
      'id': 'i1',
      'customer_id': 'c1',
      'invoice_date': '2026-07-10',
      'created_at': '2026-07-10',
      'total_amount': 300,
      'status': 'Posted',
    });
    await db.insert('invoices', {
      'id': 'i2',
      'customer_id': 'c1',
      'invoice_date': '2026-06-10',
      'created_at': '2026-06-10',
      'total_amount': 100,
      'status': 'Posted',
    });
    await db.insert('invoice_items', {
      'id': 'li1',
      'invoice_id': 'i1',
      'product_id': 'p1',
      'total_amount': 200,
    });
    await db.insert('invoice_items', {
      'id': 'li2',
      'invoice_id': 'i1',
      'product_id': 'p2',
      'total_amount': 100,
    });
    await db.insert('invoice_items', {
      'id': 'li3',
      'invoice_id': 'i2',
      'product_id': 'p1',
      'total_amount': 100,
    });
    await db.insert('orders', {
      'id': 'o1',
      'order_date': '2026-07-05',
      'created_at': '2026-07-05',
      'status': 'Open',
      'customer_id': 'c1',
    });
    await db.insert('collections', {
      'id': 'col1',
      'collection_date': '2026-07-12',
      'created_at': '2026-07-12',
      'amount': 50,
      'status': 'Posted',
      'customer_id': 'c1',
    });
    await db.insert('visits', {
      'id': 'v1',
      'check_in_at': '2026-07-01',
      'created_at': '2026-07-01',
      'customer_id': 'c1',
    });
    await db.insert('targets', {
      'id': 't1',
      'period': '2026-07',
      'target_amount': 400,
      'achieved_amount': 200,
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('periodOverview returns summary metrics and 2 cols', () async {
    const repo = CompareMatrixRepository();
    final query = ComparisonWizardState.fromTemplate(
      CompareTemplate.periodOverview,
      anchor: DateTime(2026, 7, 28),
    );
    final result = await repo.fetchMatrix(db, query);
    expect(result.colKeys.length, 2);
    expect(result.summaryMetrics, isNotEmpty);
    final sales = result.summaryMetrics
        .firstWhere((r) => r.kind == PeriodMetricKind.sales);
    expect(sales.periodB, 300);
    expect(sales.periodA, 100);
  });

  test('productPeriod matrix top products across periods', () async {
    const repo = CompareMatrixRepository();
    final query = ComparisonWizardState.fromTemplate(
      CompareTemplate.productPeriod,
      anchor: DateTime(2026, 7, 28),
    ).copyWith(topN: 10);
    final result = await repo.fetchMatrix(db, query);
    expect(result.rowKeys, contains('p1'));
    expect(result.colKeys.length, 2);
    // Temmuz (B) p1 = 200
    final bId = query.periods[1].id;
    expect(result.valueAt('p1', bId), 200);
    final aId = query.periods[0].id;
    expect(result.valueAt('p1', aId), 100);
  });

  test('companyPeriod with selected firm falls back without company_id',
      () async {
    const repo = CompareMatrixRepository();
    final query = ComparisonWizardState.fromTemplate(
      CompareTemplate.companyPeriod,
      anchor: DateTime(2026, 7, 28),
    ).copyWith(companyIds: const ['001']);
    final result = await repo.fetchMatrix(db, query);
    expect(result.rowKeys, ['001']);
    expect(result.colKeys.length, 2);
    final bId = query.periods[1].id;
    // company_id yok → dönem toplamı seçili satıra
    expect(result.valueAt('001', bId), 300);
  });
}
