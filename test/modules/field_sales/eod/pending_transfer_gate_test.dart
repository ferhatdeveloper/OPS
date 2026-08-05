// Dosya Adı: pending_transfer_gate_test.dart
// Açıklama: Gün sonu / çıkış bekleyen fatura kapısı birim testleri
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:flutter_test/flutter_test.dart';
import 'package:exfin_ops/modules/field_sales/eod/viewmodel/pending_transfer_gate.dart';
import 'package:exfin_ops/modules/field_sales/eod/viewmodel/pending_transfer_guard.dart';
import 'package:exfin_ops/modules/field_sales/invoices/model/invoice_untransferred_record.dart';
import 'package:exfin_ops/modules/field_sales/invoices/viewmodel/invoice_untransferred_store.dart';

void main() {
  group('PendingTransferGate', () {
    test('count 0 → allow, interrupt yok', () {
      final d = PendingTransferGate.evaluate(
        action: PendingTransferAction.dayClose,
        pendingInvoiceCount: 0,
      );
      expect(d.verdict, PendingTransferVerdict.allow);
      expect(d.shouldInterrupt, isFalse);
      expect(d.allowsForceProceed, isFalse);
    });

    test('gün sonu bekleyen → warn + force + dens rota', () {
      final d = PendingTransferGate.evaluate(
        action: PendingTransferAction.dayClose,
        pendingInvoiceCount: 3,
      );
      expect(d.verdict, PendingTransferVerdict.warn);
      expect(d.shouldInterrupt, isTrue);
      expect(d.allowsForceProceed, isTrue);
      expect(d.pendingInvoiceCount, 3);
      expect(
        d.listRoute,
        PendingTransferGate.invoicesUntransferredRoute,
      );
      expect(d.messageKey, PendingTransferGate.messageDayCloseKey);
      expect(d.forceProceedKey, PendingTransferGate.forceCloseKey);
    });

    test('çıkış bekleyen → warn + force logout key', () {
      final d = PendingTransferGate.evaluate(
        action: PendingTransferAction.logout,
        pendingInvoiceCount: 1,
      );
      expect(d.verdict, PendingTransferVerdict.warn);
      expect(d.messageKey, PendingTransferGate.messageLogoutKey);
      expect(d.forceProceedKey, PendingTransferGate.forceLogoutKey);
      expect(d.openListKey, PendingTransferGate.openListKey);
    });

    test('dayStatusComplete aynı gün sonu mesajını kullanır', () {
      final d = PendingTransferGate.evaluate(
        action: PendingTransferAction.dayStatusComplete,
        pendingInvoiceCount: 2,
      );
      expect(d.messageKey, PendingTransferGate.messageDayCloseKey);
      expect(d.forceProceedKey, PendingTransferGate.forceCloseKey);
    });

    test('negatif count 0 gibi davranır', () {
      final d = PendingTransferGate.evaluate(
        action: PendingTransferAction.logout,
        pendingInvoiceCount: -5,
      );
      expect(d.verdict, PendingTransferVerdict.allow);
      expect(d.pendingInvoiceCount, 0);
    });
  });

  group('PendingTransferGuard', () {
    test('store satır sayısını karar sayısına bağlar', () async {
      final store = InvoiceUntransferredStore(
        loader: () async => const [
          InvoiceUntransferredRecord(id: 'a', documentNo: 'A1'),
          InvoiceUntransferredRecord(id: 'b', documentNo: 'B1'),
        ],
      );
      final guard = PendingTransferGuard(store: store);
      final d = await guard.evaluate(PendingTransferAction.dayClose);
      expect(d.pendingInvoiceCount, 2);
      expect(d.shouldInterrupt, isTrue);
    });

    test('boş store → allow', () async {
      final store = InvoiceUntransferredStore(
        loader: () async => const [],
      );
      final guard = PendingTransferGuard(store: store);
      final d = await guard.evaluate(PendingTransferAction.logout);
      expect(d.verdict, PendingTransferVerdict.allow);
    });
  });
}
