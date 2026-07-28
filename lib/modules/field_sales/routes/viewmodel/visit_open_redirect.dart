// Dosya Adı: visit_open_redirect.dart
// Açıklama: Açık ziyaret engelinde VisitFormScreen yönlendirmesi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localization.dart';
import '../view/visit_form_screen.dart';
import '../view/visit_history_screen.dart';
import 'visit_open_redirect_logic.dart';
import 'visit_provider.dart';

export 'visit_open_redirect_logic.dart';

/// {@template redirect_to_open_visit_if_needed}
/// `visit_already_open` hatasında açık ziyaretin cari formuna gider.
///
/// Parametreler:
/// - [context]: Navigasyon / SnackBar
/// - [ref]: [visitProvider] okuma
/// - [l10n]: Çeviri
/// - [replace]: true ise pushReplacementNamed
///
/// Dönüş değeri:
/// - [bool]: Yönlendirme yapıldıysa true
/// {@endtemplate}
Future<bool> redirectToOpenVisitIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalization l10n,
  bool replace = false,
}) async {
  final err = ref.read(visitProvider).error;
  if (!shouldRedirectToOpenVisit(err)) return false;

  var open = ref.read(visitProvider).activeVisit;
  if (open == null) {
    await ref.read(visitProvider.notifier).fetchActiveVisit();
    if (!context.mounted) return false;
    open = ref.read(visitProvider).activeVisit;
  }

  final customerId = openVisitRedirectCustomerId(open?.customerId);
  if (customerId == null) return false;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        l10n.translate('field_sales.visit_redirected_to_open'),
      ),
      action: SnackBarAction(
        label: l10n.translate('field_sales.stubs.visit_history'),
        onPressed: () {
          Navigator.pushNamed(
            context,
            VisitHistoryScreen.routeName,
            arguments: {'customerId': customerId},
          );
        },
      ),
    ),
  );

  if (replace) {
    await Navigator.pushReplacementNamed(
      context,
      VisitFormScreen.routeName,
      arguments: customerId,
    );
  } else {
    await Navigator.pushNamed(
      context,
      VisitFormScreen.routeName,
      arguments: customerId,
    );
  }
  return true;
}
