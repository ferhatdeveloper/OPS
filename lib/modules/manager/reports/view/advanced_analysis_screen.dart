import 'package:flutter/material.dart';
import '../../../../core/localization/app_localization.dart';

class AdvancedAnalysisScreen extends StatelessWidget {
  const AdvancedAnalysisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(AppLocalization.of(context).translate('advanced.advanced_analysis'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalization.of(context).translate('advanced.performance_summary'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPerformanceChart(context),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildDeepStatCard(context, AppLocalization.of(context).translate('advanced.best_sellers'), Icons.star, Colors.amber)),
                const SizedBox(width: 16),
                Expanded(child: _buildDeepStatCard(context, AppLocalization.of(context).translate('advanced.profitable_stores'), Icons.business, Colors.teal)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalization.of(context).translate('advanced.regional_analysis'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRegionalList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.blue.withOpacity(0.3)),
            const SizedBox(height: 16),
             Text(AppLocalization.of(context).translate('advanced.preparing_chart_data'), style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeepStatCard(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(AppLocalization.of(context).translate('advanced.view'), style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRegionalList(BuildContext context) {
    final regions = [
      {'name': AppLocalization.of(context).translate('advanced.region_marmara'), 'performance': '94%', 'color': Colors.blue},
      {'name': AppLocalization.of(context).translate('advanced.region_ege'), 'performance': '88%', 'color': Colors.green},
      {'name': AppLocalization.of(context).translate('advanced.region_central_anatolia'), 'performance': '72%', 'color': Colors.orange},
      {'name': AppLocalization.of(context).translate('advanced.region_mediterranean'), 'performance': '81%', 'color': Colors.red},
    ];

    return Column(
      children: regions.map((region) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (region['color'] as Color).withOpacity(0.1),
                  child: Text(
                    region['performance'] as String,
                    style: TextStyle(
                      color: region['color'] as Color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    region['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(Icons.trending_up, color: Colors.green.withOpacity(0.7), size: 18),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
