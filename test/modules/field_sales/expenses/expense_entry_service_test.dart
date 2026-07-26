// Dosya Adı: expense_entry_service_test.dart
// Açıklama: Masraf girişi yerel SQLite kayıt birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/expenses/model/expense_record.dart';
import 'package:exfin_ops/modules/field_sales/expenses/viewmodel/expense_entry_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(SqlQuerys.createExpensesTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpenseRecord', () {
    test('toMap / fromMap round-trip', () {
      final record = ExpenseRecord(
        id: 'exp-1',
        type: ExpenseType.fuel,
        amount: 125.5,
        note: 'Benzin',
        createdAt: DateTime(2026, 7, 26, 10),
      );

      final restored = ExpenseRecord.fromMap(record.toMap());
      expect(restored.id, 'exp-1');
      expect(restored.type, ExpenseType.fuel);
      expect(restored.amount, 125.5);
      expect(restored.note, 'Benzin');
      expect(restored.isSynced, isFalse);
      expect(restored.createdAt.day, 26);
    });

    test('parseAmount TR ondalık', () {
      expect(ExpenseRecord.parseAmount('1.250,75'), 1250.75);
      expect(ExpenseRecord.parseAmount('125,5'), 125.5);
      expect(ExpenseRecord.parseAmount(''), isNull);
      expect(ExpenseRecord.parseAmount('abc'), isNull);
    });
  });

  group('ExpenseEntryService.saveLocal', () {
    test('expenses tablosuna satır yazar', () async {
      final record = ExpenseRecord(
        id: 'exp-save-1',
        type: ExpenseType.food,
        amount: 80,
        note: 'Öğle',
        createdAt: DateTime(2026, 7, 26, 12),
      );

      final id = await ExpenseEntryService.saveLocal(
        db: db,
        record: record,
      );

      expect(id, 'exp-save-1');

      final rows = await db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows, hasLength(1));
      expect(rows.first['type'], 'FOOD');
      expect(rows.first['amount'], 80);
      expect(rows.first['note'], 'Öğle');
      expect(rows.first['is_synced'], 0);
    });

    test('tutar <= 0 ise ArgumentError', () async {
      final record = ExpenseRecord(
        id: 'exp-bad',
        type: ExpenseType.other,
        amount: 0,
        createdAt: DateTime(2026, 7, 26),
      );

      expect(
        () => ExpenseEntryService.saveLocal(db: db, record: record),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SqlQuerys.createExpensesTable', () {
    test('DDL CREATE TABLE içerir', () {
      expect(
        SqlQuerys.createExpensesTable,
        contains('CREATE TABLE IF NOT EXISTS expenses'),
      );
      expect(SqlQuerys.createExpensesTable, contains('type TEXT NOT NULL'));
      expect(SqlQuerys.createExpensesTable, contains('amount REAL NOT NULL'));
    });
  });
}
