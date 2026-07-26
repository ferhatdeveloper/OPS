// Dosya Adı: unsaved_voucher_scope.dart
// Açıklama: Kaydedilmemiş fiş PopScope sarmalayıcısı (Devam Et / Sil)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import 'unsaved_voucher_dialog.dart';

/// {@template unsaved_voucher_scope}
/// Kaydedilmemiş kalem varken geri çıkışı engeller; Devam Et / Sil sorar.
///
/// Kullanım örneği:
/// ```dart
/// UnsavedVoucherScope(
///   hasUnsaved: state.items.isNotEmpty,
///   onDiscard: () => notifier.discardDraft(),
///   child: Scaffold(...),
/// )
/// ```
/// {@endtemplate}
class UnsavedVoucherScope extends StatelessWidget {
  /// [hasUnsaved]: Çıkışta uyarı gösterilsin mi
  final bool hasUnsaved;

  /// [onDiscard]: Sil seçilince taslağı temizle
  final VoidCallback onDiscard;

  /// [child]: Korunan alt ağaç (genelde Scaffold)
  final Widget child;

  const UnsavedVoucherScope({
    Key? key,
    required this.hasUnsaved,
    required this.onDiscard,
    required this.child,
  }) : super(key: key);

  Future<void> _handlePop(BuildContext context, bool didPop) async {
    if (didPop) return;
    final discard = await confirmDiscardUnsavedVoucher(
      context: context,
      hasUnsaved: hasUnsaved,
    );
    if (!discard || !context.mounted) return;
    onDiscard();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasUnsaved,
      onPopInvokedWithResult: (didPop, _) {
        _handlePop(context, didPop);
      },
      child: child,
    );
  }
}
