import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import 'package:exfin_ops/modules/field_sales/shared/view/field_sales_dens_theme.dart';

class AdvancedAnalysisScreen extends StatelessWidget {
  const AdvancedAnalysisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: AppLocalization.of(context)
            .translate('advanced.advanced_analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalization.of(context)
                  .translate('advanced.performance_summary'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPerformanceChart(context),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDeepStatCard(
                    context,
                    AppLocalization.of(context)
                        .translate('advanced.best_sellers'),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDeepStatCard(
                    context,
                    AppLocalization.of(context)
                        .translate('advanced.profitable_stores'),
                    Icons.business,
                    Colors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalization.of(context)
                  .translate('advanced.regional_analysis'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildRegionalList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 40,
              color: Colors.blue.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalization.of(context)
                  .translate('advanced.preparing_chart_data'),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepStatCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalization.of(context).translate('advanced.view'),
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalList(BuildContext context) {
    final regions = [
      {
        'name': AppLocalization.of(context)
            .translate('advanced.region_marmara'),
        'performance': '94%',
        'color': Colors.blue,
      },
      {
        'name': AppLocalization.of(context).translate('advanced.region_ege'),
        'performance': '88%',
        'color': Colors.green,
      },
      {
        'name': AppLocalization.of(context)
            .translate('advanced.region_central_anatolia'),
        'performance': '72%',
        'color': Colors.orange,
      },
      {
        'name': AppLocalization.of(context)
            .translate('advanced.region_mediterranean'),
        'performance': '81%',
        'color': Colors.red,
      },
    ];

    return Column(
      children: regions.map((region) {
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      (region['color'] as Color).withOpacity(0.1),
                  child: Text(
                    region['performance'] as String,
                    style: TextStyle(
                      color: region['color'] as Color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    region['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  Icons.trending_up,
                  color: Colors.green.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
