// Dosya Adı: customer_reconciliation_summary_test.dart
// Açıklama: Mutabakat özet matematik + store dönem özeti unit
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/customers/model/customer_extract_movement.dart';
import 'package:exfin_ops/modules/field_sales/customers/model/customer_reconciliation_summary.dart';
import 'package:exfin_ops/modules/field_sales/customers/viewmodel/customer_extract_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('CustomerReconciliationSummary closing = açılış + borç − alacak', () {
    const s = CustomerReconciliationSummary(
      openingBalance: 100,
      periodDebit: 50,
      periodCredit: 20,
      movementCount: 2,
    );
    expect(s.closingBalance, 130);
    expect(s.periodNet, 30);
  });

  test('CustomerExtractStore.reconciliationSummary — açılış + dönem', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1),
    );
    addTearDown(() async => db.close());

    final store = CustomerExtractStore(openDb: () async => db);
    await store.ensureTable(db);

    await store.insert(
      CustomerExtractMovement(
        id: 'm-open',
        customerId: 'C-REC',
        movementDate: DateTime(2026, 6, 15),
        documentNo: 'A1',
        description: 'önce',
        debit: 200,
        credit: 0,
      ),
    );
    await store.insert(
      CustomerExtractMovement(
        id: 'm-deb',
        customerId: 'C-REC',
        movementDate: DateTime(2026, 7, 10),
        documentNo: 'B1',
        description: 'borç',
        debit: 80,
        credit: 0,
      ),
    );
    await store.insert(
      CustomerExtractMovement(
        id: 'm-cred',
        customerId: 'C-REC',
        movementDate: DateTime(2026, 7, 12),
        documentNo: 'B2',
        description: 'alacak',
        debit: 0,
        credit: 30,
      ),
    );

    final summary = await store.reconciliationSummary(
      customerId: 'C-REC',
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 7, 31),
    );

    expect(summary.openingBalance, 200);
    expect(summary.periodDebit, 80);
    expect(summary.periodCredit, 30);
    expect(summary.closingBalance, 250);
    expect(summary.movementCount, 2);
  });
}
