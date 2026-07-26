// Dosya Adı: unsaved_voucher_dialog.dart
// Açıklama: Kaydedilmemiş fiş uyarısı — Devam Et / Sil (MBT parity)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template UnsavedVoucherAction}
/// Kaydedilmemiş fiş diyaloğu sonucu.
/// {@endtemplate}
enum UnsavedVoucherAction {
  /// Düzenlemeye devam et (çıkma / taslağı koru)
  continueEditing,

  /// Taslağı sil
  delete,
}

/// {@template ExistingDraftDecision}
/// Entry açılışında mevcut taslak için karar.
/// {@endtemplate}
enum ExistingDraftDecision {
  /// Taslak yok → yeni fiş başlat
  startFresh,

  /// Devam Et → mevcut taslağı koru
  keepExisting,

  /// Sil → taslağı silip yeni fiş başlat
  discardAndRestart,
}

/// {@template resolveExistingDraftDecision}
/// Dialog aksiyonunu entry açılış kararına çevirir (saf / test edilebilir).
///
/// Parametreler:
/// - [hasExistingDraft]: Kaydedilmemiş kalem / form var mı
/// - [action]: Dialog sonucu (`null` → koru)
///
/// Dönüş değeri:
/// - [ExistingDraftDecision]: startFresh / keepExisting / discardAndRestart
/// {@endtemplate}
ExistingDraftDecision resolveExistingDraftDecision({
  required bool hasExistingDraft,
  UnsavedVoucherAction? action,
}) {
  if (!hasExistingDraft) return ExistingDraftDecision.startFresh;
  if (action == UnsavedVoucherAction.delete) {
    return ExistingDraftDecision.discardAndRestart;
  }
  return ExistingDraftDecision.keepExisting;
}

/// {@template showUnsavedVoucherDialog}
/// Kaydedilmemiş fiş uyarısını gösterir.
///
/// Dönüş değeri:
/// - [UnsavedVoucherAction.continueEditing]: Devam Et
/// - [UnsavedVoucherAction.delete]: Sil
/// - `null`: dialog kapatıldı
///
/// Kullanım örneği:
/// ```dart
/// final action = await showUnsavedVoucherDialog(context);
/// if (action == UnsavedVoucherAction.delete) { ... }
/// ```
/// {@endtemplate}
Future<UnsavedVoucherAction?> showUnsavedVoucherDialog(
  BuildContext context, {
  String? customerLabel,
}) {
  final l10n = AppLocalization.of(context);
  final baseMessage = l10n.translate('field_sales.unsaved_voucher_message');
  final label = customerLabel?.trim();
  final message = (label != null && label.isNotEmpty)
      ? '$baseMessage\n($label)'
      : baseMessage;

  return showDialog<UnsavedVoucherAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Text(
          l10n.translate('field_sales.unsaved_voucher_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(UnsavedVoucherAction.continueEditing),
            child: Text(
              l10n.translate('field_sales.unsaved_voucher_continue'),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () =>
                Navigator.of(ctx).pop(UnsavedVoucherAction.delete),
            child: Text(
              l10n.translate('field_sales.unsaved_voucher_delete'),
            ),
          ),
        ],
      );
    },
  );
}

/// {@template confirmDiscardUnsavedVoucher}
/// Kaydedilmemiş fiş varsa dialog gösterir.
///
/// Dönüş değeri:
/// - `true`: Sil seçildi (çıkışa izin ver)
/// - `false`: Devam Et veya iptal (çıkışa izin verme)
///
/// [hasUnsaved] false ise doğrudan true döner.
/// {@endtemplate}
Future<bool> confirmDiscardUnsavedVoucher({
  required BuildContext context,
  required bool hasUnsaved,
  String? customerLabel,
}) async {
  if (!hasUnsaved) return true;
  final action = await showUnsavedVoucherDialog(
    context,
    customerLabel: customerLabel,
  );
  return action == UnsavedVoucherAction.delete;
}

/// {@template promptExistingDraftVoucher}
/// Entry açılışında mevcut taslak varsa ortak uyarıyı gösterir.
///
/// Dönüş değeri:
/// - [ExistingDraftDecision]: startFresh / keepExisting / discardAndRestart
/// {@endtemplate}
Future<ExistingDraftDecision> promptExistingDraftVoucher({
  required BuildContext context,
  required bool hasExistingDraft,
  String? customerLabel,
}) async {
  if (!hasExistingDraft) return ExistingDraftDecision.startFresh;
  final action = await showUnsavedVoucherDialog(
    context,
    customerLabel: customerLabel,
  );
  return resolveExistingDraftDecision(
    hasExistingDraft: true,
    action: action,
  );
}
