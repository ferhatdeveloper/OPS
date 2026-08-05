// Dosya Adı: invoice_untransferred_queue_test.dart
// Açıklama: Transfer edilmeyen fatura dens — canlı store / empty / seed smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_untransferred_record.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_untransferred_seed.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoices_untransferred_screen.dart';
import 'package:exfin_ops/modules/field_sales/invoices/viewmodel/invoice_untransferred_store.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  testWidgets('boş store → empty state (seed yok)', (tester) async {
    await pumpStubWithL10n(
      tester,
      InvoicesUntransferredScreen(
        store: InvoiceUntransferredStore(
          loader: () async => const [],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expectStubL10nSmoke(
      tester,
      'field_sales.stubs.invoices_untransferred',
    );
    expect(find.text('1-SATIŞ'), findsOneWidget);
    expect(find.text('2-ALIŞ'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('0 Adet'), findsOneWidget);
    expect(
      find.text('Transfer edilmeyen fatura yok.'),
      findsOneWidget,
    );
    expect(
      find.text(InvoiceUntransferredSeed.salesRows.first.documentNo),
      findsNothing,
    );
  });

  testWidgets('canlı is_synced=0 satır gösterir', (tester) async {
    final now = DateTime.now();
    await pumpStubWithL10n(
      tester,
      InvoicesUntransferredScreen(
        store: InvoiceUntransferredStore(
          loader: () async => [
            InvoiceUntransferredRecord(
              id: 'inv-live-1',
              documentNo: 'FT-LIVE-001',
              invoiceType: 'field_sales.wholesale_invoice_8',
              docSide: InvoiceUntransferredDocSide.sales,
              customerCode: 'C900',
              customerName: 'Canlı Cari',
              documentDate: now,
              amount: 42.5,
              isSynced: 0,
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('FT-LIVE-001'), findsOneWidget);
    expect(find.text('1 Adet'), findsOneWidget);
    expect(find.text('Bekliyor'), findsOneWidget);
    expect(find.text('Durum'), findsWidgets);
    expect(
      find.text('Transfer edilmeyen fatura yok.'),
      findsNothing,
    );
  });

  testWidgets('kuyruk hatası → Aktarılamadı dens durum', (tester) async {
    final now = DateTime.now();
    await pumpStubWithL10n(
      tester,
      InvoicesUntransferredScreen(
        store: InvoiceUntransferredStore(
          loader: () async => [
            InvoiceUntransferredRecord(
              id: 'inv-err-1',
              documentNo: 'FT-ERR-001',
              docSide: InvoiceUntransferredDocSide.sales,
              documentDate: now,
              amount: 10,
              isSynced: 0,
              queueJobId: 'job-err',
              retryCount: 6,
              lastError: 'logo down',
            ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('FT-ERR-001'), findsOneWidget);
    expect(find.text('Aktarılamadı'), findsOneWidget);
  });

  testWidgets('hata + seedOnError → seed satır', (tester) async {
    await pumpStubWithL10n(
      tester,
      InvoicesUntransferredScreen(
        seedOnError: true,
        store: InvoiceUntransferredStore(
          loader: () async => throw Exception('db'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    final sales = InvoiceUntransferredSeed.salesRows;
    expect(find.text(sales.first.documentNo), findsOneWidget);
  });
}
