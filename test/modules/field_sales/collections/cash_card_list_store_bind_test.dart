// Dosya Adı: cash_card_list_store_bind_test.dart
// Açıklama: CashCardListScreen → CashCardStore + master fallback smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/collections/model/cash_card_seed.dart';
import 'package:exfin_ops/modules/field_sales/collections/view/cash_card_list_screen.dart';
import 'package:exfin_ops/modules/field_sales/collections/viewmodel/cash_card_store.dart';

import '../../../field_sales/stub_modules/stub_l10n_harness.dart';

/// Store satırlarını döner (DB yok).
class _RowsStore extends CashCardStore {
  _RowsStore(this.rows);

  final List<CashCardRecord> rows;

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<CashCardRecord>> listActive() async => rows;
}

/// listActive hata fırlatır → master fallback.
class _ThrowingStore extends CashCardStore {
  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<CashCardRecord>> listActive() async {
    throw StateError('sqlite unavailable');
  }
}

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('store satırları dens listede görünür', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(
      tester,
      CashCardListScreen(
        selectionMode: true,
        store: _RowsStore(const [
          CashCardRecord(
            id: 'cc_custom',
            code: '999 99 99',
            name: 'ÖZEL KASA',
            nameKey: 'field_sales.cash_card_merkez_tl',
          ),
        ]),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('999 99 99'), findsOneWidget);
    expect(find.text('100 01 01'), findsNothing);
  });

  testWidgets('boş/hata store → CashCardMaster fallback', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpStubWithL10n(
      tester,
      CashCardListScreen(
        selectionMode: true,
        store: _ThrowingStore(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('100 01 01'), findsOneWidget);
    expect(find.text('MERKEZ TL KASA'), findsOneWidget);
    expect(find.text('200 01 01'), findsOneWidget);
  });
}
