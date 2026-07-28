// Dosya Adı: visit_new_customer_screen.dart
// Açıklama: Ziyaret → Yeni Cari Hesap (form + check-in)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localization.dart';
import '../../customers/model/customer_model.dart';
import '../../customers/view/customer_form_screen.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../viewmodel/visit_open_redirect.dart';
import '../viewmodel/visit_provider.dart';
import 'visit_form_screen.dart';

/// {@template visit_new_customer_screen}
/// Ziyaret menüsünden yeni cari: form kaydı → check-in → ziyaret formu.
/// Route: `/field-sales/visit-new`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VisitNewCustomerScreen.routeName);
/// ```
/// {@endtemplate}
class VisitNewCustomerScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/visit-new`
  static const String routeName = '/field-sales/visit-new';

  const VisitNewCustomerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VisitNewCustomerScreen> createState() =>
      _VisitNewCustomerScreenState();
}

class _VisitNewCustomerScreenState
    extends ConsumerState<VisitNewCustomerScreen> {
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openForm());
  }

  /// {@template visit_new_open_form}
  /// Cari formunu açar; kayıt sonrası check-in + ziyaret formu.
  /// {@endtemplate}
  Future<void> _openForm() async {
    if (_opening || !mounted) return;
    setState(() => _opening = true);
    final l10n = AppLocalization.of(context);

    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerFormScreen(),
      ),
    );

    if (!mounted) return;

    if (result is! CustomerModel || result.id.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }

    final customer = result;
    final success =
        await ref.read(visitProvider.notifier).checkIn(customer.id);
    if (!mounted) return;

    if (!success) {
      final redirected = await redirectToOpenVisitIfNeeded(
        context: context,
        ref: ref,
        l10n: l10n,
        replace: true,
      );
      if (redirected || !mounted) return;
      final err = ref.read(visitProvider).error;
      final msg = (err != null && err.isNotEmpty)
          ? l10n.translate(err)
          : l10n.translate('field_sales.visit_check_in_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      // Cari kaydı tamam; ziyaret formuna yine de geç (check-in opsiyonel)
      await Navigator.pushReplacementNamed(
        context,
        VisitFormScreen.routeName,
        arguments: customer.id,
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${l10n.translate('field_sales.visit_started')}: '
          '${customer.name}',
        ),
      ),
    );
    await Navigator.pushReplacementNamed(
      context,
      VisitFormScreen.routeName,
      arguments: customer.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.visit_new_customer'),
        useGradient: true,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
