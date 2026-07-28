// Dosya Adı: report_category_list_screen.dart
// Açıklama: MBT rapor kategori dens listesi (2 sütun kart grid)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../model/mbt_report_catalog.dart';
import '../model/mbt_report_category.dart';
import '../model/mbt_report_definition.dart';
import 'report_parameters_screen.dart';

/// {@template report_category_list_screen}
/// Rapor kategori dens grid — satıra dokununca Parametreler.
///
/// Route örnekleri: `/field-sales/report-cari`, `…-stock`, …
///
/// Kullanım örneği:
/// ```dart
/// const ReportCategoryListScreen(category: MbtReportCategory.cari);
/// ```
/// {@endtemplate}
class ReportCategoryListScreen extends StatelessWidget {
  /// Named route öneki — kategori [MbtReportCategory.menuRoute]
  static const String routePrefix = '/field-sales/report-';

  /// [category]: Hub kategori
  final MbtReportCategory category;

  /// [reports]: Test inject (null → katalog)
  final List<MbtReportDefinition>? reports;

  /// {@macro report_category_list_screen}
  const ReportCategoryListScreen({
    Key? key,
    required this.category,
    this.reports,
  }) : super(key: key);

  void _openParams(BuildContext context, MbtReportDefinition report) {
    Navigator.of(context).pushNamed(
      ReportParametersScreen.routeName,
      arguments: report.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final items = reports ?? MbtReportCatalog.byCategory(category);
    const Color primary = FieldSalesDensAppBar.primaryColor;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate(category.titleKey),
        backgroundColor: primary,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.55,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final report = items[index];
          return Material(
            color: FieldSalesDensTheme.surface(context),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openParams(context, report),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          size: 18,
                          color: FieldSalesDensAppBar.primaryColor,
                        ),
                        const Spacer(),
                        Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      l10n.translate(report.titleKey),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
