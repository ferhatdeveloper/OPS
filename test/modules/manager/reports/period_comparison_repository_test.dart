// Dosya Adı: period_comparison_repository_test.dart
// Açıklama: Dönem karşılaştırma SQLite repository unit test
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:exfin_ops/modules/manager/reports/model/period_comparison_models.dart';
import 'package:exfin_ops/modules/manager/reports/viewmodel/period_comparison_repository.dart';
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
            invoice_date TEXT,
            created_at TEXT,
            total_amount REAL,
            status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            order_date TEXT,
            created_at TEXT,
            status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE collections (
            id TEXT PRIMARY KEY,
            collection_date TEXT,
            created_at TEXT,
            amount REAL,
            status TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE visits (
            id TEXT PRIMARY KEY,
            check_in_at TEXT,
            created_at TEXT
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

    await db.insert('invoices', {
      'id': 'i1',
      'invoice_date': '2026-07-10',
      'created_at': '2026-07-10',
      'total_amount': 200,
      'status': 'Posted',
    });
    await db.insert('invoices', {
      'id': 'i2',
      'invoice_date': '2026-06-10',
      'created_at': '2026-06-10',
      'total_amount': 100,
      'status': 'Posted',
    });
    await db.insert('orders', {
      'id': 'o1',
      'order_date': '2026-07-05',
      'created_at': '2026-07-05',
      'status': 'Open',
    });
    await db.insert('orders', {
      'id': 'o2',
      'order_date': '2026-06-05',
      'created_at': '2026-06-05',
      'status': 'Open',
    });
    await db.insert('orders', {
      'id': 'o3',
      'order_date': '2026-06-08',
      'created_at': '2026-06-08',
      'status': 'Open',
    });
    await db.insert('collections', {
      'id': 'c1',
      'collection_date': '2026-07-12',
      'created_at': '2026-07-12',
      'amount': 50,
      'status': 'Posted',
    });
    await db.insert('visits', {
      'id': 'v1',
      'check_in_at': '2026-07-01',
      'created_at': '2026-07-01',
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

  test('thisMonthVsLast metrikleri satış/sipariş/tahsilat/ziyaret/hedef', () async {
    const repo = PeriodComparisonRepository();
    final result = await repo.fetch(
      db,
      preset: PeriodComparePreset.thisMonthVsLast,
      anchor: DateTime(2026, 7, 28),
    );

    final byKind = {for (final r in result.rows) r.kind: r};
    expect(byKind[PeriodMetricKind.sales]!.periodA, 100);
    expect(byKind[PeriodMetricKind.sales]!.periodB, 200);
    expect(byKind[PeriodMetricKind.orderCount]!.periodA, 2);
    expect(byKind[PeriodMetricKind.orderCount]!.periodB, 1);
    expect(byKind[PeriodMetricKind.collection]!.periodB, 50);
    expect(byKind[PeriodMetricKind.visit]!.periodB, 1);
    expect(byKind[PeriodMetricKind.targetAchievement]!.periodB, 50);
  });
}
