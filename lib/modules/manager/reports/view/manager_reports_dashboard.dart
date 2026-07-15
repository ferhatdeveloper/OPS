import 'package:flutter/material.dart';
import 'period_comparison_report.dart';
import '../../../../core/localization/app_localization.dart';

class ManagerReportsDashboard extends StatelessWidget {
  const ManagerReportsDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDarkMode ? Colors.white : const Color(0xFF2C3E50);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalization.of(context).translate('submodules.yonetici_raporlari'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isDarkMode ? Theme.of(context).appBarTheme.backgroundColor : const Color(0xFF375A7F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalization.of(context).translate('manager_dashboard.performance_summary_tr'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: headerColor),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildKpiCard(context, AppLocalization.of(context).translate('manager_dashboard.monthly_revenue'), '1,250,500 ₺', Icons.trending_up, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard(context, AppLocalization.of(context).translate('manager_dashboard.open_orders'), '45', Icons.shopping_cart, Colors.orange)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildKpiCard(context, AppLocalization.of(context).translate('manager_dashboard.collection'), '480,000 ₺', Icons.account_balance_wallet, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildKpiCard(context, AppLocalization.of(context).translate('manager_dashboard.new_customers'), '+12', Icons.person_add, Colors.purple)),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalization.of(context).translate('manager_dashboard.detailed_analysis'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: headerColor),
            ),
            const SizedBox(height: 16),
            // We use standard push navigation since this is an internal dashboard menu
            _buildReportMenuItem(
              context,
              icon: Icons.compare_arrows,
              title: AppLocalization.of(context).translate('advanced.period_comparison'),
              subtitle: AppLocalization.of(context).translate('manager_dashboard.period_comparison_desc'),
              color: Colors.indigo,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PeriodComparisonReportScreen()));
              }
            ),
            const SizedBox(height: 12),
            _buildReportMenuItem(
              context,
              icon: Icons.store,
              title: AppLocalization.of(context).translate('manager_dashboard.store_region_analysis'),
              subtitle: AppLocalization.of(context).translate('manager_dashboard.store_region_analysis_desc'),
              color: Colors.teal,
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalization.of(context).translate('manager_dashboard.preparing_store_analysis'))));
              }
            ),
            const SizedBox(height: 12),
            _buildReportMenuItem(
              context,
              icon: Icons.inventory,
              title: AppLocalization.of(context).translate('manager_dashboard.inventory_stock_report'),
              subtitle: AppLocalization.of(context).translate('manager_dashboard.inventory_stock_report_desc'),
              color: Colors.brown,
              onTap: () {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalization.of(context).translate('manager_dashboard.preparing_stock_report'))));
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2C3E50);
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.transparent : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.more_vert, color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildReportMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2C3E50);
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey.shade600;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
