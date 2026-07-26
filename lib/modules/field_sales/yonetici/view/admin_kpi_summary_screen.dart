// Dosya Adı: admin_kpi_summary_screen.dart
// Açıklama: MBT Yönetici — plasiyer KPI özeti (SQLite günlük aggregate)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/admin_kpi_summary.dart';
import '../viewmodel/admin_kpi_provider.dart';

/// {@template admin_kpi_summary_screen}
/// Plasiyer KPI özet ekranı (MBT Yönetici parity).
///
/// Rota: `/field-sales/admin` — menü seed `fs_admin`.
/// Sayılar yerel SQLite bugünkü COUNT aggregate.
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, AdminKpiSummaryScreen.routeName);
/// ```
/// {@endtemplate}
class AdminKpiSummaryScreen extends ConsumerWidget {
  /// [routeName]: Named route — `/field-sales/admin`
  static const String routeName = '/field-sales/admin';

  const AdminKpiSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.admin_kpi');
    final asyncSummary = ref.watch(adminKpiSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: asyncSummary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminKpiSummaryProvider),
          child: _AdminKpiBody(
            summary: AdminKpiSummary.zero,
            hintKey: 'field_sales.admin_kpi_error_hint',
          ),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminKpiSummaryProvider),
          child: _AdminKpiBody(
            summary: summary,
            hintKey: 'field_sales.admin_kpi_live_hint',
          ),
        ),
      ),
    );
  }
}

/// {@template _admin_kpi_body}
/// Alt başlık + 4 KPI kartı + dip not (mevcut görsel dil korunur).
/// {@endtemplate}
class _AdminKpiBody extends StatelessWidget {
  /// [summary]: Gösterilecek KPI sayıları
  final AdminKpiSummary summary;

  /// [hintKey]: Alt açıklama l10n anahtarı
  final String hintKey;

  const _AdminKpiBody({
    required this.summary,
    required this.hintKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final kpis = <_KpiRow>[
      _KpiRow(
        labelKey: 'field_sales.order',
        value: '${summary.orderCount}',
        icon: Icons.shopping_cart_outlined,
      ),
      _KpiRow(
        labelKey: 'field_sales.invoice',
        value: '${summary.invoiceCount}',
        icon: Icons.receipt_long_outlined,
      ),
      _KpiRow(
        labelKey: 'field_sales.collection',
        value: '${summary.collectionCount}',
        icon: Icons.account_balance_wallet_outlined,
      ),
      _KpiRow(
        labelKey: 'field_sales.visit',
        value: '${summary.visitCount}',
        icon: Icons.location_on_outlined,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          l10n.translate('field_sales.admin_kpi_subtitle'),
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final kpi = kpis[index];
            return _FlatKpiCard(
              label: l10n.translate(kpi.labelKey),
              value: kpi.value,
              icon: kpi.icon,
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          l10n.translate(hintKey),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// {@template _kpi_row}
/// Tek KPI satırı (etiket anahtarı + değer + ikon).
/// {@endtemplate}
class _KpiRow {
  /// [labelKey]: l10n anahtarı
  final String labelKey;

  /// [value]: Gösterilecek sayı metni
  final String value;

  /// [icon]: Kart ikonu
  final IconData icon;

  const _KpiRow({
    required this.labelKey,
    required this.value,
    required this.icon,
  });
}

/// {@template _flat_kpi_card}
/// MBT tarzı düz / yoğun KPI kartı (mevcut field_sales token’ları).
/// {@endtemplate}
class _FlatKpiCard extends StatelessWidget {
  /// [label]: Kart başlığı
  final String label;

  /// [value]: Sayı metni
  final String value;

  /// [icon]: Sol üst ikon
  final IconData icon;

  const _FlatKpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF375A7F).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF375A7F)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF375A7F),
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
