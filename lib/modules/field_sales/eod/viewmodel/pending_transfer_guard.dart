// Dosya Adı: pending_transfer_guard.dart
// Açıklama: Bekleyen fatura sayısını InvoiceUntransferredStore ile çözer
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import '../../invoices/viewmodel/invoice_untransferred_store.dart';
import 'pending_transfer_gate.dart';

/// {@template pending_transfer_guard}
/// Gün sonu / çıkış öncesi bekleyen Logo fatura kontrolü.
///
/// `is_synced=0` (logo_ref henüz yok) + `sync_queue` invoice satırları.
///
/// Kullanım örneği:
/// ```dart
/// final d = await PendingTransferGuard().evaluate(
///   PendingTransferAction.dayClose,
/// );
/// ```
/// {@endtemplate}
class PendingTransferGuard {
  /// [store]: Transfer edilmeyen fatura kaynağı
  final InvoiceUntransferredStore store;

  /// {@macro pending_transfer_guard}
  const PendingTransferGuard({
    this.store = const InvoiceUntransferredStore(),
  });

  /// {@template pending_transfer_guard_count}
  /// Bekleyen fatura adedi (birleşik dens).
  ///
  /// Dönüş değeri:
  /// - [int]: ≥0; hata → 0 (kapıyı yanlışlıkla kilitleme)
  /// {@endtemplate}
  Future<int> countPendingInvoices() async {
    try {
      final rows = await store.loadUnsynced();
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  /// {@template pending_transfer_guard_evaluate}
  /// Store sayımı + [PendingTransferGate] kararı.
  ///
  /// Parametreler:
  /// - [action]: Gün sonu / çıkış
  ///
  /// Dönüş değeri:
  /// - [PendingTransferDecision]: UI dialog / devam kararı
  /// {@endtemplate}
  Future<PendingTransferDecision> evaluate(
    PendingTransferAction action,
  ) async {
    final count = await countPendingInvoices();
    return PendingTransferGate.evaluate(
      action: action,
      pendingInvoiceCount: count,
    );
  }
}
