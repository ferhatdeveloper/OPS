// Dosya Adı: customer_extract_screen_test.dart
// Açıklama: Cari ekstre dens liste — provider/SQLite bağ smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:exfin_ops/modules/field_sales/customers/model/customer_extract_movement.dart';
import 'package:exfin_ops/modules/field_sales/customers/view/customer_extract_screen.dart';
import 'package:exfin_ops/modules/field_sales/customers/viewmodel/customer_extract_provider.dart';
import 'package:exfin_ops/modules/field_sales/customers/viewmodel/customer_extract_store.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

/// Boş liste dönen store (widget smoke, DB yok).
class _EmptyExtractStore extends CustomerExtractStore {
  const _EmptyExtractStore();

  @override
  Future<List<CustomerExtractMovement>> query({
    String? customerId,
    required DateTime start,
    required DateTime end,
    ExtractMovementFilter filter = ExtractMovementFilter.all,
    String search = '',
  }) async {
    return const [];
  }
}

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('CustomerExtractScreen dens filtre + boş hareket', (tester) async {
    await pumpStubWithL10n(
      tester,
      ProviderScope(
        overrides: [
          customerExtractStoreProvider.overrideWithValue(
            const _EmptyExtractStore(),
          ),
        ],
        child: const CustomerExtractScreen(customerId: 'C-100'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expectStubL10nSmoke(tester, 'field_sales.stubs.customer_extract');
    expect(find.textContaining('C-100'), findsOneWidget);
    expectStubL10nSmoke(tester, 'field_sales.extract_empty');
    expectStubL10nSmoke(tester, 'field_sales.extract_filter_all');
    expectStubL10nSmoke(tester, 'field_sales.extract_col_debit');
    expectStubL10nSmoke(tester, 'field_sales.period_this_month');
  });

  test('CustomerExtractStore seed + dönem filtresi', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    addTearDown(() async => db.close());

    final store = CustomerExtractStore(openDb: () async => db);
    await store.ensureReady();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    final monthRows = await store.query(
      customerId: 'C-100',
      start: start,
      end: end,
    );
    expect(monthRows.length, 2);
    expect(monthRows.any((m) => m.isDebit), isTrue);
    expect(monthRows.any((m) => m.isCredit), isTrue);

    final debitOnly = await store.query(
      customerId: 'C-100',
      start: start,
      end: end,
      filter: ExtractMovementFilter.debit,
    );
    expect(debitOnly, everyElement(predicate((CustomerExtractMovement m) {
      return m.debit > 0;
    })));

    final yearRows = await store.query(
      customerId: 'C-100',
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, 12, 31),
    );
    expect(yearRows.length, greaterThanOrEqualTo(3));
  });
}
