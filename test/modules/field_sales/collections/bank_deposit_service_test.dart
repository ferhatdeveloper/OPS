// Dosya Adı: bank_deposit_service_test.dart
// Açıklama: Banka yatırma yerel kayıt + sync_queue birim testleri
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/core/database/migrations/SqlQuerys.dart';
import 'package:exfin_ops/modules/field_sales/collections/model/bank_deposit_record.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/bank_deposit_service.dart';

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
        await db.execute(SqlQuerys.createBankDepositsTable);
        await db.execute(SqlQuerys.createSyncQueueTable);
      },
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('BankDepositRecord', () {
    test('toMap / fromMap round-trip', () {
      final record = BankDepositRecord(
        id: 'bd-1',
        cashCode: '100 01 01',
        bankCode: '102 01 01',
        amount: 2500.75,
        documentNo: 'BY-001',
        depositDate: DateTime(2026, 7, 26),
        notes: 'Gün sonu yatırma',
        onay: 1,
        isSynced: false,
        createdAt: DateTime(2026, 7, 26, 10),
        updatedAt: DateTime(2026, 7, 26, 10),
      );

      final restored = BankDepositRecord.fromMap(record.toMap());
      expect(restored.id, 'bd-1');
      expect(restored.cashCode, '100 01 01');
      expect(restored.bankCode, '102 01 01');
      expect(restored.amount, 2500.75);
      expect(restored.documentNo, 'BY-001');
      expect(restored.depositDate.day, 26);
      expect(restored.notes, 'Gün sonu yatırma');
      expect(restored.onay, 1);
      expect(restored.isSynced, isFalse);
    });

    test('parseAmount TR ondalık', () {
      expect(BankDepositRecord.parseAmount('1.250,75'), 1250.75);
      expect(BankDepositRecord.parseAmount('250,5'), 250.5);
      expect(BankDepositRecord.parseAmount(''), isNull);
      expect(BankDepositRecord.parseAmount('abc'), isNull);
    });

    test('validateGuard boş kasa/banka hata anahtarı', () {
      expect(
        BankDepositRecord.validateGuard(
          cashCode: '',
          bankCode: '102',
          amount: 10,
        ),
        'field_sales.bank_deposit_requires_accounts',
      );
    });

    test('validateGuard aynı hesap hata anahtarı', () {
      expect(
        BankDepositRecord.validateGuard(
          cashCode: '01',
          bankCode: '01',
          amount: 10,
        ),
        'field_sales.bank_deposit_same_account',
      );
    });

    test('validateGuard geçersiz tutar', () {
      expect(
        BankDepositRecord.validateGuard(
          cashCode: '01',
          bankCode: '02',
          amount: 0,
        ),
        'field_sales.payment_invalid_amount',
      );
    });

    test('validateGuard geçerli null', () {
      expect(
        BankDepositRecord.validateGuard(
          cashCode: '01',
          bankCode: '02',
          amount: 100,
        ),
        isNull,
      );
    });
  });

  group('BankDepositService.saveLocalAndQueue', () {
    test('yerel bank_deposits + sync_queue satırı yazar', () async {
      final record = BankDepositRecord(
        id: 'bd-save-1',
        cashCode: '100 01 01',
        bankCode: '102 01 01',
        amount: 500,
        documentNo: 'EV-9',
        depositDate: DateTime(2026, 7, 26),
        notes: 'Test',
        onay: 1,
        isSynced: false,
        createdAt: DateTime(2026, 7, 26, 12),
        updatedAt: DateTime(2026, 7, 26, 12),
      );

      final id = await BankDepositService.saveLocalAndQueue(
        db: db,
        record: record,
      );

      expect(id, 'bd-save-1');

      final local = await db.query(
        'bank_deposits',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(local, hasLength(1));
      expect(local.first['cash_code'], '100 01 01');
      expect(local.first['bank_code'], '102 01 01');
      expect(local.first['amount'], 500);
      expect(local.first['is_synced'], 0);
      expect(local.first['ONAY'], 1);

      final queue = await db.query(
        'sync_queue',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['bank_deposit', id],
      );
      expect(queue, hasLength(1));
      final payload = jsonDecode(queue.first['payload'] as String) as Map;
      expect(payload['id'], id);
      expect(payload['entity'], 'bank_deposit');
      expect(payload['payment_type'], 'bank_deposit');
      expect(payload['cash_code'], '100 01 01');
      expect(payload['bank_code'], '102 01 01');
      expect(payload['amount'], 500);
      expect(payload.containsKey('customer_code'), isFalse);
    });
  });
}
