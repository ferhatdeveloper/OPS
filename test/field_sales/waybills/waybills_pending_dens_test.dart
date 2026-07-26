// Dosya Adı: waybills_pending_dens_test.dart
// Açıklama: Bekleyen irsaliye dens kuyruk UI smoke (SQLite seed maps)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/waybills/model/waybill_pending_seed.dart';
import 'package:exfin_ops/modules/field_sales/waybills/view/waybills_pending_screen.dart';
import 'package:exfin_ops/modules/field_sales/waybills/viewmodel/waybill_pending_store.dart';

import '../stub_modules/stub_l10n_harness.dart';

/// Test: fake async altında SQLite beklemeden dens satır döner.
class _FixedPendingStore extends WaybillPendingStore {
  _FixedPendingStore(this._rows);

  final List<Map<String, dynamic>> _rows;

  @override
  Future<List<Map<String, dynamic>>> loadPending() async => _rows;
}

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('WaybillsPendingScreen dens sekme + SQLite pending satır',
      (tester) async {
    final store = _FixedPendingStore(WaybillPendingSeed.defaultMaps());

    await pumpStubWithL10n(
      tester,
      WaybillsPendingScreen(store: store),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expectStubL10nSmoke(tester, 'field_sales.stubs.waybills_pending');
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('2-ALIŞ'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Seed toptan satır dens title (belge no)
    expect(find.text('IRS-PENDING-S'), findsOneWidget);
  });
}
