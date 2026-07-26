// Dosya Adı: einvoice_status_queue_test.dart
// Açıklama: e-Fatura durum dens ETTN/GİB satır smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/invoices/model/einvoice_status_seed.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/einvoice_status_screen.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('EinvoiceStatusScreen dens ETTN/GİB alanları', (tester) async {
    await pumpStubWithL10n(
      tester,
      EinvoiceStatusScreen(records: EinvoiceStatusSeed.defaultRows),
    );
    await tester.pump();
    expectStubL10nSmoke(tester, 'field_sales.stubs.einvoice_status');
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('2-ALIŞ'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    expect(find.text('Başlangıç'), findsOneWidget);
    expect(find.text('Bitiş'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    final sales = EinvoiceStatusSeed.salesRows;
    expect(sales, isNotEmpty);
    expect(find.text('ETTN'), findsWidgets);
    expect(find.text('GİB Durum'), findsWidgets);
    expect(find.text(sales.first.documentNo), findsOneWidget);
    expect(find.text(sales.first.ettn), findsOneWidget);
    expect(find.text("GİB'e Gönderildi"), findsWidgets);
  });
}
