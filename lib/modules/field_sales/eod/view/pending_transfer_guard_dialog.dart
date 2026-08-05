// Dosya Adı: pending_transfer_guard_dialog.dart
// Açıklama: Bekleyen fatura — gün sonu / çıkış AlertDialog kancası
// Oluşturulma Tarihi: 2026-08-05
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-08-05

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../viewmodel/pending_transfer_gate.dart';

/// {@template pending_transfer_dialog_result}
/// Guard dialog sonucu.
/// {@endtemplate}
enum PendingTransferDialogResult {
  /// İptal — eylem durur
  cancel,

  /// Transfer edilmeyen faturalar listesine git
  openList,

  /// Uyarıda zorla devam (block’ta yok)
  forceProceed,
}

/// {@template pending_transfer_guard_dialog}
/// Minimal AlertDialog — dens redesign yok; iş kuralı kancası.
///
/// Kullanım örneği:
/// ```dart
/// final r = await showPendingTransferGuardDialog(
///   context: context,
///   decision: decision,
/// );
/// ```
/// {@endtemplate}
Future<PendingTransferDialogResult> showPendingTransferGuardDialog({
  required BuildContext context,
  required PendingTransferDecision decision,
}) async {
  if (!decision.shouldInterrupt) {
    return PendingTransferDialogResult.forceProceed;
  }

  final l10n = AppLocalization.of(context);
  final message = l10n.translate(
    decision.messageKey,
    args: {'count': '${decision.pendingInvoiceCount}'},
  );

  final result = await showDialog<PendingTransferDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.translate(decision.titleKey)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              PendingTransferDialogResult.cancel,
            ),
            child: Text(l10n.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              PendingTransferDialogResult.openList,
            ),
            child: Text(l10n.translate(decision.openListKey)),
          ),
          if (decision.allowsForceProceed)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(
                PendingTransferDialogResult.forceProceed,
              ),
              child: Text(
                l10n.translate(decision.forceProceedKey!),
              ),
            ),
        ],
      );
    },
  );

  return result ?? PendingTransferDialogResult.cancel;
}
