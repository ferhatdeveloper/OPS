// Dosya Adı: admin_kpi_repository_test.dart
// Açıklama: Yönetici KPI SQLite COUNT/SUM aggregate birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/model/admin_kpi_summary.dart';
import 'package:exfin_ops/modules/field_sales/yonetici/viewmodel/admin_kpi_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  const repo = AdminKpiRepository();
  final day = DateTime(2026, 7, 26);

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createOrdersTable);
        await db.execute(SqlQuerys.createInvoicesTable);
        await db.execute(SqlQuerys.createCollectionsTable);
        await db.execute(SqlQuerys.createVisitsTable);
        await db.execute(SqlQuerys.createCustomersTable);
        await db.execute(SqlQuerys.createWaybillsTable);
        await db.execute(SqlQuerys.createBankDepositsTable);
        await db.execute(SqlQuerys.createTargetsTable);
        await db.execute(SqlQuerys.createUsersTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('AdminKpiRepository.fetchToday', () {
    test('boş tabloda sıfır döner', () async {
      final summary = await repo.fetchToday(db, day: day);
      expect(summary.orderCount, 0);
      expect(summary.invoiceCount, 0);
      expect(summary.collectionCount, 0);
      expect(summary.visitCount, 0);
      expect(summary.salesAmount, 0);
      expect(summary.sparklineSales.length, 7);
    });

    test('bugünkü kayıtları sayar; iptal ve diğer günü dışlar', () async {
      await db.insert('orders', {
        'id': 'o-today',
        'order_date': '2026-07-26T09:00:00.000',
        'total_amount': 100,
        'status': 'Pending',
        'is_synced': 0,
      });
      await db.insert('orders', {
        'id': 'o-cancel',
        'order_date': '2026-07-26T10:00:00.000',
        'total_amount': 50,
        'status': 'Cancelled',
        'is_synced': 1,
      });
      await db.insert('orders', {
        'id': 'o-other',
        'order_date': '2026-07-25T09:00:00.000',
        'total_amount': 200,
        'status': 'Approved',
        'is_synced': 1,
      });

      await db.insert('invoices', {
        'id': 'i-today',
        'invoice_date': '2026-07-26T11:00:00.000',
        'total_amount': 300,
        'status': 'Completed',
        'is_synced': 0,
      });
      await db.insert('invoices', {
        'id': 'i-cancel',
        'invoice_date': '2026-07-26T12:00:00.000',
        'total_amount': 10,
        'status': 'Cancelled',
        'is_synced': 1,
      });

      await db.insert('collections', {
        'id': 'c-today',
        'collection_date': '2026-07-26T13:00:00.000',
        'amount': 80,
        'payment_type': 'Cash',
        'status': 'Completed',
      });
      await db.insert('collections', {
        'id': 'c-card',
        'collection_date': '2026-07-26T14:00:00.000',
        'amount': 40,
        'payment_type': 'CreditCard',
        'status': 'Completed',
      });
      await db.insert('collections', {
        'id': 'c-other',
        'collection_date': '2026-07-20T13:00:00.000',
        'amount': 40,
        'status': 'Completed',
      });

      await db.insert('visits', {
        'id': 'v-today',
        'check_in_at': '2026-07-26T08:00:00.000',
        'status': 'Completed',
      });
      await db.insert('visits', {
        'id': 'v-other',
        'check_in_at': '2026-07-01T08:00:00.000',
        'status': 'Open',
      });

      await db.insert('customers', {
        'id': 'cust-1',
        'name': 'A',
        'balance': 150,
      });
      await db.insert('customers', {
        'id': 'cust-2',
        'name': 'B',
        'balance': -20,
      });

      await db.insert('bank_deposits', {
        'id': 'bd-1',
        'cash_code': 'KASA',
        'bank_code': '102',
        'amount': 25,
        'deposit_date': '2026-07-26',
        'is_deleted': 0,
        'created_at': '2026-07-26T15:00:00.000',
        'updated_at': '2026-07-26T15:00:00.000',
      });

      await db.insert('waybills', {
        'id': 'w-today',
        'waybill_date': '2026-07-26T10:00:00.000',
        'total_amount': 50,
        'status': 'Pending',
        'is_synced': 0,
      });

      await db.insert('collections', {
        'id': 'c-check',
        'collection_date': '2026-07-26T15:00:00.000',
        'amount': 30,
        'payment_type': 'Check',
        'status': 'Completed',
        'salesperson_code': 'sp-1',
      });

      await db.update(
        'visits',
        {'user_id': 'u-1'},
        where: 'id = ?',
        whereArgs: ['v-today'],
      );
      await db.update(
        'collections',
        {'salesperson_code': 'u-1'},
        where: 'id = ?',
        whereArgs: ['c-today'],
      );

      await db.insert('users', {
        'id': 'u-1',
        'username': 'ali',
        'email': 'a@t.com',
        'full_name': 'Ali Plasiyer',
        'role': 'sales_rep',
        'is_active': 1,
        'is_deleted': 0,
        'created_at': '2026-01-01',
        'updated_at': '2026-01-01',
      });

      await db.insert('targets', {
        'id': 't-1',
        'user_id': 'u-1',
        'target_amount': 1000,
        'achieved_amount': 400,
        'period': '2026-07',
        'type': 'Sales',
      });

      final summary = await repo.fetchToday(db, day: day);
      expect(summary.orderCount, 1);
      expect(summary.invoiceCount, 1);
      expect(summary.collectionCount, 3);
      expect(summary.visitCount, 1);
      expect(summary.waybillCount, 1);
      expect(summary.salesAmount, 300);
      expect(summary.orderAmount, 100);
      expect(summary.collectionAmount, 150);
      expect(summary.cashCollected, 80);
      expect(summary.checkCollected, 30);
      expect(summary.bankSnapshot, 65); // 40 card + 25 deposit
      expect(summary.openReceivables, 150);
      expect(summary.debtorCount, 1);
      expect(summary.pendingOrderCount, 1);
      expect(summary.pendingInvoiceCount, 1);
      expect(summary.pendingTransferTotal, 3);
      expect(summary.targetAmount, 1000);
      expect(summary.targetAchieved, 400);
      expect(summary.sparklineSales.length, 7);
      expect(summary.sparklineSales.last, 300);
      expect(summary.sparklineCollections.length, 7);
      expect(summary.pivotRows, isNotEmpty);
      expect(summary.activeSalespersonCount, greaterThanOrEqualTo(1));
      final insight = summary.toInsightRows();
      expect(insight, isNotEmpty);
    });
  });

  group('AdminKpiRepository.fetchPeriod', () {
    test('haftalık aralık önceki günü dahil eder', () async {
      await db.insert('orders', {
        'id': 'o-mon',
        'order_date': '2026-07-20T09:00:00.000', // Pazartesi
        'total_amount': 10,
        'status': 'Pending',
      });
      await db.insert('orders', {
        'id': 'o-sun',
        'order_date': '2026-07-26T09:00:00.000', // Pazar
        'total_amount': 20,
        'status': 'Pending',
      });
      await db.insert('orders', {
        'id': 'o-prev',
        'order_date': '2026-07-19T09:00:00.000',
        'total_amount': 99,
        'status': 'Pending',
      });

      final summary = await repo.fetchPeriod(
        db,
        period: AdminKpiPeriod.week,
        anchor: day,
      );
      expect(summary.orderCount, 2);
    });
  });
}
