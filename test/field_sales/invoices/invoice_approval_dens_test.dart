// Dosya Adı: invoice_approval_dens_test.dart
// Açıklama: Fatura onaylama dens gerçek kayıt satır smoke
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter_test/flutter_test.dart';

import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_model.dart';
import 'package:exfin_ops/modules/field_sales/invoices/view/invoice_approval_screen.dart';

import '../stub_modules/stub_l10n_harness.dart';

void main() {
  setUpAll(() async {
    await ensureStubL10nLoaded();
  });

  final now = DateTime.now();
  final seed = <InvoiceModel>[
    InvoiceModel(
      id: 'inv-pend-1',
      customerId: 'C-PEND-01',
      invoiceDate: now,
      totalAmount: 150.5,
      status: 'Pending',
      invoiceType: 'field_sales.wholesale_invoice_8',
      approvalStatus: 0,
    ),
    InvoiceModel(
      id: 'inv-ok-1',
      customerId: 'C-OK-01',
      invoiceDate: now,
      totalAmount: 220,
      status: 'Completed',
      invoiceType: 'field_sales.purchase_invoice',
      approvalStatus: 1,
    ),
  ];

  testWidgets('InvoiceApprovalScreen dens gerçek satırlar', (tester) async {
    await pumpStubWithL10n(
      tester,
      InvoiceApprovalScreen(invoices: seed),
    );
    await tester.pump();
    expectStubL10nSmoke(tester, 'field_sales.stubs.invoice_approval');
    expect(find.text('Bekleyen'), findsWidgets);
    expect(find.text('Onaylanan'), findsOneWidget);
    expect(find.text('C-PEND-01'), findsOneWidget);
    expect(find.text('Beklemede'), findsOneWidget);
    expect(find.textContaining('150.50'), findsOneWidget);
    // Onaylı kayıt Bekleyen sekmesinde görünmez
    expect(find.text('C-OK-01'), findsNothing);
  });

  test('InvoiceModel ONAY dens bayrakları mutually exclusive', () {
    final pending = InvoiceModel(
      id: 'a',
      customerId: 'c',
      invoiceDate: now,
      totalAmount: 1,
      approvalStatus: 0,
      status: 'Pending',
    );
    final approved = InvoiceModel(
      id: 'b',
      customerId: 'c',
      invoiceDate: now,
      totalAmount: 1,
      approvalStatus: 1,
      status: 'Pending',
    );
    expect(pending.isPendingApproval, isTrue);
    expect(pending.isApproved, isFalse);
    expect(approved.isPendingApproval, isFalse);
    expect(approved.isApproved, isTrue);
    expect(approved.toMap()['approval_status'], 1);
    expect(
      InvoiceModel.fromMap(approved.toMap()).approvalStatus,
      1,
    );
  });
}
