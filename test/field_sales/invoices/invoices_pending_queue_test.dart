// Dosya Adı: invoices_pending_queue_test.dart
// Açıklama: Bekleyen fatura dens kuyruk smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_pending_seed.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoices_pending_screen.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('InvoicesPendingScreen dens satış/alış kuyruk', (tester) async {
    await pumpStubWithL10n(
      tester,
      InvoicesPendingScreen(records: InvoicePendingSeed.defaultRows),
    );
    expectStubL10nSmoke(tester, 'field_sales.stubs.invoices_pending');
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('2-ALIŞ'), findsOneWidget);
    expect(find.text('Bu Ay'), findsOneWidget);
    expect(find.text('Başlangıç'), findsOneWidget);
    expect(find.text('Bitiş'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    final sales = InvoicePendingSeed.salesRows;
    expect(sales, isNotEmpty);
    expect(find.text(sales.first.id), findsOneWidget);
    expect(find.text('Onay bekliyor'), findsWidgets);
  });
}
