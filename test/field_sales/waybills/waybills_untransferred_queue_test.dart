// Dosya Adı: waybills_untransferred_queue_test.dart
// Açıklama: K08 transfer edilmeyen irsaliyeler dens → queue smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/waybills/model/waybill_type.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybills_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/waybills/viewmodel/waybill_repository.dart';
import 'package:exfin_ops/modules/field_sales/waybills/viewmodel/waybill_unsynced_store.dart';

import '../stub_modules/stub_l10n_harness.dart';

/// Widget smoke için SQLite’siz unsynced store.
class _FakeWaybillUnsyncedStore extends WaybillUnsyncedStore {
  /// [rows]: Dönülecek dens satırlar
  final List<WaybillUnsyncedRow> rows;

  const _FakeWaybillUnsyncedStore(this.rows);

  @override
  Future<List<WaybillUnsyncedRow>> loadUnsynced() async => rows;
}

/// Async dens yüklemesinin bitmesini bekler.
Future<void> _pumpUntilLoaded(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('WaybillsUntransferredScreen dens kuyruk boş', (tester) async {
    await pumpStubWithL10n(
      tester,
      const WaybillsUntransferredScreen(
        store: _FakeWaybillUnsyncedStore([]),
      ),
    );
    await _pumpUntilLoaded(tester);

    expectStubL10nSmoke(tester, 'field_sales.stubs.waybills_untransferred');
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('2-ALIŞ'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('0 Adet'), findsOneWidget);
    expect(
      find.text('Transfer edilmeyen irsaliye yok.'),
      findsOneWidget,
    );
  });

  testWidgets('WaybillsUntransferredScreen is_synced=0 satır gösterir',
      (tester) async {
    final now = DateTime.now();
    await pumpStubWithL10n(
      tester,
      WaybillsUntransferredScreen(
        store: _FakeWaybillUnsyncedStore([
          WaybillUnsyncedRow(
            id: 'wb-u1',
            customerId: 'cust-u',
            customerCode: 'ARP-U',
            customerName: 'Unsync Cari',
            waybillDate: now,
            waybillType: WaybillType.wholesale.localKey,
            totalAmount: 99,
            notes: 'Sevk bekleyen',
            isSynced: 0,
          ),
        ]),
      ),
    );
    await _pumpUntilLoaded(tester);

    expect(find.text('Sevk bekleyen'), findsOneWidget);
    expect(find.text('1 Adet'), findsOneWidget);
    expect(
      find.text('Transfer edilmeyen irsaliye yok.'),
      findsNothing,
    );
  });
}
